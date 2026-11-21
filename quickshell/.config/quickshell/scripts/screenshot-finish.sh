#!/usr/bin/env bash
# Chamado pelo painel de screenshot do shell.
#
#   screenshot-finish.sh <arquivo temporário> <salvar 0|1> <copiar 0|1>

tmp="$1"
save="$2"
copy="$3"

mkdir -p "$HOME/.cache"
exec 2> >(tee -a "$HOME/.cache/screenshot.log" >&2)

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
file=""

say() {
  if command -v notify-send >/dev/null; then
    notify-send "$@"
  else
    echo "screenshot: ${*: -1}" >&2
  fi
}

[ -f "$tmp" ] || { say -u critical "Screenshot" "a captura temporária não existe mais"; exit 1; }

if [ "$save" = 1 ]; then
  mkdir -p "$dir"
  file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"
  cp "$tmp" "$file"
fi

if [ "$copy" = 1 ]; then
  wl-copy --type image/png < "$tmp"
fi

rm -f "$tmp"

if [ "$save" = 1 ] && [ "$copy" = 1 ]; then
  body="Salvo em Pictures/Screenshots e copiado para o clipboard"
elif [ "$save" = 1 ]; then
  body="Salvo em Pictures/Screenshots"
else
  body="Copiado para o clipboard"
fi

if [ -n "$file" ]; then
  say -i "$file" "Screenshot" "$body"
else
  say "Screenshot" "$body"
fi
