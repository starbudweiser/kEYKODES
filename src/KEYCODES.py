"""Visualiseur de codes clavier pour les fichiers .ini de Skyrim.

Affiche, pour chaque touche pressée, son code DirectInput (scancode utilisé par Skyrim,
SkyUI et les MCM) en hexadécimal court et en décimal, ainsi que sa valeur ImGuiKey
(menus Dear ImGui des plugins SKSE). Le code dépend de la position
physique de la touche, comme sous Windows : la touche « A » d'un clavier AZERTY donne
le code de « Q » (0x10).
"""
import ctypes
import json
import sys
from pathlib import Path

from PyQt6.QtCore import QLocale, Qt
from PyQt6.QtGui import QActionGroup
from PyQt6.QtWidgets import QApplication, QHBoxLayout, QLabel, QMenu, QPushButton, QVBoxLayout, QWidget

import i18n
import socle_qt
import update_check
from i18n import L, N_

# Réglages (langue choisie) : même emplacement que les autres applis
# Fenêtre : 750 × 400 pour des textes à 100 %, mise à l'échelle des textes Socle (110 %).
BASE_SIZE = (750, 400)
CONFIG_FILE = Path.home() / "Library" / "Application Support" / "kEYKODES" / "config.json"
AUTO = "auto"  # langue du système

# Noms utilisés seulement par la preview web (touches absentes des claviers Mac)
WEB_ONLY_NAMES = (N_("Arrêt défil"), N_("Insert"))

