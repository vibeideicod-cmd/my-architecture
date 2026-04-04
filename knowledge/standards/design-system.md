# Дизайн-система команды

## Цвета

### Фоны
| Название | HEX | Когда использовать |
|---|---|---|
| Чёрный | `#0a0a0a` | Основной фон страницы |
| Тёмно-зелёный | `#103206` | Альтернативный фон, карточки, секции |
| Зелёный акцент | `#4b7850` | Обводки, hover-эффекты на зелёных элементах |

### Акценты
| Название | HEX | Когда использовать |
|---|---|---|
| Оранжевый | `#e86c3a` | Главный акцент — кнопки CTA, выделение, ссылки |
| Золото | `#d4af37` | Декоративные элементы, разделители, иконки |
| Тёмное золото | `#c99700` | Hover-состояние для золотых элементов |

### Текст
| Название | HEX | Когда использовать |
|---|---|---|
| Светлый текст | `#e8e0d8` | Основной текст на тёмном фоне |
| Приглушённый | `#a89e94` | Вспомогательный текст, подписи, метки |
| Бежевый | `#d3bfb1` | Подзаголовки, описания |

### CSS-переменные (рекомендуемые)

```css
:root {
  --bg: #0a0a0a;
  --bg-green: #103206;
  --accent: #e86c3a;
  --gold: #d4af37;
  --gold-dark: #c99700;
  --text: #e8e0d8;
  --text-muted: #a89e94;
  --beige: #d3bfb1;
}
```

## Шрифты

| Шрифт | Назначение | Начертания |
|---|---|---|
| `Playfair Display` | Заголовки (h1, h2, крупные элементы) | 400, 600, 700; italic |
| `Montserrat` | Основной текст, кнопки, метки | 300, 400, 500, 600, 700 |

### Подключение через Google Fonts

```html
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;500;600;700&family=Playfair+Display:ital,wght@0,400;0,600;0,700;1,400&display=swap" rel="stylesheet" />
```

### Размеры текста (с clamp)

```css
/* Главный заголовок */
font-size: clamp(2rem, 6vw, 4rem);

/* Подзаголовок секции */
font-size: clamp(1.3rem, 3.5vw, 2rem);

/* Основной текст */
font-size: clamp(0.9rem, 2vw, 1rem);

/* Мелкий текст, метки */
font-size: clamp(0.75rem, 1.5vw, 0.875rem);
```

## Кнопки

### Основная кнопка (оранжевая)

```css
.btn-primary {
  background: linear-gradient(135deg, #e86c3a 0%, #c4532a 100%);
  color: #fff;
  border: none;
  border-radius: 50px;
  padding: 14px 32px;
  font-family: 'Montserrat', sans-serif;
  font-weight: 600;
  font-size: 14px;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  box-shadow: 0 4px 20px rgba(232, 108, 58, 0.35);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 32px rgba(232, 108, 58, 0.5);
}
```

### Вторичная кнопка (обводка)

```css
.btn-outline {
  background: transparent;
  color: #e86c3a;
  border: 1px solid rgba(232, 108, 58, 0.5);
  border-radius: 50px;
  padding: 12px 28px;
  font-family: 'Montserrat', sans-serif;
  font-weight: 500;
  transition: border-color 0.2s, color 0.2s;
}

.btn-outline:hover {
  border-color: #e86c3a;
  color: #fff;
  background: rgba(232, 108, 58, 0.1);
}
```

## Карточки

```css
.card {
  background: rgba(16, 50, 6, 0.5);
  border: 1px solid rgba(232, 108, 58, 0.2);
  border-radius: 16px;
  padding: 32px 28px;
  transition: transform 0.25s ease, border-color 0.25s ease;
}

.card:hover {
  transform: translateY(-4px);
  border-color: rgba(232, 108, 58, 0.5);
}
```

## Разделители

```css
.divider {
  width: 60px;
  height: 2px;
  background: linear-gradient(90deg, transparent, #e86c3a, transparent);
  margin: 0 auto;
}
```

## Метки / badges

```css
.label {
  display: inline-block;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 3px;
  text-transform: uppercase;
  color: #e86c3a;
  border: 1px solid rgba(232, 108, 58, 0.3);
  padding: 6px 18px;
  border-radius: 20px;
}
```

## Адаптивность

Переломные точки:
- Мобильный: до `480px`
- Планшет: `481px – 768px`
- Десктоп: от `769px`

```css
@media (max-width: 480px) { /* мобильный */ }
@media (min-width: 768px) { /* планшет и выше */ }
@media (min-width: 1024px) { /* десктоп */ }
```

## Примечание

Страницы Ирины (`Irina/`) используют золотую акцентную систему (`#d4af37`) — это их фирменный стиль, не меняем. Новые страницы — оранжевый акцент `#e86c3a`.
