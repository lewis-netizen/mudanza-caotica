#!/usr/bin/env bash
# Validación local de convención de commits (lefthook commit-msg).
# $1 = path al archivo con el mensaje de commit.
# Vive en un archivo (no inline en lefthook.yml): el runner de lefthook en
# Windows destroza el quoting de scripts multilínea inline.

MSG=$(cat "$1")

# Commits de sync automático del bot — exentos
if echo "$MSG" | grep -q "^chore(governance): sync "; then
    exit 0
fi

if ! echo "$MSG" | grep -qE "^(feat|fix|refactor|docs|chore)\((gameplay|world|networking|persistence|ui|ux|governance)\): .+"; then
    echo "❌ Commit message format violation"
    echo "   Got: $MSG"
    echo "   Expected: tipo(dominio): descripción"
    echo "   Types: feat | fix | refactor | docs | chore"
    echo "   Scopes: gameplay | world | networking | persistence | ui | ux | governance"
    exit 1
fi
