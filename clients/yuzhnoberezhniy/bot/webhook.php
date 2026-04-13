<?php
// YUB Bot /start handler webhook
// Responds to /start with welcome message + inline WebApp button.
// Deployed via deploy-yub-bot.sh which substitutes {{TG_BOT_TOKEN}}.

$BOT_TOKEN = '{{TG_BOT_TOKEN}}';
$WEB_APP_URL = 'https://demo.ideidlyabiznesa1913.ru/yub-tg/';

$rawInput = file_get_contents('php://input');
$update = json_decode($rawInput, true);

if (!is_array($update) || !isset($update['message'])) {
    http_response_code(200);
    exit;
}

$msg     = $update['message'];
$chat_id = $msg['chat']['id'] ?? null;
$text    = $msg['text'] ?? '';

if (!$chat_id) {
    http_response_code(200);
    exit;
}

// Respond to /start (with or without args, with or without @bot_name suffix)
if (preg_match('#^/start(@\w+)?(\s|$)#', $text)) {
    $welcome =
        "Привет! 👋\n\n" .
        "Я помогу собрать рюкзак на смену в санаторий «Южнобережный» 🏖\n\n" .
        "Что я умею:\n" .
        "✅ Чеклист под возраст ребёнка, сезон и тип путёвки\n" .
        "✅ Раздел для санаторно-курортного лечения (лекарства, медкарта)\n" .
        "✅ Прогресс сохраняется — можно собирать частями\n" .
        "✅ Подсказки по каждому пункту\n\n" .
        "👇 Нажмите кнопку ниже, чтобы начать.";

    $keyboard = [
        'inline_keyboard' => [[
            ['text' => '🎒 Собрать рюкзак', 'web_app' => ['url' => $WEB_APP_URL]]
        ]]
    ];

    $ch = curl_init("https://api.telegram.org/bot{$BOT_TOKEN}/sendMessage");
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'chat_id'      => $chat_id,
        'text'         => $welcome,
        'reply_markup' => json_encode($keyboard, JSON_UNESCAPED_UNICODE),
    ]));
    curl_exec($ch);
    curl_close($ch);
}

http_response_code(200);
