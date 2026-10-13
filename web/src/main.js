// Réplique web de src/KEYCODES.py : mêmes textes (mêmes clés de traduction), mêmes codes.
import "./style.css";
import { L, LANGS, FLAGS, getLang, setLang, systemLang } from "./i18n.js";

// Codes DirectInput (Skyrim .ini) par KeyboardEvent.code (position physique de la touche)
const DIK = {
  Escape: [0x01, "Échap"], F1: [0x3b, "F1"], F2: [0x3c, "F2"], F3: [0x3d, "F3"], F4: [0x3e, "F4"],
  F5: [0x3f, "F5"], F6: [0x40, "F6"], F7: [0x41, "F7"], F8: [0x42, "F8"], F9: [0x43, "F9"],
  F10: [0x44, "F10"], F11: [0x57, "F11"], F12: [0x58, "F12"], F13: [0x64, "F13"], F14: [0x65, "F14"], F15: [0x66, "F15"],
  Digit1: [0x02, "1"], Digit2: [0x03, "2"], Digit3: [0x04, "3"], Digit4: [0x05, "4"], Digit5: [0x06, "5"],
  Digit6: [0x07, "6"], Digit7: [0x08, "7"], Digit8: [0x09, "8"], Digit9: [0x0a, "9"], Digit0: [0x0b, "0"],
  Minus: [0x0c, "Moins"], Equal: [0x0d, "Égal"], Backspace: [0x0e, "Retour arrière"], Tab: [0x0f, "Tab"],
  KeyQ: [0x10, "Q"], KeyW: [0x11, "W"], KeyE: [0x12, "E"], KeyR: [0x13, "R"], KeyT: [0x14, "T"],
  KeyY: [0x15, "Y"], KeyU: [0x16, "U"], KeyI: [0x17, "I"], KeyO: [0x18, "O"], KeyP: [0x19, "P"],
  BracketLeft: [0x1a, "Crochet gauche"], BracketRight: [0x1b, "Crochet droit"], Enter: [0x1c, "Entrée"],
  ControlLeft: [0x1d, "Ctrl gauche"],
  KeyA: [0x1e, "A"], KeyS: [0x1f, "S"], KeyD: [0x20, "D"], KeyF: [0x21, "F"], KeyG: [0x22, "G"],
  KeyH: [0x23, "H"], KeyJ: [0x24, "J"], KeyK: [0x25, "K"], KeyL: [0x26, "L"],
  Semicolon: [0x27, "Point-virgule"], Quote: [0x28, "Apostrophe"], Backquote: [0x29, "Grave"],
  ShiftLeft: [0x2a, "Maj gauche"], Backslash: [0x2b, "Barre oblique inverse"],
  KeyZ: [0x2c, "Z"], KeyX: [0x2d, "X"], KeyC: [0x2e, "C"], KeyV: [0x2f, "V"], KeyB: [0x30, "B"],
  KeyN: [0x31, "N"], KeyM: [0x32, "M"], Comma: [0x33, "Virgule"], Period: [0x34, "Point"],
  Slash: [0x35, "Barre oblique"], ShiftRight: [0x36, "Maj droite"], NumpadMultiply: [0x37, "Pavé ×"],
  AltLeft: [0x38, "Alt gauche (Option)"], Space: [0x39, "Espace"], CapsLock: [0x3a, "Verr. Maj"],
  NumLock: [0x45, "Verr. Num (Clear)"], ScrollLock: [0x46, "Arrêt défil"],
  Numpad7: [0x47, "Pavé 7"], Numpad8: [0x48, "Pavé 8"], Numpad9: [0x49, "Pavé 9"], NumpadSubtract: [0x4a, "Pavé −"],
  Numpad4: [0x4b, "Pavé 4"], Numpad5: [0x4c, "Pavé 5"], Numpad6: [0x4d, "Pavé 6"], NumpadAdd: [0x4e, "Pavé +"],
  Numpad1: [0x4f, "Pavé 1"], Numpad2: [0x50, "Pavé 2"], Numpad3: [0x51, "Pavé 3"], Numpad0: [0x52, "Pavé 0"],
  NumpadDecimal: [0x53, "Pavé ."], IntlBackslash: [0x56, "Touche < >"], NumpadEqual: [0x8d, "Pavé ="],
  NumpadEnter: [0x9c, "Pavé Entrée"], ControlRight: [0x9d, "Ctrl droit"], NumpadDivide: [0xb5, "Pavé /"],
  AltRight: [0xb8, "Alt droit (Option)"], Home: [0xc7, "Début"], ArrowUp: [0xc8, "Flèche haut"],
  PageUp: [0xc9, "Page haut"], ArrowLeft: [0xcb, "Flèche gauche"], ArrowRight: [0xcd, "Flèche droite"],
  End: [0xcf, "Fin"], ArrowDown: [0xd0, "Flèche bas"], PageDown: [0xd1, "Page bas"],
  Insert: [0xd2, "Insert"], Help: [0xd2, "Insert (Help)"], Delete: [0xd3, "Suppr"],
  MetaLeft: [0xdb, "Windows gauche (Cmd)"], MetaRight: [0xdc, "Windows droite (Cmd)"],
};

