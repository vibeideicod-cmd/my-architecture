#!/usr/bin/env python3
import os
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


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


def main():
    load_env()
    db_path = Path(os.getenv("CRM_DB_PATH", str(BASE_DIR / "data" / "crm.sqlite")))
    backup_dir = Path(os.getenv("CRM_BACKUP_DIR", "/var/backups/irina-crm"))
    keep_days = int(os.getenv("CRM_BACKUP_KEEP_DAYS", "14"))

    if not db_path.exists():
        raise SystemExit(f"Database not found: {db_path}")

    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    backup_path = backup_dir / f"crm-{stamp}.sqlite"

    with sqlite3.connect(db_path) as source:
        with sqlite3.connect(backup_path) as target:
            source.backup(target)

    cutoff = datetime.now(timezone.utc).timestamp() - keep_days * 24 * 60 * 60
    for old_backup in backup_dir.glob("crm-*.sqlite"):
        if old_backup.stat().st_mtime < cutoff:
            old_backup.unlink()

    print(f"Backup created: {backup_path}")


if __name__ == "__main__":
    main()
