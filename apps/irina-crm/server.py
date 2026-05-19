#!/usr/bin/env python3
import base64
import html
import json
import os
import sqlite3
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

BASE_DIR = Path(__file__).resolve().parent


def load_env():
    env_path = BASE_DIR / ".env"
    if not env_path.exists():
        return
    for line in env_path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip())


load_env()

HOST = os.getenv("CRM_HOST", "127.0.0.1")
PORT = int(os.getenv("CRM_PORT", "3015"))
DB_PATH = Path(os.getenv("CRM_DB_PATH", str(BASE_DIR / "data" / "crm.sqlite")))
ADMIN_USER = os.getenv("CRM_ADMIN_USER", "irina")
ADMIN_PASSWORD = os.getenv("CRM_ADMIN_PASSWORD", "change-me")
ALLOWED_ORIGINS = {
    item.strip()
    for item in os.getenv("CRM_ALLOWED_ORIGINS", "").split(",")
    if item.strip()
}

VALID_SOURCES = {"karta-rosta", "visitka", "manual", "vk", "tg", "referral", "svetlana_materials_page"}
VALID_CHANNELS = {"telegram", "whatsapp", "vk", "max", "email", "phone", "other"}
VALID_OFFER_FORMATS = {"express", "standard", "deep", "unknown"}
VALID_NOTIFICATION_STATUSES = {"pending", "sent", "failed", "manual"}
MIGRATION_COLUMNS = {
    "main_growth_point": "TEXT",
    "interested_offer_format": "TEXT",
    "notification_channel": "TEXT",
    "notification_status": "TEXT",
    "consent_given_at": "TEXT",
    "consent_text_version": "TEXT",
    "partner": "TEXT",
}
VALID_STATUSES = {
    "new",
    "needs-review",
    "contacted",
    "qualified",
    "not-fit",
    "audit-offered",
    "audit-paid",
    "in-work",
    "closed",
}


def now_iso():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def init_db():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    schema = (BASE_DIR / "schema.sql").read_text(encoding="utf-8")
    with sqlite3.connect(DB_PATH) as conn:
        conn.executescript(schema)
        existing = {row[1] for row in conn.execute("PRAGMA table_info(leads)").fetchall()}
        for column, column_type in MIGRATION_COLUMNS.items():
            if column not in existing:
                conn.execute(f"ALTER TABLE leads ADD COLUMN {column} {column_type}")


def db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def json_text(value):
    if value is None:
        return None
    return json.dumps(value, ensure_ascii=False)


def pick_answers(payload):
    answers = payload.get("answers") if isinstance(payload.get("answers"), dict) else {}
    return {
        "niche": answers.get("niche"),
        "business_age": answers.get("business_age"),
        "team_size": answers.get("team_size"),
        "workload": answers.get("workload"),
        "main_pains": json_text({
            "time_drains": answers.get("time_drains", []),
            "loss_points": answers.get("loss_points", []),
            "main_irritation": answers.get("main_irritation"),
        }),
        "automation_now": json_text(answers.get("automation_now", [])),
        "ai_experience": answers.get("ai_experience"),
        "ai_blockers": json_text(answers.get("ai_blockers", [])),
    }


def validate_lead(payload):
    errors = []
    source = str(payload.get("source", "")).strip()
    name = str(payload.get("name", "")).strip()
    channel = str(payload.get("channel", "")).strip().lower()
    contact = str(payload.get("contact", "")).strip()

    if source not in VALID_SOURCES:
        errors.append("Некорректный источник лида")
    if not 2 <= len(name) <= 80:
        errors.append("Укажите имя от 2 до 80 символов")
    if channel not in VALID_CHANNELS:
        errors.append("Некорректный канал связи")
    if not 3 <= len(contact) <= 120:
        errors.append("Укажите контакт от 3 до 120 символов")
    offer_format = str(payload.get("interested_offer_format", "unknown")).strip().lower() or "unknown"
    if offer_format not in VALID_OFFER_FORMATS:
        errors.append("Некорректный формат оффера")
    notification_channel = str(payload.get("notification_channel", channel or "none")).strip().lower() or "none"
    if notification_channel != "none" and notification_channel not in VALID_CHANNELS:
        errors.append("Некорректный канал уведомления")
    notification_status = str(payload.get("notification_status", "pending")).strip().lower() or "pending"
    if notification_status not in VALID_NOTIFICATION_STATUSES:
        errors.append("Некорректный статус уведомления")
    if source in {"karta-rosta", "visitka", "svetlana_materials_page"} and not str(payload.get("consent_given_at", "")).strip():
        errors.append("Нет отметки согласия на обработку персональных данных")
    if not isinstance(payload.get("answers", {}), dict):
        errors.append("answers должен быть объектом")
    return errors


