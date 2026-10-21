#!/bin/bash
# Construit kEYKODES.app à la racine du projet et supprime tous les fichiers temporaires.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT/src/KEYCODES.py"
APP_NAME="kEYKODES"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/keycodes_build.XXXXXX")"

cleanup() {
  rm -rf "$TMP" "$ROOT/build" "$ROOT/$APP_NAME.spec" "$ROOT/src/__pycache__"
}
trap cleanup EXIT

[ -f "$SRC" ] || { echo "Erreur : $SRC introuvable." >&2; exit 1; }
command -v pyinstaller >/dev/null 2>&1 || { echo "Erreur : pyinstaller absent (pip install pyinstaller)." >&2; exit 1; }

rm -rf "$ROOT/$APP_NAME.app"

pyinstaller --noconfirm --clean --windowed --name "$APP_NAME" \
  --icon "$ROOT/assets/icon.icns" \
  --distpath "$TMP/dist" --workpath "$TMP/work" --specpath "$TMP/spec" \
  "$SRC"

[ -d "$TMP/dist/$APP_NAME.app" ] || { echo "Erreur : app non générée." >&2; exit 1; }
mv "$TMP/dist/$APP_NAME.app" "$ROOT/$APP_NAME.app"
"$(cd "$ROOT/.." && pwd)/_tools/sign_app.sh" "$ROOT/$APP_NAME.app" 1.0.0  # signature stable (_tools)

echo "OK : $ROOT/$APP_NAME.app"
