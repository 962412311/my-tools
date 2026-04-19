#!/usr/bin/env node

import fs from 'node:fs'
import path from 'node:path'
import { spawnSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import os from 'node:os'
import crypto from 'node:crypto'

const scriptDir = path.dirname(fileURLToPath(import.meta.url))
const repoRoot = path.resolve(scriptDir, '..')
const frontendDir = path.join(repoRoot, 'frontend')
const platformId = `${process.platform}-${process.arch}`
const command = process.argv[2] || 'install'
const useIsolatedWorkspace = process.platform === 'linux' && frontendDir.startsWith('/mnt/')
const workspaceDir = useIsolatedWorkspace
  ? path.join(os.homedir(), '.cache', 'gogs', `frontend-${Buffer.from(frontendDir).toString('hex')}`)
  : frontendDir
const nodeModulesDir = path.join(workspaceDir, 'node_modules')
const platformStampPath = path.join(nodeModulesDir, '.platform-stamp.json')
const packageLockPath = path.join(workspaceDir, 'package-lock.json')
const packageJsonPath = path.join(workspaceDir, 'package.json')
const workspaceLockDir = path.join(workspaceDir, '.frontend-tool.lock')
const lockTimeoutMs = 5 * 60 * 1000
const lockRetryMs = 200

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, 'utf8'))
}

function exists(filePath) {
  return fs.existsSync(filePath)
}

function fileHash(filePath) {
  if (!exists(filePath)) {
    return null
  }

  return crypto.createHash('sha256').update(fs.readFileSync(filePath)).digest('hex')
}

function run(commandName, args) {
  const result = spawnSync(commandName, args, {
    cwd: workspaceDir,
    stdio: 'inherit',
    shell: process.platform === 'win32'
  })

  if (result.status !== 0) {
    throw new Error(`${commandName} ${args.join(' ')} 执行失败，退出码 ${result.status ?? 1}`)
  }
}

const syncedEntries = [
  'src',
  'public',
  'index.html',
  'package.json',
  'package-lock.json',
  'vite.config.js',
  '.env.production',
  '.env.production.example',
  '.eslintrc.cjs',
  '.gitignore'
]

function ensureIsolatedWorkspace() {
  if (!useIsolatedWorkspace) {
    return
  }

  fs.mkdirSync(workspaceDir, { recursive: true })
}

function syncSourceToWorkspace() {
  if (!useIsolatedWorkspace) {
    return
  }

  ensureIsolatedWorkspace()
  fs.rmSync(path.join(workspaceDir, 'dist'), { recursive: true, force: true })

  for (const entry of syncedEntries) {
    const sourcePath = path.join(frontendDir, entry)
    const targetPath = path.join(workspaceDir, entry)

    if (!exists(sourcePath)) {
      fs.rmSync(targetPath, { recursive: true, force: true })
      continue
    }

    fs.rmSync(targetPath, { recursive: true, force: true })
    fs.cpSync(sourcePath, targetPath, { recursive: true })
  }
}

function syncWorkspaceBackToSource() {
  if (!useIsolatedWorkspace) {
    return
  }

  for (const entry of syncedEntries) {
    const sourcePath = path.join(workspaceDir, entry)
    const targetPath = path.join(frontendDir, entry)

    if (!exists(sourcePath)) {
      continue
    }

    fs.rmSync(targetPath, { recursive: true, force: true })
    fs.cpSync(sourcePath, targetPath, { recursive: true })
  }

  const workspaceDist = path.join(workspaceDir, 'dist')
  try {
    if (!fs.statSync(workspaceDist).isDirectory()) {
      return
    }

    const targetDist = path.join(frontendDir, 'dist')
    fs.rmSync(targetDist, { recursive: true, force: true })
    fs.cpSync(workspaceDist, targetDist, { recursive: true })
  } catch {
    // build 命令之外不保证一定存在 dist 目录
  }
}