// Valeurs ImGuiKey (Dear ImGui, enum ImGuiKey de crystal-imgui) : touches nommées à partir de 512.
const range = (n, f) => Array.from({ length: n }, (_, i) => f(i));
const IMGUI_NAMES = [
  ..."Tab LeftArrow RightArrow UpArrow DownArrow PageUp PageDown Home End Insert Delete Backspace Space Enter".split(" "),
  ..."Escape LeftCtrl LeftShift LeftAlt LeftSuper RightCtrl RightShift RightAlt RightSuper Menu".split(" "),
  ...range(10, (i) => `Num${i}`), ...range(26, (i) => String.fromCharCode(65 + i)), ...range(24, (i) => `F${i + 1}`),
  ..."Apostrophe Comma Minus Period Slash Semicolon Equal LeftBracket Backslash RightBracket GraveAccent".split(" "),
  ..."CapsLock ScrollLock NumLock PrintScreen Pause".split(" "), ...range(10, (i) => `Keypad${i}`),
  ..."KeypadDecimal KeypadDivide KeypadMultiply KeypadSubtract KeypadAdd KeypadEnter KeypadEqual AppBack AppForward".split(" "),
];
const IMGUI = Object.fromEntries(IMGUI_NAMES.map((n, i) => [n, 512 + i]));
Object.assign(IMGUI, { MouseLeft: 655, MouseRight: 656, MouseMiddle: 657, MouseX1: 658, MouseX2: 659, MouseWheelX: 660, MouseWheelY: 661 });
const IMGUI_MOD = [["Ctrl", 4096, "ctrlKey"], ["Shift", 8192, "shiftKey"], ["Alt", 16384, "altKey"], ["Super", 32768, "metaKey"]];

