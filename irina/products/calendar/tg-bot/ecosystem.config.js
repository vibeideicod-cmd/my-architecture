// PM2-конфиг для всех трёх процессов календаря Ирины.
// Запуск на VPS Cheerful Marik (45.9.41.80):
//   pm2 start ecosystem.config.js
//   pm2 save
//   pm2 startup   (один раз — чтобы автозапускалось после ребута)
//
// Логи: pm2 logs irina-cal-tg / irina-cal-vk / irina-cal-email
// Статус: pm2 status

module.exports = {
  apps: [
    {
      name: 'irina-cal-tg',
      script: './index.js',
      cwd: __dirname,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '200M',
      env: {
        NODE_ENV: 'production',
      },
      error_file: '/var/log/pm2/irina-cal-tg.err.log',
      out_file:   '/var/log/pm2/irina-cal-tg.out.log',
      time: true,
    },
    // VK и email — отдельные cwd, см. их собственные package.json.
    // Здесь они объявлены централизованно, чтобы один pm2 start
    // поднимал всё. При желании можно их вынести в отдельные ecosystem.
    {
      name: 'irina-cal-vk',
      script: '../vk-bot/index.js',
      cwd: __dirname + '/../vk-bot',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '200M',
      env: { NODE_ENV: 'production' },
      error_file: '/var/log/pm2/irina-cal-vk.err.log',
      out_file:   '/var/log/pm2/irina-cal-vk.out.log',
      time: true,
    },
    {
      name: 'irina-cal-email',
      script: '../notify-email/index.js',
      cwd: __dirname + '/../notify-email',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '150M',
      env: { NODE_ENV: 'production' },
      error_file: '/var/log/pm2/irina-cal-email.err.log',
      out_file:   '/var/log/pm2/irina-cal-email.out.log',
      time: true,
    },
  ],
};
