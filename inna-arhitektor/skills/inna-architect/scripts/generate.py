#!/usr/bin/env python3
"""
inna-architect skill — генератор HTML.

Использование:
    python3 generate.py <platform> < input.json > output.html
    python3 generate.py browser < input.json > ../../output/browser/index.html

Читает JSON с stdin (по схеме references/content-schema.md),
выбирает templates/<platform>.html, подставляет плейсхолдеры, выводит HTML в stdout.
"""

import json
import sys
import os
from pathlib import Path


SCRIPT_DIR = Path(__file__).parent.resolve()
SKILL_DIR = SCRIPT_DIR.parent
TEMPLATES = SKILL_DIR / "templates"


def render_triggers(triggers):
    """Рендерит массив speed_triggers в HTML-карточки."""
    if not triggers:
        return ""
    cards = []
    for t in triggers:
        cards.append(f"""
      <div class="trigger-card">
        <div class="trigger-time">{html_escape(t.get('time', ''))}</div>
        <div class="trigger-format">{html_escape(t.get('format', ''))}</div>
        <div class="trigger-tech">{html_escape(t.get('tech', ''))}</div>
      </div>""")
    return "".join(cards)


def html_escape(s):
    if s is None:
        return ""
    return (str(s)
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace('"', "&quot;"))


def render_email_link(email):
    """Если email есть — возвращает HTML-кнопку mailto, иначе пусто."""
    if not email:
        return ""
    e = html_escape(email)
    return f'<a href="mailto:{e}">{e}</a>'


def main():
    if len(sys.argv) < 2:
        print("Usage: generate.py <platform>", file=sys.stderr)
        print("  platform: browser | tma | vk", file=sys.stderr)
        sys.exit(2)

    platform = sys.argv[1]
    if platform not in ("browser", "tma", "vk"):
        print(f"Unknown platform: {platform}", file=sys.stderr)
        sys.exit(2)

    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Invalid JSON on stdin: {e}", file=sys.stderr)
        sys.exit(1)

    # Validation
    triggers = data.get("speed_triggers", [])
    if not triggers:
        print("ERROR: speed_triggers is empty — блок триггеров обязателен", file=sys.stderr)
        sys.exit(1)

    warnings = []
    inna = data.get("inna", {}) or {}
    for field in ("tg_channel", "tg_direct"):
        if not inna.get(field):
            warnings.append(f"inna.{field} пусто, подставляю TBD")
            inna[field] = "#"

    template_path = TEMPLATES / f"{platform}.html"
    if not template_path.exists():
        print(f"Template not found: {template_path}", file=sys.stderr)
        sys.exit(1)

    tpl = template_path.read_text(encoding="utf-8")

    # Supabase
    supa = data.get("supabase") or {}
    supa_url = supa.get("url", "") or ""
    supa_key = supa.get("anon_key", "") or ""
    supa_table = supa.get("table", "inna_leads") or "inna_leads"

    # Visitor prefill
    visitor = data.get("visitor")
    if visitor is None:
        visitor_json = "null"
    else:
        visitor_json = json.dumps(visitor, ensure_ascii=False)

    # Hero photo: either img with onerror-fallback to monogram, or just monogram
    photo_url = inna.get("photo_url", "")
    if photo_url:
        hero_photo_inner = (
            f'<img src="{html_escape(photo_url)}" alt="Инна Архитектор" '
            f'onerror="this.style.display=\'none\';this.nextElementSibling.style.display=\'flex\'">'
            f'<div class="monogram" style="display:none">ИА</div>'
        )
    else:
        hero_photo_inner = '<div class="monogram" style="display:flex">ИА</div>'

    # Substitutions
    replacements = {
        "{{HERO_PHOTO_INNER}}":   hero_photo_inner,
        "{{INNA_PHOTO_URL}}":     html_escape(inna.get("photo_url", "")),
        "{{INNA_TG_CHANNEL}}":    html_escape(inna.get("tg_channel", "#")),
        "{{INNA_TG_DIRECT}}":     html_escape(inna.get("tg_direct", "#")),
        "{{INNA_EMAIL}}":         html_escape(inna.get("email", "") or ""),
        "{{INNA_EMAIL_LINK}}":    render_email_link(inna.get("email")),
        "{{SPEED_TRIGGERS_HTML}}": render_triggers(triggers),
        "{{SUPABASE_URL}}":       html_escape(supa_url),
        "{{SUPABASE_ANON_KEY}}":  html_escape(supa_key),
        "{{SUPABASE_TABLE}}":     html_escape(supa_table),
        "{{VISITOR_PREFILL_JSON}}": visitor_json,
    }

    for key, val in replacements.items():
        tpl = tpl.replace(key, val)

    # Post-validation: no leftover {{...}}
    import re
    leftover = re.findall(r"\{\{[A-Z_]+\}\}", tpl)
    if leftover:
        print(f"ERROR: unreplaced placeholders: {leftover}", file=sys.stderr)
        sys.exit(1)

    # Forbidden text check
    forbidden = ["Нейро Бабки", "нейро бабки", "СССР"]
    for word in forbidden:
        if word in tpl:
            print(f"WARNING: forbidden text '{word}' found in output", file=sys.stderr)

    sys.stdout.write(tpl)

    if warnings:
        for w in warnings:
            print(f"WARNING: {w}", file=sys.stderr)
    print(f"OK: generated {platform} HTML, size={len(tpl)} chars", file=sys.stderr)


if __name__ == "__main__":
    main()