// ImGuiKey par KeyboardEvent.code (même position physique que le code DirectInput).
const CODE_TO_IMGUI = {
  Escape: "Escape", Backspace: "Backspace", Tab: "Tab", Enter: "Enter", Space: "Space",
  Minus: "Minus", Equal: "Equal", BracketLeft: "LeftBracket", BracketRight: "RightBracket", Semicolon: "Semicolon",
  Quote: "Apostrophe", Backquote: "GraveAccent", Backslash: "Backslash", Comma: "Comma", Period: "Period", Slash: "Slash",
  ControlLeft: "LeftCtrl", ShiftLeft: "LeftShift", AltLeft: "LeftAlt", MetaLeft: "LeftSuper",
  ControlRight: "RightCtrl", ShiftRight: "RightShift", AltRight: "RightAlt", MetaRight: "RightSuper",
  CapsLock: "CapsLock", NumLock: "NumLock", ScrollLock: "ScrollLock",
  NumpadMultiply: "KeypadMultiply", NumpadSubtract: "KeypadSubtract", NumpadAdd: "KeypadAdd", NumpadDecimal: "KeypadDecimal",
  NumpadEqual: "KeypadEqual", NumpadEnter: "KeypadEnter", NumpadDivide: "KeypadDivide",
  Home: "Home", ArrowUp: "UpArrow", PageUp: "PageUp", ArrowLeft: "LeftArrow", ArrowRight: "RightArrow",
  End: "End", ArrowDown: "DownArrow", PageDown: "PageDown", Insert: "Insert", Help: "Insert", Delete: "Delete",
};
for (let i = 0; i < 10; i++) { CODE_TO_IMGUI[`Digit${i}`] = `Num${i}`; CODE_TO_IMGUI[`Numpad${i}`] = `Keypad${i}`; }
for (let i = 1; i <= 15; i++) CODE_TO_IMGUI[`F${i}`] = `F${i}`;
for (let i = 0; i < 26; i++) { const c = String.fromCharCode(65 + i); CODE_TO_IMGUI[`Key${c}`] = c; }

// Boutons de souris : [code Skyrim/SKSE, nom, ImGuiKey] par MouseEvent.button.
const MOUSE = [[256, "Clic gauche", "MouseLeft"], [258, "Clic milieu", "MouseMiddle"], [257, "Clic droit", "MouseRight"],
  [259, "Bouton souris 4", "MouseX1"], [260, "Bouton souris 5", "MouseX2"]];

const $ = (id) => document.getElementById(id);

// Modificateurs ImGui tenus, hors touche elle-même.
const modsOf = (e, imguiName) => IMGUI_MOD.filter(([mod, , prop]) => e[prop] && !(imguiName || "").includes(mod));

// Dernier affichage, retraduit au changement de langue
let last = null;

/** Affiche une touche ; `name` est la clé française du nom (null : touche non reconnue). */
function show(name, code, imguiName, mods, char = "") {
  last = [name, code, imguiName, mods, char];
  let shown = name ? L(name) : L("non reconnue");
  if (char) shown = L("{name} (caractère '{c}')", { name: shown, c: char });
  $("key-name").textContent = L("Touche détectée : {name}", { name: shown });
  $("skyrim-hex").classList.toggle("is-unknown", code == null);
  $("skyrim-hex").textContent = L("Format .ini court : {value}", { value: code == null ? L("aucun") : `0x${code.toString(16).padStart(2, "0")}` });
  $("dec").textContent = L("Code décimal : {value}", { value: code ?? "—" });
  if (!imguiName) {
    $("imgui").textContent = L("ImGuiKey : {value}", { value: L("aucune") });
    $("chord").textContent = L("Accord ImGui : {value}", { value: "—" });
    return;
  }
  const key = IMGUI[imguiName];
  $("imgui").textContent = L("ImGuiKey : {value}", { value: `${imguiName} = ${key}` });
  let chord = "—";
  if (mods.length) {
    const value = mods.reduce((acc, [, bit]) => acc | bit, key);
    chord = `${[...mods.map(([m]) => m), imguiName].join("+")} = ${value} (0x${value.toString(16).padStart(4, "0")})`;
  }
  $("chord").textContent = L("Accord ImGui : {value}", { value: chord });
}

// --- Langue ---

const LANG_KEY = "keykodes-preview-lang";
let langChoice = "auto";

function loadLangChoice() {
  try {
    langChoice = localStorage.getItem(LANG_KEY) || "auto";
  } catch {
    langChoice = "auto";
  }
  setLang(langChoice === "auto" ? systemLang() : langChoice);
}

function setLanguage(choice) {
  langChoice = choice;
  try {
    localStorage.setItem(LANG_KEY, choice);
  } catch {
    /* préférence non mémorisée : sans gravité */
  }
  setLang(choice === "auto" ? systemLang() : choice);
  applyTexts();
}

