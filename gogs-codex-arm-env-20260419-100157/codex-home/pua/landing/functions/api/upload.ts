import { getSession } from "./_session"
import { sanitize } from "./_sanitize"

interface Env {
  DB: D1Database
  UPLOADS: R2Bucket
  SESSION_SECRET: string
}

// Use single onRequest handler — custom domains may not route onRequestPost correctly
export const onRequest: PagesFunction<Env> = async ({ request, env }) => {
  const session = await getSession(request, env.SESSION_SECRET)
  if (!session) {
    return Response.json({ error: "Unauthorized" }, { status: 401 })
  }

  // Detect upload: JSON with file_data (base64) or multipart form
  const contentType = request.headers.get("content-type") || ""
  const isJsonUpload = contentType.includes("application/json")
  const isMultipartUpload = contentType.includes("multipart/form-data")
  const isUpload = isJsonUpload || isMultipartUpload || request.method === "POST"

  if (!isUpload) {
    // GET: list user's uploads
    const { results } = await env.DB.prepare(
      "SELECT file_name, file_size, created_at FROM uploads WHERE github_id = ? ORDER BY created_at DESC LIMIT 50"
    ).bind(session.id).all()
    return Response.json({ uploads: results })
  }

  // POST: upload file
  try {
    let raw: string
    let fileName: string
    let wechatId: string
    let originalSize: number

    if (isJsonUpload) {
      // JSON body with base64 file_data (workaround for Cloudflare custom domain stripping multipart body)
      // Guard: read as text first — if body is empty (POST→GET rewrite strips body), return 400 instead of crashing
      const rawText = await request.text()
      if (!rawText || !rawText.trim()) {
        return Response.json({
          error: "Empty request body — the upload was likely intercepted by a proxy that stripped the POST body. Try refreshing and uploading again, or report this to the admin."
        }, { status: 400 })
      }
      let body: { file_name?: string; file_data?: string; wechat_id?: string }
      try {
        body = JSON.parse(rawText)
      } catch (parseErr) {
        return Response.json({ error: "Invalid JSON body: " + String(parseErr) }, { status: 400 })
      }
      if (!body.file_data || !body.file_name) {
        return Response.json({ error: "file_name and file_data are required" }, { status: 400 })
      }
      if (!body.wechat_id?.trim()) {
        return Response.json({ error: "WeChat ID is required" }, { status: 400 })
      }
      if (!body.file_name.endsWith(".jsonl")) {
        return Response.json({ error: "Only .jsonl files are accepted" }, { status: 400 })
      }
      // Decode base64
      const binaryStr = atob(body.file_data)
      raw = new TextDecoder().decode(Uint8Array.from(binaryStr, c => c.charCodeAt(0)))
      fileName = body.file_name
      wechatId = body.wechat_id.trim()
      originalSize = raw.length
    } else {
      // Multipart form data (original path)
      const formData = await request.formData()
      const file = formData.get("file") as File | null
      const wid = formData.get("wechat_id") as string | null
      if (!file) {
        return Response.json({ error: "No file provided" }, { status: 400 })
      }
      if (!wid?.trim()) {
        return Response.json({ error: "WeChat ID is required" }, { status: 400 })
      }
      if (!file.name.endsWith(".jsonl")) {
        return Response.json({ error: "Only .jsonl files are accepted" }, { status: 400 })
      }
      if (file.size > 50 * 1024 * 1024) {
        return Response.json({ error: "File too large (max 50MB)" }, { status: 400 })
      }
      raw = await file.text()
      fileName = file.name
      wechatId = wid.trim()
      originalSize = file.size
    }

    if (originalSize > 50 * 1024 * 1024) {
      return Response.json({ error: "File too large (max 50MB)" }, { status: 400 })
    }
    let sanitized: string
    try {
      sanitized = sanitize(raw)
    } catch (e) {
      return Response.json({ error: "Sanitization failed: " + String(e) }, { status: 422 })
    }

    // Upload sanitized content to R2
    const key = `${session.login}/${Date.now()}-${fileName}`
    await env.UPLOADS.put(key, sanitized, {
      httpMetadata: { contentType: "application/jsonl" },
      customMetadata: {
        github_id: session.id,
        github_login: session.login,
        wechat_id: wechatId.trim(),
      },
    })

    // Record sanitized byte length (post-sanitization size, not original)
    const sanitizedSize = new TextEncoder().encode(sanitized).byteLength
    await env.DB.prepare(
      "INSERT INTO uploads (github_id, github_login, wechat_id, file_key, file_name, file_size) VALUES (?, ?, ?, ?, ?, ?)"
    ).bind(session.id, session.login, wechatId, key, fileName, sanitizedSize).run()

    // Send email notification (fire-and-forget)
    const sizeMB = (originalSize / 1024 / 1024).toFixed(2)
    const emailBody = [
      `New PUA Skill data upload:`,
      ``,
      `GitHub: ${session.login} (${session.id})`,
      `WeChat: ${wechatId}`,
      `File: ${fileName} (${sizeMB} MB)`,
      `R2 Key: ${key}`,
      `Time: ${new Date().toISOString()}`,
    ].join("\n")

    fetch("https://api.mailchannels.net/tx/v1/send", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: "xsser.w@gmail.com", name: "PUA Admin" }] }],
        from: { email: "noreply@pua-skill.pages.dev", name: "PUA Skill Upload" },
        subject: `[PUA Upload] ${session.login} uploaded ${fileName}`,
        content: [{ type: "text/plain", value: emailBody }],
      }),
    }).catch(() => {})

    return Response.json({ ok: true, key, file_name: fileName, file_size: originalSize })
  } catch (e) {
    return Response.json({ error: "Upload failed: " + String(e) }, { status: 500 })
  }
}
