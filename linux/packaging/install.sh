#!/usr/bin/env bash
# Ставит Wickly в домашнюю папку: без прав root и без пакетного менеджера.
#
#   ./install.sh            — поставить и прописать в меню приложений
#   ./install.sh --remove   — убрать (данные дневника остаются на месте)
#
# Куда кладём:
#   ~/.local/lib/wickly                      само приложение
#   ~/.local/bin/wickly                      команда запуска
#   ~/.local/share/applications/wickly.desktop  ярлык в меню
#   ~/.local/share/icons/hicolor/…/wickly.png   иконка
#
# Дневник живёт отдельно, в ~/.local/share/com.wickly.wickly — переустановка
# и удаление его не трогают.
set -e

APP_DIR="$HOME/.local/lib/wickly"
BIN="$HOME/.local/bin/wickly"
DESKTOP="$HOME/.local/share/applications/wickly.desktop"
ICON_DIR="$HOME/.local/share/icons/hicolor/512x512/apps"
SRC="$(cd "$(dirname "$0")" && pwd)"

if [ "$1" = "--remove" ]; then
  rm -rf "$APP_DIR" "$BIN" "$DESKTOP" "$ICON_DIR/wickly.png"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  echo "Wickly убран. Дневник остался в ~/.local/share/com.wickly.wickly"
  exit 0
fi

if [ ! -x "$SRC/wickly" ]; then
  echo "Рядом со скриптом нет собранного приложения (файла wickly)." >&2
  exit 1
fi

echo "→ ставлю в $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR" "$(dirname "$BIN")" "$(dirname "$DESKTOP")" "$ICON_DIR"
cp -a "$SRC/." "$APP_DIR/"
rm -f "$APP_DIR/install.sh" "$APP_DIR/wickly.desktop"

ln -sf "$APP_DIR/wickly" "$BIN"
[ -f "$SRC/wickly.png" ] && cp "$SRC/wickly.png" "$ICON_DIR/wickly.png"

cat > "$DESKTOP" <<EOF
[Desktop Entry]
Type=Application
Name=Wickly
GenericName=Дневник
Comment=Личный дневник без аккаунта
Exec=$APP_DIR/wickly
Icon=wickly
Terminal=false
Categories=Office;Utility;
StartupWMClass=com.wickly.wickly
EOF

update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "Готово. Запуск: wickly (или из меню приложений)."
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Внимание: $HOME/.local/bin нет в PATH — команда wickly не найдётся." ;;
esac
