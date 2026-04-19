const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const configIniPath = path.join(repoRoot, 'config', 'config.ini');
const httpServerPath = path.join(repoRoot, 'backend', 'src', 'service', 'HttpServer.cpp');

function parseIniKeys(content) {
  const keys = [];
  let section = '';

  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#') || trimmed.startsWith(';')) {
      continue;
    }

    const sectionMatch = trimmed.match(/^\[(.+)\]$/);
    if (sectionMatch) {
      section = sectionMatch[1];
      continue;
    }

    const separatorIndex = trimmed.indexOf('=');
    if (separatorIndex === -1 || !section) {
      continue;
    }

    keys.push(`${section}/${trimmed.slice(0, separatorIndex)}`);
  }

  return keys;
}

function extractRuntimeSchemaKeys(content) {
  const fnStart = content.indexOf('const QVector<RuntimeConfigEntry> &runtimeConfigEntries()');
  if (fnStart === -1) {
    return [];
  }
  const fnBody = content.slice(fnStart, content.indexOf('const QStringList &uiConfigKeys()', fnStart));
  const matches = [...fnBody.matchAll(/QStringLiteral\("((?:camera|lidar|lidar_calibration|plc|processing|recording|system|pile_manager)\/[^"]+)"\)/g)];
  return matches.map((match) => match[1]);
}

function isManagedByFrontend(key) {
  if (key.startsWith('database/')) {
    return false;
  }
  return true;
}

const iniKeys = parseIniKeys(fs.readFileSync(configIniPath, 'utf8'));
const expectedKeys = iniKeys.filter(isManagedByFrontend).sort();
const schemaKeys = [...new Set(extractRuntimeSchemaKeys(fs.readFileSync(httpServerPath, 'utf8')))].sort();

const missing = expectedKeys.filter((key) => !schemaKeys.includes(key));

if (missing.length > 0) {
  console.error('Missing runtime config keys in backend schema:');
  for (const key of missing) {
    console.error(`- ${key}`);
  }
  process.exit(1);
}

console.log(`Runtime config schema covers ${expectedKeys.length} managed config keys.`);
