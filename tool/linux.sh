#!/usr/bin/env bash
# Сборка и запуск Wickly на Linux-десктопе.
#
# Отдельный скрипт, потому что на обычной машине сборка спотыкается дважды:
#
# 1. Flutter из **snap** подкладывает внутрь самого SDK файл
#    `bin/internal/bootstrap.sh` (копию своего `env.sh`) и переписывает им PATH
#    даже при прямом запуске SDK. Оттуда приезжает clang-10 из core20, рядом с
#    которым нет линковщика, и сборка падает на
#    «Failed to find any of [ld.lld, ld] in /snap/flutter/.../llvm-10/bin».
#    Файл создаётся заново при КАЖДОМ запуске `flutter` из snap, поэтому
#    убираем его перед сборкой, а не один раз.
#
# 2. clang с заголовками свежего libstdc++ ругается на `alloc_align`, поэтому
#    десктопную часть собираем gcc — если он есть.
#
# Использование:
#   tool/linux.sh            — собрать debug и запустить
#   tool/linux.sh release    — собрать release и запустить
#   tool/linux.sh build      — только собрать (debug)
#   XDG_DATA_HOME=~/.wickly-b tool/linux.sh run — второй экземпляр со своими
#                              данными: так проверяется синхронизация на одной
#                              машине (у каждого своя база и свои вложения).
set -e

cd "$(dirname "$0")/.."

MODE="${1:-debug}"

# --- SDK ---------------------------------------------------------------
FLUTTER_BIN="$(command -v flutter || true)"
if [ -z "$FLUTTER_BIN" ]; then
  echo "flutter не найден в PATH" >&2
  exit 1
fi
# Обёртка snap запускает настоящий SDK из домашней папки — берём его напрямую,
# иначе окружение снапа снова навяжет свой тулчейн.
if [ -x "$HOME/snap/flutter/common/flutter/bin/flutter" ]; then
  FLUTTER_BIN="$HOME/snap/flutter/common/flutter/bin/flutter"
fi
FLUTTER_ROOT="$(cd "$(dirname "$FLUTTER_BIN")/.." && pwd)"
rm -f "$FLUTTER_ROOT/bin/internal/bootstrap.sh"

# --- тулчейн -----------------------------------------------------------
TOOLCHAIN=()
if command -v gcc >/dev/null && command -v g++ >/dev/null; then
  TOOLCHAIN=(CC=gcc CXX=g++)
fi

BUILD_MODE=debug
[ "$MODE" = "release" ] && BUILD_MODE=release

BUNDLE="build/linux/x64/$BUILD_MODE/bundle/wickly"

if [ "$MODE" != "run" ]; then
  echo "→ сборка ($BUILD_MODE)"
  # Чистое окружение: любые LDFLAGS/PKG_CONFIG_PATH от снапа ломают линковку.
  env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin TERM="${TERM:-xterm}" \
    LANG="${LANG:-C.UTF-8}" "${TOOLCHAIN[@]}" \
    "$FLUTTER_BIN" build linux "--$BUILD_MODE"
fi

[ "$MODE" = "build" ] && exit 0

if [ ! -x "$BUNDLE" ]; then
  echo "нет сборки: $BUNDLE" >&2
  exit 1
fi

echo "→ запуск ($BUILD_MODE)${XDG_DATA_HOME:+, данные в $XDG_DATA_HOME}"
exec "$BUNDLE"
