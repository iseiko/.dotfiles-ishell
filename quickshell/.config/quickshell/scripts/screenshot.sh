#!/usr/bin/env bash
# Screenshots no Hyprland com grim + slurp + wl-copy.
#
#   screenshot.sh <region|window|screen> [clip]
#
#   region   você arrasta para escolher uma área
#   window   você clica em uma janela (precisa do jq)
#   screen   o monitor inteiro
#   clip     (opcional) só copia para o clipboard, sem salvar arquivo
#   ask      (opcional) captura e abre o painel do shell, onde você escolhe:
#            Ctrl+S salvar, Ctrl+C copiar, Enter os dois, Esc descartar
#
# Sem "clip": salva em ~/Pictures/Screenshots E copia para o clipboard.

# Everything that goes wrong is also written to ~/.cache/screenshot.log, so you can see why a
# keybind did nothing
mkdir -p "$HOME/.cache"
exec 2> >(tee -a "$HOME/.cache/screenshot.log" >&2)

mode="${1:-region}"
clip_only=false
ask=false
[ "${2:-}" = "clip" ] && clip_only=true
[ "${2:-}" = "ask" ] && ask=true

dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

# Shows a notification, or just prints the message if libnotify (notify-send) is not installed
say() {
  if command -v notify-send >/dev/null; then
    notify-send "$@"
  else
    echo "screenshot: ${*: -1}" >&2
  fi
}

fail() {
  say -u critical "Screenshot" "$1"
  exit 1
}

for cmd in grim slurp wl-copy; do
  command -v "$cmd" >/dev/null || fail "$cmd não está instalado"
done

geometry=""
monitor=""

case "$mode" in
  region)
    # Esc cancela, e então não fazemos nada
    geometry="$(slurp -d)" || exit 0
    ;;
  window)
    command -v jq >/dev/null || fail "o modo window precisa do jq (sudo pacman -S jq)"
    # Todas as janelas visíveis nos workspaces ativos viram retângulos que você pode clicar
    workspaces="$(hyprctl monitors -j | jq '[.[].activeWorkspace.id]')"
    geometry="$(hyprctl clients -j | jq -r --argjson ws "$workspaces" '
        .[] | select(.workspace.id as $w | $ws | index($w))
        | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | slurp -r)" || exit 0
    ;;
  screen)
    # O monitor onde está o foco (sem jq captura todos os monitores)
    if command -v jq >/dev/null; then
      monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
    fi
    ;;
  *)
    fail "modo desconhecido: $mode (use region, window ou screen)"
    ;;
esac

# -l 1: compressão PNG mais rápida (o arquivo fica um pouco maior, a captura é bem mais ágil)
args=(-l 1)
[ -n "$geometry" ] && args+=(-g "$geometry")
[ -n "$monitor" ] && args+=(-o "$monitor")

# "ask": captura agora e deixa o painel do shell perguntar o que fazer com a imagem
if $ask; then
  tmp="${XDG_RUNTIME_DIR:-/tmp}/screenshot-$(date +%s%N).png"
  grim "${args[@]}" "$tmp" || fail "não consegui capturar a tela"
  if ! qs ipc call screenshot show "$tmp" "$mode" >/dev/null 2>&1; then
    # o shell não está rodando: faz o comportamento normal (salva e copia)
    mkdir -p "$dir"
    cp "$tmp" "$file" && wl-copy --type image/png < "$file"
    rm -f "$tmp"
    say -i "$file" "Screenshot salvo" "Copiado para o clipboard e salvo em Pictures/Screenshots"
  fi
  exit 0
fi

if $clip_only; then
  grim "${args[@]}" - | wl-copy --type image/png
  [ "${PIPESTATUS[0]}" -eq 0 ] || fail "não consegui capturar a tela"
  say "Screenshot" "Copiado para o clipboard"
else
  mkdir -p "$dir"
  # Uma única captura vai para o arquivo e para o clipboard ao mesmo tempo
  grim "${args[@]}" - | tee "$file" | wl-copy --type image/png
  [ "${PIPESTATUS[0]}" -eq 0 ] || fail "não consegui capturar a tela"
  say -i "$file" "Screenshot salvo" "Copiado para o clipboard e salvo em Pictures/Screenshots"
fi
