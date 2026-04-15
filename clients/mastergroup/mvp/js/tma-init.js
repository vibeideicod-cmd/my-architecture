// Telegram Mini App инициализация для МГ-платформы.
// Загружается после telegram-web-app.js. Работает no-op если не в Telegram.
(function () {
  const tg = window.Telegram && window.Telegram.WebApp;
  if (!tg || !tg.initData && !tg.platform) {
    window.isTMA = false;
    return;
  }

  tg.ready();
  tg.expand();

  window.isTMA = true;
  window.tg = tg;
  document.documentElement.classList.add('tma');

  // Лёгкий виброотклик на все кнопки (если поддерживается)
  if (tg.HapticFeedback) {
    document.addEventListener('click', function (e) {
      const el = e.target.closest('button, .btn, a.cta-primary, a.btn-primary, .save-btn, .url-btn');
      if (el) tg.HapticFeedback.impactOccurred('light');
    }, true);
  }

  // Хелпер: поделиться ссылкой через нативный шер Telegram
  window.tmaShareLink = function (url, text) {
    const shareUrl = 'https://t.me/share/url?url=' + encodeURIComponent(url) +
                     '&text=' + encodeURIComponent(text || '');
    tg.openTelegramLink(shareUrl);
  };

  // Хелпер: открыть любую ссылку через нативный браузер Telegram (tg://)
  window.tmaOpenLink = function (url) {
    if (url.startsWith('tg://') || url.startsWith('https://t.me/')) {
      tg.openTelegramLink(url);
    } else {
      tg.openLink(url);
    }
  };
})();