def insert_lead(payload):
    lead_id = "lead_" + datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S_") + uuid.uuid4().hex[:6]
    timestamp = now_iso()
    answers = pick_answers(payload)
    result_summary = payload.get("result_summary", "")

    values = {
        "id": lead_id,
        "created_at": timestamp,
        "updated_at": timestamp,
        "source": str(payload.get("source", "")).strip(),
        "status": "new",
        "name": str(payload.get("name", "")).strip(),
        "channel": str(payload.get("channel", "")).strip().lower(),
        "contact": str(payload.get("contact", "")).strip(),
        "context_note": str(payload.get("context_note", "")).strip(),
        "main_growth_point": str(payload.get("main_growth_point", "")).strip(),
        "interested_offer_format": str(payload.get("interested_offer_format", "unknown")).strip().lower() or "unknown",
        "notification_channel": str(payload.get("notification_channel", payload.get("channel", "none"))).strip().lower() or "none",
        "notification_status": str(payload.get("notification_status", "pending")).strip().lower() or "pending",
        "consent_given_at": str(payload.get("consent_given_at", "")).strip(),
        "consent_text_version": str(payload.get("consent_text_version", "")).strip(),
        "partner": str(payload.get("partner", "")).strip() or None,
        "result_summary": json_text(result_summary),
        "next_step": "Написать вручную, уточнить контекст и бриф",
        "followup_owner": "Ирина",
        "followup_due_at": None,
        "notes": "",
        "raw_payload": json_text(payload),
        **answers,
    }
    columns = ", ".join(values.keys())
    placeholders = ", ".join(":" + key for key in values.keys())
    with db() as conn:
        conn.execute(f"INSERT INTO leads ({columns}) VALUES ({placeholders})", values)
    return lead_id


