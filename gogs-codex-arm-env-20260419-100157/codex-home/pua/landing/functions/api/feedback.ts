interface Env {
  DB: D1Database
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
}

export const onRequest: PagesFunction<Env> = async ({ request, env }) => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders })
  }

  // Detect POST: method=POST or has JSON Content-Type (custom domain may rewrite method)
  const hasJsonContentType = request.headers.get("content-type")?.includes("application/json")
  const isPost = request.method === "POST" || hasJsonContentType

  if (isPost) {
    // Try to read body — custom domain may strip it
    let bodyText: string | null = null
    try { bodyText = await request.text() } catch {}

    if (bodyText && bodyText.length > 2) {
      try {
        const body = JSON.parse(bodyText) as {
          rating?: string
          task_summary?: string
          pua_level?: string
          pua_count?: number
          flavor?: string
          session_data?: string
          failure_count?: number
        }

        if (!body.rating) {
          return Response.json({ error: "rating is required" }, { status: 400, headers: corsHeaders })
        }

        await env.DB.prepare(
          `INSERT INTO feedback (rating, task_summary, pua_level, pua_count, flavor, session_data, failure_count, ip_country)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`
        )
          .bind(
            body.rating,
            body.task_summary || null,
            body.pua_level || "L0",
            body.pua_count || 0,
            body.flavor || "阿里",
            body.session_data || null,
            body.failure_count || 0,
            request.headers.get("CF-IPCountry") || "unknown"
          )
          .run()

        return Response.json({ ok: true }, { headers: corsHeaders })
      } catch (e) {
        return Response.json(
          { error: "Failed to save feedback", detail: String(e) },
          { status: 500, headers: corsHeaders }
        )
      }
    }
    // Body was empty/stripped — fall through to GET
  }

  // GET: aggregate stats
  const stats = await env.DB.prepare(
    `SELECT rating, COUNT(*) as count, AVG(pua_count) as avg_pua_count
     FROM feedback GROUP BY rating ORDER BY count DESC`
  ).all()

  const total = await env.DB.prepare(
    "SELECT COUNT(*) as total FROM feedback"
  ).first<{ total: number }>()

  return Response.json({
    total_feedback: total?.total || 0,
    by_rating: stats.results,
  }, { headers: corsHeaders })
}
