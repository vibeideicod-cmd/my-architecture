#!/bin/bash
# Hook: автоматическая запись каждого git commit в дневник дня.
# Срабатывает после Bash(git commit*) только в проекте my-architecture.
# Создан 2026-05-05 после инцидента 04.05 (упёрлись в лимит, дневник
# не сохранился — нужна страховка на случай падения сессии).

PROJECT_ROOT="/Users/innaandreychenko/Documents/Projects/my-architecture"
DIARY_DIR="$PROJECT_ROOT/memory/sessions"

# Никогда не блокируем Claude Code — любая проблема = silent skip.
exit_silent() { exit 0; }

# Работаем только если git toplevel = наш проект.
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit_silent
[ "$GIT_ROOT" = "$PROJECT_ROOT" ] || exit_silent

# Папка дневников должна существовать. Если её нет — молча пропускаем.
[ -d "$DIARY_DIR" ] || exit_silent

DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
DIARY="$DIARY_DIR/$DATE.md"

# Получаем последний коммит. Если коммитов ещё нет — пропускаем.
COMMIT_INFO=$(cd "$PROJECT_ROOT" && git log -1 --format='%h %s' 2>/dev/null) || exit_silent
[ -z "$COMMIT_INFO" ] && exit_silent

# Если файла дневника нет — создаём с заголовком и автосекцией.
if [ ! -f "$DIARY" ]; then
  printf "# Сессия %s\n\n## Лог коммитов (auto)\n\n" "$DATE" > "$DIARY" 2>/dev/null || exit_silent
fi

# Если файл есть, но автосекции в нём нет — дописываем секцию.
if ! grep -q "^## Лог коммитов (auto)" "$DIARY" 2>/dev/null; then
  printf "\n## Лог коммитов (auto)\n\n" >> "$DIARY" 2>/dev/null || exit_silent
fi

# Дописываем строку коммита.
printf -- "- %s \`%s\`\n" "$TIME" "$COMMIT_INFO" >> "$DIARY" 2>/dev/null || exit_silent

exit 0
