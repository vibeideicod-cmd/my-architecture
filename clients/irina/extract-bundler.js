// extract-bundler.js — распаковка bundler-формата claude.ai/design в обычный HTML + assets
// Запуск: node clients/irina/extract-bundler.js
// Вход:   inbox20/vizitka-irina405.html
// Выход:  clients/irina/visitka-v3/index.html + clients/irina/visitka-v3/assets/

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..', '..');
const INPUT = path.join(ROOT, 'inbox20', 'vizitka-irina405.html');
const OUT_DIR = path.join(__dirname, 'visitka-v3');
const ASSETS_DIR = path.join(OUT_DIR, 'assets');

const MIME_EXT = {
  'image/jpeg': '.jpg',
  'image/jpg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'image/svg+xml': '.svg',
  'image/gif': '.gif',
  'font/woff2': '.woff2',
  'font/woff': '.woff',
  'font/ttf': '.ttf',
  'application/font-woff2': '.woff2',
  'application/font-woff': '.woff',
  'audio/mpeg': '.mp3',
  'audio/mp3': '.mp3',
  'audio/ogg': '.ogg',
  'audio/wav': '.wav',
  'video/mp4': '.mp4',
  'video/webm': '.webm',
};

function extractScript(html, type) {
  const re = new RegExp(`<script type="${type.replace(/\//g, '\\/')}">([\\s\\S]*?)<\\/script>`);
  const m = html.match(re);
  return m ? m[1].trim() : null;
}

function main() {
  console.log(`Читаю ${INPUT}...`);
  const html = fs.readFileSync(INPUT, 'utf8');
  console.log(`  размер: ${(html.length / 1024 / 1024).toFixed(1)} МБ`);

  const manifestRaw = extractScript(html, '__bundler/manifest');
  const templateRaw = extractScript(html, '__bundler/template');

  if (!manifestRaw || !templateRaw) {
    console.error('❌ Не нашёл __bundler/manifest или __bundler/template');
    process.exit(1);
  }

  console.log('Парсю manifest...');
  const manifest = JSON.parse(manifestRaw);
  console.log(`  ассетов: ${Object.keys(manifest).length}`);

  console.log('Парсю template (HTML-строку)...');
  let templateHtml = JSON.parse(templateRaw);
  console.log(`  длина HTML: ${(templateHtml.length / 1024).toFixed(0)} КБ`);

  console.log(`Создаю ${OUT_DIR}...`);
  fs.mkdirSync(ASSETS_DIR, { recursive: true });

  // Подкатегории assets
  const subdirs = { font: 'fonts', image: 'images', audio: 'audio', video: 'video' };
  for (const sub of Object.values(subdirs)) {
    fs.mkdirSync(path.join(ASSETS_DIR, sub), { recursive: true });
  }

  console.log('Сохраняю ассеты и обновляю ссылки в HTML...');
  let savedCount = 0;
  let unknownMime = new Set();

  for (const [uuid, info] of Object.entries(manifest)) {
    const mime = info.mime || '';
    const ext = MIME_EXT[mime] || '';
    if (!ext) {
      unknownMime.add(mime);
      continue;
    }

    // Папка по типу
    const category = mime.split('/')[0]; // font / image / audio / video
    const subdir = subdirs[category] || 'misc';
    const subdirPath = path.join(ASSETS_DIR, subdir);
    fs.mkdirSync(subdirPath, { recursive: true });

    const filename = uuid + ext;
    const filepath = path.join(subdirPath, filename);

    fs.writeFileSync(filepath, Buffer.from(info.data, 'base64'));

    // В HTML заменяем UUID на относительный путь
    const relPath = `assets/${subdir}/${filename}`;
    // Простая замена — split/join, чтобы не нарваться на regex special chars
    templateHtml = templateHtml.split(uuid).join(relPath);

    savedCount++;
  }

  if (unknownMime.size > 0) {
    console.warn(`⚠️ Неизвестные mime: ${[...unknownMime].join(', ')}`);
  }

  console.log(`Записываю ${path.join(OUT_DIR, 'index.html')}...`);
  fs.writeFileSync(path.join(OUT_DIR, 'index.html'), templateHtml, 'utf8');

  // Размер итогового
  const stat = fs.statSync(path.join(OUT_DIR, 'index.html'));
  console.log(`  размер: ${(stat.size / 1024).toFixed(0)} КБ`);

  console.log(`\n✅ Готово!`);
  console.log(`   HTML:   ${path.join(OUT_DIR, 'index.html')}`);
  console.log(`   Assets: ${savedCount} файлов в ${ASSETS_DIR}`);
}

main();