# Codes DirectInput (DIK_*) par code de touche virtuel macOS (kVK_*, position physique).
MAC_TO_DIK = {
    0x35: (0x01, N_("Échap")), 0x7A: (0x3B, "F1"), 0x78: (0x3C, "F2"), 0x63: (0x3D, "F3"), 0x76: (0x3E, "F4"),
    0x60: (0x3F, "F5"), 0x61: (0x40, "F6"), 0x62: (0x41, "F7"), 0x64: (0x42, "F8"), 0x65: (0x43, "F9"),
    0x6D: (0x44, "F10"), 0x67: (0x57, "F11"), 0x6F: (0x58, "F12"), 0x69: (0x64, "F13"), 0x6B: (0x65, "F14"),
    0x71: (0x66, "F15"),
    0x12: (0x02, "1"), 0x13: (0x03, "2"), 0x14: (0x04, "3"), 0x15: (0x05, "4"), 0x17: (0x06, "5"),
    0x16: (0x07, "6"), 0x1A: (0x08, "7"), 0x1C: (0x09, "8"), 0x19: (0x0A, "9"), 0x1D: (0x0B, "0"),
    0x1B: (0x0C, N_("Moins")), 0x18: (0x0D, N_("Égal")), 0x33: (0x0E, N_("Retour arrière")), 0x30: (0x0F, "Tab"),
    0x0C: (0x10, "Q"), 0x0D: (0x11, "W"), 0x0E: (0x12, "E"), 0x0F: (0x13, "R"), 0x11: (0x14, "T"),
    0x10: (0x15, "Y"), 0x20: (0x16, "U"), 0x22: (0x17, "I"), 0x1F: (0x18, "O"), 0x23: (0x19, "P"),
    0x21: (0x1A, N_("Crochet gauche")), 0x1E: (0x1B, N_("Crochet droit")), 0x24: (0x1C, N_("Entrée")),
    0x3B: (0x1D, N_("Ctrl gauche")),
    0x00: (0x1E, "A"), 0x01: (0x1F, "S"), 0x02: (0x20, "D"), 0x03: (0x21, "F"), 0x05: (0x22, "G"),
    0x04: (0x23, "H"), 0x26: (0x24, "J"), 0x28: (0x25, "K"), 0x25: (0x26, "L"),
    0x29: (0x27, N_("Point-virgule")), 0x27: (0x28, N_("Apostrophe")), 0x0A: (0x29, N_("Grave")),
    0x38: (0x2A, N_("Maj gauche")), 0x2A: (0x2B, N_("Barre oblique inverse")),
    0x06: (0x2C, "Z"), 0x07: (0x2D, "X"), 0x08: (0x2E, "C"), 0x09: (0x2F, "V"), 0x0B: (0x30, "B"),
    0x2D: (0x31, "N"), 0x2E: (0x32, "M"), 0x2B: (0x33, N_("Virgule")), 0x2F: (0x34, N_("Point")),
    0x2C: (0x35, N_("Barre oblique")), 0x3C: (0x36, N_("Maj droite")), 0x43: (0x37, N_("Pavé ×")),
    0x3A: (0x38, N_("Alt gauche (Option)")), 0x31: (0x39, N_("Espace")), 0x39: (0x3A, N_("Verr. Maj")),
    0x47: (0x45, N_("Verr. Num (Clear)")),
    0x59: (0x47, N_("Pavé 7")), 0x5B: (0x48, N_("Pavé 8")), 0x5C: (0x49, N_("Pavé 9")), 0x4E: (0x4A, N_("Pavé −")),
    0x56: (0x4B, N_("Pavé 4")), 0x57: (0x4C, N_("Pavé 5")), 0x58: (0x4D, N_("Pavé 6")), 0x45: (0x4E, N_("Pavé +")),
    0x53: (0x4F, N_("Pavé 1")), 0x54: (0x50, N_("Pavé 2")), 0x55: (0x51, N_("Pavé 3")), 0x52: (0x52, N_("Pavé 0")),
    0x41: (0x53, N_("Pavé .")), 0x51: (0x8D, N_("Pavé =")), 0x4C: (0x9C, N_("Pavé Entrée")),
    0x3E: (0x9D, N_("Ctrl droit")), 0x4B: (0xB5, N_("Pavé /")), 0x3D: (0xB8, N_("Alt droit (Option)")),
    0x73: (0xC7, N_("Début")), 0x7E: (0xC8, N_("Flèche haut")), 0x74: (0xC9, N_("Page haut")),
    0x7B: (0xCB, N_("Flèche gauche")), 0x7C: (0xCD, N_("Flèche droite")), 0x77: (0xCF, N_("Fin")),
    0x7D: (0xD0, N_("Flèche bas")), 0x79: (0xD1, N_("Page bas")), 0x72: (0xD2, N_("Insert (Help)")),
    0x75: (0xD3, N_("Suppr")), 0x37: (0xDB, N_("Windows gauche (Cmd)")), 0x36: (0xDC, N_("Windows droite (Cmd)")),
}

# Valeurs ImGuiKey (Dear ImGui, enum ImGuiKey de crystal-imgui) : touches nommées à partir de 512.
IMGUI_NAMES = (
    "Tab LeftArrow RightArrow UpArrow DownArrow PageUp PageDown Home End Insert Delete Backspace Space Enter "
    "Escape LeftCtrl LeftShift LeftAlt LeftSuper RightCtrl RightShift RightAlt RightSuper Menu "
    + " ".join(f"Num{i}" for i in range(10)) + " "
    + " ".join(chr(c) for c in range(ord("A"), ord("Z") + 1)) + " "
    + " ".join(f"F{i}" for i in range(1, 25)) + " "
    "Apostrophe Comma Minus Period Slash Semicolon Equal LeftBracket Backslash RightBracket GraveAccent "
    "CapsLock ScrollLock NumLock PrintScreen Pause "
    + " ".join(f"Keypad{i}" for i in range(10)) + " "
    "KeypadDecimal KeypadDivide KeypadMultiply KeypadSubtract KeypadAdd KeypadEnter KeypadEqual "
    "AppBack AppForward"
).split()
IMGUI = {name: 512 + i for i, name in enumerate(IMGUI_NAMES)}
IMGUI.update(MouseLeft=655, MouseRight=656, MouseMiddle=657, MouseX1=658, MouseX2=659, MouseWheelX=660, MouseWheelY=661)
IMGUI_MOD = (("Ctrl", 4096), ("Shift", 8192), ("Alt", 16384), ("Super", 32768))

