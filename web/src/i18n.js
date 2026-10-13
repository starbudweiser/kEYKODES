// Équivalent web de src/i18n.py : le texte français sert de clé.
// La table vient de src/i18n_strings.py (exportée par export_i18n.py avant `npm run dev`).
import TR from "./i18n.json";

export const LANGS = { fr: "Français", en: "English", it: "Italiano", es: "Español" };
export const FLAGS = { fr: "🇫🇷", en: "🇬🇧", it: "🇮🇹", es: "🇪🇸" };
const INDEX = { en: 0, it: 1, es: 2 };

let lang = "fr";

export const getLang = () => lang;
export const setLang = (code) => (lang = code in LANGS ? code : "fr");

/** Première langue prise en charge parmi celles du navigateur (comme la langue du Mac dans l'appli). */
export function systemLang(preferred = navigator.languages || [navigator.language], fallback = "en") {
  for (const code of preferred) {
    const c = (code || "").slice(0, 2).toLowerCase();
    if (c in LANGS) return c;
  }
  return fallback;
}

export function L(text, kw = {}) {
  let out = text;
  if (lang !== "fr") out = TR[text]?.[INDEX[lang]] || text;
  return out.replace(/\{(\w+)\}/g, (m, k) => (k in kw ? kw[k] : m));
}