function buildLangMenu() {
  const sys = systemLang();
  const items = [["auto", L("Automatique ({lang})", { lang: `${FLAGS[sys]} ${LANGS[sys]}` })], null,
    ...Object.entries(LANGS).map(([code, name]) => [code, `${FLAGS[code]}  ${name}`])];
  $("lang-menu").replaceChildren(
    ...items.map((item) => {
      if (!item) return Object.assign(document.createElement("hr"), { className: "lang-menu__sep" });
      const [code, label] = item;
      const btn = document.createElement("button");
      btn.type = "button";
      btn.className = "lang-menu__item";
      btn.setAttribute("role", "menuitemradio");
      btn.setAttribute("aria-checked", String(code === langChoice));
      btn.textContent = label;
      btn.addEventListener("click", () => {
        closeLangMenu();
        setLanguage(code);
      });
      return btn;
    }),
  );
}

const langMenuOpen = () => !$("lang-menu").hidden;

function openLangMenu() {
  buildLangMenu();
  $("lang-menu").hidden = false;
  $("lang").setAttribute("aria-expanded", "true");
}

function closeLangMenu() {
  $("lang-menu").hidden = true;
  $("lang").setAttribute("aria-expanded", "false");
}

function applyTexts() {
  const code = getLang();
  document.documentElement.lang = code;
  $("lang").textContent = FLAGS[code];
  $("lang").title = L("Langue : {name}", { name: LANGS[code] });
  $("lang").setAttribute("aria-label", $("lang").title);
  $("instruct").textContent = L("Appuyez sur n'importe quelle touche de votre clavier");
  $("hint").textContent = L("Codes DirectInput et ImGuiKey, selon la position physique de la touche (comme sous Windows).");
  if (last) { show(...last); return; }
  $("key-name").textContent = L("Touche détectée : {name}", { name: "—" });
  $("skyrim-hex").textContent = L("Format .ini court : {value}", { value: "—" });
  $("dec").textContent = L("Code décimal : {value}", { value: "—" });
  $("imgui").textContent = L("ImGuiKey : {value}", { value: "—" });
  $("chord").textContent = L("Accord ImGui : {value}", { value: "—" });
}

// Le bouton et le menu des langues gardent leurs clics ; le clavier reste réservé à la détection
$("lang").addEventListener("mousedown", (e) => e.stopPropagation());
$("lang-menu").addEventListener("mousedown", (e) => e.stopPropagation());
$("lang").addEventListener("click", () => (langMenuOpen() ? closeLangMenu() : openLangMenu()));

loadLangChoice();
applyTexts();

window.addEventListener("keydown", (e) => {
  e.preventDefault();
  if (langMenuOpen()) closeLangMenu();
  const char = e.key.length === 1 && e.key.trim() ? e.key : "";
  const found = DIK[e.code];
  if (!found) { show(null, null, null, [], char); return; }
  const [code, name] = found;
  const imguiName = CODE_TO_IMGUI[e.code];
  show(name, code, imguiName, modsOf(e, imguiName), char);
});

window.addEventListener("mousedown", (e) => {
  if (langMenuOpen()) { closeLangMenu(); return; }
  const found = MOUSE[e.button];
  if (!found) return;
  e.preventDefault();
  const [code, name, imguiName] = found;
  show(name, code, imguiName, modsOf(e, imguiName));
});
window.addEventListener("contextmenu", (e) => e.preventDefault());

window.addEventListener("wheel", (e) => {
  if (e.deltaY) show(e.deltaY < 0 ? "Molette haut" : "Molette bas", e.deltaY < 0 ? 264 : 265, "MouseWheelY", modsOf(e, "MouseWheelY"));
  else if (e.deltaX) show("Molette horizontale", null, "MouseWheelX", modsOf(e, "MouseWheelX"));
}, { passive: true });