# ImGuiKey par code DirectInput (même position physique).
DIK_TO_IMGUI = {
    0x01: "Escape", 0x0E: "Backspace", 0x0F: "Tab", 0x1C: "Enter", 0x39: "Space",
    0x0C: "Minus", 0x0D: "Equal", 0x1A: "LeftBracket", 0x1B: "RightBracket", 0x27: "Semicolon",
    0x28: "Apostrophe", 0x29: "GraveAccent", 0x2B: "Backslash", 0x33: "Comma", 0x34: "Period", 0x35: "Slash",
    0x1D: "LeftCtrl", 0x2A: "LeftShift", 0x38: "LeftAlt", 0xDB: "LeftSuper",
    0x9D: "RightCtrl", 0x36: "RightShift", 0xB8: "RightAlt", 0xDC: "RightSuper",
    0x3A: "CapsLock", 0x45: "NumLock", 0x46: "ScrollLock",
    0x37: "KeypadMultiply", 0x4A: "KeypadSubtract", 0x4E: "KeypadAdd", 0x53: "KeypadDecimal",
    0x8D: "KeypadEqual", 0x9C: "KeypadEnter", 0xB5: "KeypadDivide",
    0xC7: "Home", 0xC8: "UpArrow", 0xC9: "PageUp", 0xCB: "LeftArrow", 0xCD: "RightArrow",
    0xCF: "End", 0xD0: "DownArrow", 0xD1: "PageDown", 0xD2: "Insert", 0xD3: "Delete",
    0x0B: "Num0", 0x52: "Keypad0", 0x4F: "Keypad1", 0x50: "Keypad2", 0x51: "Keypad3", 0x4B: "Keypad4",
    0x4C: "Keypad5", 0x4D: "Keypad6", 0x47: "Keypad7", 0x48: "Keypad8", 0x49: "Keypad9",
    0x57: "F11", 0x58: "F12", 0x64: "F13", 0x65: "F14", 0x66: "F15",
}
DIK_TO_IMGUI.update({0x02 + i: f"Num{i + 1}" for i in range(9)})
DIK_TO_IMGUI.update({0x3B + i: f"F{i + 1}" for i in range(10)})
for _row, _letters in ((0x10, "QWERTYUIOP"), (0x1E, "ASDFGHJKL"), (0x2C, "ZXCVBNM")):
    DIK_TO_IMGUI.update({_row + i: ch for i, ch in enumerate(_letters)})

# Boutons de souris : (code Skyrim/SKSE, nom, ImGuiKey).
MOUSE = {
    Qt.MouseButton.LeftButton: (256, N_("Clic gauche"), "MouseLeft"),
    Qt.MouseButton.RightButton: (257, N_("Clic droit"), "MouseRight"),
    Qt.MouseButton.MiddleButton: (258, N_("Clic milieu"), "MouseMiddle"),
    Qt.MouseButton.BackButton: (259, N_("Bouton souris 4"), "MouseX1"),
    Qt.MouseButton.ForwardButton: (260, N_("Bouton souris 5"), "MouseX2"),
}

# Sur un clavier ISO (AZERTY…), la touche à gauche de « W » envoie kVK_ANSI_Grave (0x32) :
# c'est la touche OEM_102 de Windows. Sur un clavier ANSI, 0x32 est la touche en haut à gauche.
ANSI_GRAVE = 0x32


def _is_iso_keyboard() -> bool:
    try:
        carbon = ctypes.cdll.LoadLibrary("/System/Library/Frameworks/Carbon.framework/Carbon")
        carbon.LMGetKbdType.restype = ctypes.c_uint8
        carbon.KBGetLayoutType.restype = ctypes.c_uint32
        carbon.KBGetLayoutType.argtypes = [ctypes.c_int16]
        return carbon.KBGetLayoutType(carbon.LMGetKbdType()).to_bytes(4, "big") == b"ISO "
    except (OSError, AttributeError):
        return False


