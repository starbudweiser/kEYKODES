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

# Lanceur PyInstaller compilé depuis les sources, contre les faux positifs antivirus (absent hors de ce dossier d'outils : lanceur standard).
PYI_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/_tools/pyinstaller_source.sh"
if [ -x "$PYI_SRC" ]; then "$PYI_SRC" python3; fi
pyinstaller --noconfirm --clean --windowed --name "$APP_NAME" \
  --icon "$ROOT/assets/icon.icns" \
  --distpath "$TMP/dist" --workpath "$TMP/work" --specpath "$TMP/spec" \
  "$SRC"

[ -d "$TMP/dist/$APP_NAME.app" ] || { echo "Erreur : app non générée." >&2; exit 1; }
mv "$TMP/dist/$APP_NAME.app" "$ROOT/$APP_NAME.app"
# Signature stable avec _tools/sign_app.sh (certificat local) ; sans lui (compilation depuis
# le dépôt GitHub seul), signature ad hoc pour que l'appli se lance quand même.
SIGN_APP="$(cd "$ROOT/.." && pwd)/_tools/sign_app.sh"
if [ -x "$SIGN_APP" ]; then
    "$SIGN_APP" "$ROOT/$APP_NAME.app" 1.3.0
else
    echo "_tools/sign_app.sh absent : signature ad hoc."
    codesign --force --deep --sign - "$ROOT/$APP_NAME.app"
fi

echo "OK : $ROOT/$APP_NAME.app"