function toWindowsPath(targetPath) {
  const normalized = path.resolve(targetPath).replace(/\\/g, '/')
  const match = normalized.match(/^\/mnt\/([a-zA-Z])\/(.*)$/)
  if (!match) {
    return null
  }

  const drive = match[1].toUpperCase()
  const tail = match[2].replace(/\//g, '\\')
  return `${drive}:\\${tail}`
}

function removeDirectory(targetPath) {
  try {
    fs.rmSync(targetPath, { recursive: true, force: true })
    return
  } catch (error) {
    const windowsPath = toWindowsPath(targetPath)
    if (!windowsPath) {
      throw error
    }

    console.log(`[frontend-tool] 本地删除失败，回退到 Windows 删除: ${windowsPath}`)
    spawnSync('cmd.exe', ['/c', 'attrib', '-R', '-S', '-H', `${windowsPath}\\*`, '/S', '/D'], {
      stdio: 'inherit'
    })

    const cmdResult = spawnSync('cmd.exe', ['/c', 'rmdir', '/s', '/q', windowsPath], {
      stdio: 'inherit'
    })
    if (!fs.existsSync(targetPath)) {
      return
    }

    const psCommand = [
      '$ErrorActionPreference = "Stop"',
      `if (Test-Path -LiteralPath '${windowsPath.replace(/\\/g, '\\\\')}') {`,
      `  Remove-Item -LiteralPath '${windowsPath.replace(/\\/g, '\\\\')}' -Recurse -Force`,
      '}'
    ].join('; ')
    const psResult = spawnSync('powershell.exe', ['-NoProfile', '-Command', psCommand], {
      stdio: 'inherit'
    })
    if ((cmdResult.status !== 0 || psResult.status !== 0) && fs.existsSync(targetPath)) {
      throw error
    }
  }
}

function ensureCleanNodeModulesForCurrentPlatform() {
  if (!exists(nodeModulesDir)) {
    return true
  }

  if (!exists(platformStampPath)) {
    console.log(`[frontend-tool] 检测到未标记的 node_modules，重建为当前平台 ${platformId}`)
    removeDirectory(nodeModulesDir)
    return true
  }

  try {
    const stamp = readJson(platformStampPath)
    if (stamp.platform !== platformId) {
      console.log(`[frontend-tool] 检测到跨平台 node_modules (${stamp.platform} -> ${platformId})，正在重建`)
      removeDirectory(nodeModulesDir)
      return true
    }
    if (stamp.packageLockHash !== fileHash(packageLockPath)) {
      console.log('[frontend-tool] 检测到前端依赖锁文件变化，正在重建 node_modules')
      removeDirectory(nodeModulesDir)
      return true
    }
    if (stamp.packageJsonHash !== fileHash(packageJsonPath)) {
      console.log('[frontend-tool] 检测到前端 package.json 变化，正在重建 node_modules')
      removeDirectory(nodeModulesDir)
      return true
    }
  } catch (error) {
    console.log('[frontend-tool] 读取 node_modules 平台标记失败，重建依赖目录')
    removeDirectory(nodeModulesDir)
    return true
  }

  return false
}

function writePlatformStamp() {
  fs.mkdirSync(nodeModulesDir, { recursive: true })
  fs.writeFileSync(platformStampPath, JSON.stringify({
    platform: platformId,
    packageJsonHash: fileHash(packageJsonPath),
    packageLockHash: fileHash(packageLockPath),
    generatedAt: new Date().toISOString()
  }, null, 2))
}

function ensureDependencies() {
  ensureIsolatedWorkspace()
  syncSourceToWorkspace()
  const needsInstall = ensureCleanNodeModulesForCurrentPlatform() || !exists(nodeModulesDir)

  if (needsInstall) {
    console.log('[frontend-tool] 安装前端依赖 (npm install)')
    run('npm', ['install'])
    writePlatformStamp()
    syncWorkspaceBackToSource()
    return
  }

  console.log(`[frontend-tool] 当前 node_modules 与平台 ${platformId} 匹配，跳过重装`)
}

function readLockInfo() {
  try {
    return readJson(path.join(workspaceLockDir, 'lock.json'))
  } catch {
    return null
  }
}

function releaseWorkspaceLock() {
  if (!useIsolatedWorkspace) {
    return
  }

  fs.rmSync(workspaceLockDir, { recursive: true, force: true })
}

function acquireWorkspaceLock() {
  if (!useIsolatedWorkspace) {
    return
  }

  ensureIsolatedWorkspace()
  const startedAt = Date.now()
  const lockInfo = {
    pid: process.pid,
    command,
    createdAt: new Date().toISOString()
  }

  while (true) {
    try {
      fs.mkdirSync(workspaceLockDir)
      fs.writeFileSync(path.join(workspaceLockDir, 'lock.json'), JSON.stringify(lockInfo, null, 2))
      return
    } catch (error) {
      if (error.code !== 'EEXIST') {
        throw error
      }

      const currentLock = readLockInfo()
      if (currentLock?.pid) {
        try {
          process.kill(currentLock.pid, 0)
        } catch (lockError) {
          if (lockError.code === 'ESRCH') {
            console.log('[frontend-tool] 检测到失效工作区锁进程，正在清理')
            releaseWorkspaceLock()
            continue
          }
        }
      }
      const lockAgeMs = currentLock?.createdAt
        ? Date.now() - new Date(currentLock.createdAt).getTime()
        : Number.POSITIVE_INFINITY

      if (!Number.isFinite(lockAgeMs) || lockAgeMs > lockTimeoutMs) {
        console.log('[frontend-tool] 检测到过期工作区锁，正在清理')
        releaseWorkspaceLock()
        continue
      }

      if (Date.now() - startedAt > lockTimeoutMs) {
        throw new Error(`等待前端隔离工作区锁超时，当前锁: ${JSON.stringify(currentLock)}`)
      }

      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, lockRetryMs)
    }
  }
}

try {
  acquireWorkspaceLock()

  switch (command) {
    case 'install':
      ensureDependencies()
      break
    case 'build':
      ensureDependencies()
      run('npm', ['run', 'build'])
      syncWorkspaceBackToSource()
      break
    case 'dev':
      if (useIsolatedWorkspace) {
        console.log('[frontend-tool] 检测到 WSL 挂载盘环境，dev 将在隔离工作区启动；若需稳定热更新，优先改用 Windows 终端或本机环境。')
      }
      ensureDependencies()
      run('npm', ['run', 'dev'])
      break
    case 'lint':
      ensureDependencies()
      run('npm', ['run', 'lint'])
      syncWorkspaceBackToSource()
      break
    default:
      console.error(`未知命令: ${command}`)
      console.error('用法: node scripts/frontend-tool.js [install|build|dev|lint]')
      process.exit(1)
  }
} catch (error) {
  console.error(`[frontend-tool] ${error.message}`)
  process.exit(1)
} finally {
  releaseWorkspaceLock()
}