def dik_for(virtual_key: int, iso: bool) -> tuple[int, str] | None:
    """Code DirectInput et nom de la touche, ou None si la touche n'existe pas dans DirectInput."""
    if virtual_key == ANSI_GRAVE:
        return (0x56, N_("Touche < >")) if iso else (0x29, N_("Grave"))
    return MAC_TO_DIK.get(virtual_key)


def load_config() -> dict:
    try:
        data = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}  # config absente ou corrompue -> valeurs par défaut


def save_config(data: dict) -> None:
    try:
        CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
        CONFIG_FILE.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    except OSError as e:
        print(f"Config save failed: {e}", file=sys.stderr)


def detect_system_lang() -> str:
    """Langue de l'interface du Mac (Réglages > Général > Langue et région)."""
    return i18n.system_lang(QLocale.system().uiLanguages())


class KeyCodeViewerApp(QWidget):
    def __init__(self, config: dict):
        super().__init__()
        self.config = config
        self.iso = _is_iso_keyboard()
        self.last = None  # dernier affichage (nom, code, ImGuiKey, modificateurs, caractère), retraduit au changement de langue
        self.setWindowTitle("kEYKODES")
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)

        layout = QVBoxLayout(self)
        layout.setContentsMargins(socle_qt.m("space-8"), socle_qt.m("space-4"), socle_qt.m("space-4"), socle_qt.m("space-6"))
        layout.setSpacing(socle_qt.m("space-2"))

        # En-tête : consigne centrée, drapeau de la langue à droite
        self.label_instruct = socle_qt.role(QLabel(), "muted")
        self.btn_lang = QPushButton()
        self.btn_lang.setObjectName("LangButton")
        self.btn_lang.setCursor(Qt.CursorShape.PointingHandCursor)
        self.btn_lang.setFocusPolicy(Qt.FocusPolicy.NoFocus)  # le clavier reste réservé à la détection
        self.btn_lang.clicked.connect(self._open_language_menu)
        self.head_right = QWidget()
        right = QHBoxLayout(self.head_right)
        right.setContentsMargins(0, 0, 0, 0)
        right.setSpacing(socle_qt.m("space-1"))
        right.addWidget(self.btn_lang)
        self.head_left = QWidget()  # titres centrés malgré les marges asymétriques (largeur fixée par _style)
        head = QHBoxLayout()
        head.setContentsMargins(0, socle_qt.m("space-4"), 0, 0)
        head.addWidget(self.head_left)
        head.addWidget(self.label_instruct, 1, Qt.AlignmentFlag.AlignHCenter)
        head.addWidget(self.head_right, 0, Qt.AlignmentFlag.AlignTop)
        layout.addLayout(head)
        layout.addStretch(1)

        self.label_key_name = socle_qt.role(QLabel(), "heading")
        self.label_skyrim_hex = QLabel()
        self.label_skyrim_hex.setObjectName("IniValue")
        self.label_dec = QLabel()
        self.label_dec.setObjectName("DecValue")
        self.label_imgui = QLabel()
        self.label_imgui.setObjectName("DecValue")
        self.label_chord = socle_qt.role(QLabel(), "muted")
        for lbl in (self.label_key_name, self.label_skyrim_hex, self.label_dec, self.label_imgui, self.label_chord):
            lbl.setAlignment(Qt.AlignmentFlag.AlignCenter)
            layout.addWidget(lbl)
        layout.addStretch(1)

        self.label_hint = socle_qt.role(QLabel(), "meta")
        layout.addWidget(self.label_hint, alignment=Qt.AlignmentFlag.AlignHCenter)

        self._style()
        self.apply_texts()

    def _style(self):
        """Tailles propres à l'appli (consigne, valeurs, drapeau) et de la fenêtre, à l'échelle des textes Socle."""
        k = socle_qt.scale()
        px = lambda size: round(size * k)
        mono = socle_qt.font("mono").family()
        self.setStyleSheet(
            f'QLabel[role="muted"] {{ font-size: {px(14)}px; }}'
            f'QLabel#IniValue {{ font-family: "{mono}"; font-size: {px(32)}px; font-weight: 700; color: {socle_qt.c("accent-text")}; }}'
            f'QLabel#IniValue[status="danger"] {{ color: {socle_qt.c("danger")}; }}'
            f'QLabel#DecValue {{ font-family: "{mono}"; font-size: {px(18)}px; color: {socle_qt.c("text")}; }}'
            f'QPushButton#LangButton {{ background: transparent; border: none; border-radius: {socle_qt.m("radius")}px;'
            f' padding: 0; min-height: 0; font-size: {px(18)}px; }}'
            f'QPushButton#LangButton:hover {{ background: {socle_qt.c("surface-hover")}; }}'
            f'#HeadSide {{ background: transparent; }}'
        )
        self.btn_lang.setFixedSize(px(18) + 12, px(18) + 8)
        for w in (self.head_left, self.head_right):
            w.setObjectName("HeadSide")
        self.head_right.adjustSize()
        self.head_left.setFixedWidth(max(0, self.head_right.sizeHint().width() - socle_qt.m("space-4")))
        self.setFixedSize(*(round(v * max(1.0, k)) for v in BASE_SIZE))

    # --- Langue ---

    def _open_language_menu(self):
        menu = QMenu(self)
        group = QActionGroup(menu)
        chosen = self.config.get("language", AUTO)
        system = detect_system_lang()
        auto = menu.addAction(L("Automatique ({lang})", lang=f"{i18n.FLAGS[system]} {i18n.LANGS[system]}"))
        auto.setData(AUTO)
        menu.addSeparator()
        actions = [auto]
        for code, name in i18n.LANGS.items():
            act = menu.addAction(f"{i18n.FLAGS[code]}  {name}")
            act.setData(code)
            actions.append(act)
        for act in actions:
            act.setCheckable(True)
            act.setChecked(act.data() == chosen)
            group.addAction(act)
        picked = menu.exec(self.btn_lang.mapToGlobal(self.btn_lang.rect().bottomLeft()))
        if picked is not None:
            self.set_language(picked.data())
        self.setFocus()

    def set_language(self, choice: str):
        """Change la langue (code ou AUTO), la mémorise et retraduit l'interface."""
        self.config["language"] = choice
        save_config(self.config)
        i18n.set_lang(detect_system_lang() if choice == AUTO else choice)
        self.apply_texts()

    def apply_texts(self):
        """(Re)traduit tous les textes visibles dans la langue active."""
        code = i18n.get_lang()
        self.btn_lang.setText(i18n.FLAGS[code])
        self.btn_lang.setToolTip(L("Langue : {name}", name=i18n.LANGS[code]))
        self.label_instruct.setText(L("Appuyez sur n'importe quelle touche de votre clavier"))
        self.label_hint.setText(L("Codes DirectInput et ImGuiKey, selon la position physique de la touche (comme sous Windows)."))
        if self.last is None:
            self.label_key_name.setText(L("Touche détectée : {name}", name="—"))
            self.label_skyrim_hex.setText(L("Format .ini court : {value}", value="—"))
            self.label_dec.setText(L("Code décimal : {value}", value="—"))
            self.label_imgui.setText(L("ImGuiKey : {value}", value="—"))
            self.label_chord.setText(L("Accord ImGui : {value}", value="—"))
        else:
            self._show(*self.last)

    def focusNextPrevChild(self, _next: bool) -> bool:
        return False  # Tab doit être capturée comme une touche, pas déplacer le focus

    def _mods(self, event, imgui_name: str | None) -> list[tuple[str, int]]:
        """Modificateurs ImGui tenus (sur macOS, Qt inverse Ctrl et Cmd), hors touche elle-même."""
        m = event.modifiers()
        held = {
            "Ctrl": bool(m & Qt.KeyboardModifier.MetaModifier),
            "Shift": bool(m & Qt.KeyboardModifier.ShiftModifier),
            "Alt": bool(m & Qt.KeyboardModifier.AltModifier),
            "Super": bool(m & Qt.KeyboardModifier.ControlModifier),
        }
        own = next((mod for mod, _ in IMGUI_MOD if imgui_name and mod in imgui_name), None)
        return [(mod, bit) for mod, bit in IMGUI_MOD if held[mod] and mod != own]

    def _show(self, name: str | None, code: int | None, imgui_name: str | None,
              mods: list[tuple[str, int]], char: str = ""):
        """Affiche une touche ; `name` est la clé française du nom (None : touche non reconnue)."""
        self.last = (name, code, imgui_name, mods, char)
        shown = L(name) if name else L("non reconnue")
        if char:
            shown = L("{name} (caractère '{c}')", name=shown, c=char)
        self.label_key_name.setText(L("Touche détectée : {name}", name=shown))
        if code is None:
            self.label_skyrim_hex.setText(L("Format .ini court : {value}", value=L("aucun")))
            self.label_dec.setText(L("Code décimal : {value}", value="—"))
            socle_qt.status(self.label_skyrim_hex, "danger")
        else:
            self.label_skyrim_hex.setText(L("Format .ini court : {value}", value=f"0x{code:02x}"))
            self.label_dec.setText(L("Code décimal : {value}", value=code))
            socle_qt.status(self.label_skyrim_hex, "none")
        if imgui_name is None:
            self.label_imgui.setText(L("ImGuiKey : {value}", value=L("aucune")))
            self.label_chord.setText(L("Accord ImGui : {value}", value="—"))
            return
        key = IMGUI[imgui_name]
        self.label_imgui.setText(L("ImGuiKey : {value}", value=f"{imgui_name} = {key}"))
        chord = "—"
        if mods:
            value = key | sum(bit for _, bit in mods)
            combo = "+".join([mod for mod, _ in mods] + [imgui_name])
            chord = f"{combo} = {value} (0x{value:04x})"
        self.label_chord.setText(L("Accord ImGui : {value}", value=chord))

    def keyPressEvent(self, event):
        char = event.text()
        char = char if char and char.isprintable() and char.strip() else ""
        found = dik_for(event.nativeVirtualKey(), self.iso)
        if found is None:
            self._show(None, None, None, [], char)
            return
        code, name = found
        imgui_name = DIK_TO_IMGUI.get(code)
        self._show(name, code, imgui_name, self._mods(event, imgui_name), char)

    def mousePressEvent(self, event):
        found = MOUSE.get(event.button())
        if found is None:
            return
        code, name, imgui_name = found
        self._show(name, code, imgui_name, self._mods(event, imgui_name))

    def wheelEvent(self, event):
        delta = event.angleDelta()
        if delta.y():
            name, code, imgui_name = (N_("Molette haut"), 264, "MouseWheelY") if delta.y() > 0 else (N_("Molette bas"), 265, "MouseWheelY")
        elif delta.x():
            name, code, imgui_name = N_("Molette horizontale"), None, "MouseWheelX"
        else:
            return
        self._show(name, code, imgui_name, self._mods(event, imgui_name))


if __name__ == "__main__":
    app = QApplication(sys.argv)
    config = load_config()
    choice = config.get("language", AUTO)
    i18n.set_lang(choice if choice in i18n.LANGS else detect_system_lang())
    socle_qt.apply(app)
    window = KeyCodeViewerApp(config)
    window.show()
    update_check.start_qt(window, "kEYKODES", lang=i18n.get_lang)  # nouvelle version ? (au plus une fois par jour)
    window.activateWindow()
    window.setFocus()
    sys.exit(app.exec())