class Handler(BaseHTTPRequestHandler):
    server_version = "IrinaCRM/0.1"

    def log_message(self, fmt, *args):
        safe_path = self.path.split("?")[0]
        print("%s - - [%s] %s" % (self.client_address[0], self.log_date_time_string(), fmt % args), safe_path)

    def origin_allowed(self):
        origin = self.headers.get("Origin")
        return not origin or origin in ALLOWED_ORIGINS

    def send_cors(self):
        origin = self.headers.get("Origin")
        if origin and origin in ALLOWED_ORIGINS:
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def send_json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_cors()
        self.end_headers()
        self.wfile.write(body)

    def send_html(self, status, content):
        body = content.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        if not self.origin_allowed():
            self.send_json(403, {"ok": False, "error": "forbidden_origin"})
            return
        self.send_response(204)
        self.send_cors()
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/health":
            self.send_json(200, {"ok": True, "service": "irina-crm"})
            return
        if parsed.path == "/admin":
            if not self.require_auth():
                return
            self.render_admin()
            return
        self.send_json(404, {"ok": False, "error": "not_found"})

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/leads":
            self.handle_create_lead()
            return
        if parsed.path == "/admin/status":
            if not self.require_auth():
                return
            self.handle_status_update()
            return
        self.send_json(404, {"ok": False, "error": "not_found"})

    def handle_create_lead(self):
        if not self.origin_allowed():
            self.send_json(403, {"ok": False, "error": "forbidden_origin", "message": "Источник запроса не разрешён"})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length > 64 * 1024:
                self.send_json(413, {"ok": False, "error": "payload_too_large", "message": "Слишком большой запрос"})
                return
            payload = json.loads(self.rfile.read(length).decode("utf-8"))
        except Exception:
            self.send_json(400, {"ok": False, "error": "bad_json", "message": "Некорректный JSON"})
            return

        errors = validate_lead(payload)
        if errors:
            self.send_json(400, {"ok": False, "error": "validation_error", "message": "; ".join(errors)})
            return

        lead_id = insert_lead(payload)
        self.send_json(201, {"ok": True, "lead_id": lead_id, "status": "new", "message": "Лид сохранён"})

    def require_auth(self):
        header = self.headers.get("Authorization", "")
        if header.startswith("Basic "):
            try:
                decoded = base64.b64decode(header.split(" ", 1)[1]).decode("utf-8")
                user, password = decoded.split(":", 1)
                if user == ADMIN_USER and password == ADMIN_PASSWORD:
                    return True
            except Exception:
                pass
        self.send_response(401)
        self.send_header("WWW-Authenticate", 'Basic realm="Irina CRM"')
        self.end_headers()
        return False

    def render_admin(self):
        query = parse_qs(urlparse(self.path).query)
        status_filter = query.get("status", [""])[0]
        params = []
        where = ""
        if status_filter in VALID_STATUSES:
            where = "WHERE status = ?"
            params.append(status_filter)
        with db() as conn:
            rows = conn.execute(
                f"SELECT * FROM leads {where} ORDER BY created_at DESC LIMIT 200",
                params,
            ).fetchall()

        cards = []
        for row in rows:
            result = ""
            try:
                parsed = json.loads(row["result_summary"] or "[]")
                if isinstance(parsed, list):
                    result = "<br>".join(
                        f"<strong>{html.escape(str(item.get('title', '')))}</strong>: {html.escape(str(item.get('text', '')))}"
                        if isinstance(item, dict) else html.escape(str(item))
                        for item in parsed[:4]
                    )
            except Exception:
                result = html.escape(row["result_summary"] or "")
            cards.append(f"""
              <article class="lead">
                <div class="lead-head">
                  <h2>{html.escape(row['name'])}</h2>
                  <span>{html.escape(row['status'])}</span>
                </div>
                <p><b>Контакт:</b> {html.escape(row['channel'])} · {html.escape(row['contact'])}</p>
                <p><b>Источник:</b> {html.escape(row['source'])} · {html.escape(row['created_at'])}{(' · <b>Партнёр:</b> ' + html.escape(row['partner'])) if (row['partner'] if 'partner' in row.keys() else None) else ''}</p>
                <p><b>Главная точка:</b> {html.escape(row['main_growth_point'] or '')}</p>
                <p><b>Формат:</b> {html.escape(row['interested_offer_format'] or 'unknown')} · <b>Уведомление:</b> {html.escape(row['notification_channel'] or '')} / {html.escape(row['notification_status'] or '')}</p>
                <p><b>Согласие ПД:</b> {html.escape(row['consent_given_at'] or '')} · {html.escape(row['consent_text_version'] or '')}</p>
                <p><b>Ниша:</b> {html.escape(row['niche'] or '')}</p>
                <p><b>Контекст:</b> {html.escape(row['context_note'] or '')}</p>
                <div class="result">{result}</div>
                <form method="post" action="/admin/status">
                  <input type="hidden" name="id" value="{html.escape(row['id'])}">
                  <select name="status">
                    {''.join(f'<option value="{s}" {"selected" if s == row["status"] else ""}>{s}</option>' for s in VALID_STATUSES)}
                  </select>
                  <button type="submit">Обновить</button>
                </form>
              </article>
            """)

        content = f"""<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CRM Студии</title>
  <style>
    body {{ margin:0; font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background:#FCFAE1; color:#306654; }}
    header {{ padding:24px; background:#306654; color:#FCFAE1; }}
    main {{ max-width:1080px; margin:0 auto; padding:24px; }}
    h1 {{ margin:0; font-size:28px; }}
    .lead {{ background:white; border:1px solid #e8e2c0; border-radius:8px; padding:18px; margin:0 0 14px; }}
    .lead-head {{ display:flex; justify-content:space-between; gap:16px; align-items:center; }}
    .lead h2 {{ margin:0; font-size:20px; }}
    .lead-head span {{ background:#FF935E; color:#FCFAE1; padding:4px 8px; border-radius:999px; font-size:13px; }}
    .result {{ border-left:3px solid #FF935E; padding-left:12px; margin:12px 0; color:#306654; }}
    select, button {{ min-height:36px; border-radius:6px; border:1px solid #cfc4b6; padding:6px 10px; }}
    button {{ background:#306654; color:#FCFAE1; cursor:pointer; }}
  </style>
</head>
<body>
  <header><h1>CRM Студии</h1><p>Последние 200 лидов</p></header>
  <main>{''.join(cards) if cards else '<p>Лидов пока нет.</p>'}</main>
</body>
</html>"""
        self.send_html(200, content)

    def handle_status_update(self):
        length = int(self.headers.get("Content-Length", "0"))
        data = parse_qs(self.rfile.read(length).decode("utf-8"))
        lead_id = data.get("id", [""])[0]
        status = data.get("status", [""])[0]
        if status not in VALID_STATUSES:
            self.send_json(400, {"ok": False, "error": "invalid_status"})
            return
        with db() as conn:
            conn.execute(
                "UPDATE leads SET status = ?, updated_at = ? WHERE id = ?",
                (status, now_iso(), lead_id),
            )
        self.send_response(303)
        self.send_header("Location", "/admin")
        self.end_headers()


def main():
    init_db()
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Irina CRM MVP listening on http://{HOST}:{PORT}")
    httpd.serve_forever()


if __name__ == "__main__":
    main()
