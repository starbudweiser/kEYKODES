// Calcul des codes : touche physique -> DirectInput / ImGuiKey, accord de modificateurs, texte affiché.

import Foundation

/// Touche macOS 0x32 (kVK_ANSI_Grave) : touche « < > » (OEM_102) sur clavier ISO, « ` » sur clavier ANSI.
public let ansiGrave = 0x32

/// Code DirectInput et nom de la touche, ou nil si elle n'existe pas dans DirectInput.
public func dikFor(virtualKey: Int, iso: Bool) -> DikKey? {
    if virtualKey == ansiGrave {
        return iso ? DikKey(code: 0x56, name: N_("Touche < >")) : DikKey(code: 0x29, name: N_("Grave"))
    }
    return macToDik[virtualKey]
}

/// Modificateurs tenus (noms ImGui du mode d'affichage).
public struct HeldMods: OptionSet, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let ctrl = HeldMods(rawValue: 1)
    public static let shift = HeldMods(rawValue: 2)
    public static let alt = HeldMods(rawValue: 4)
    public static let sup = HeldMods(rawValue: 8)

    func holds(_ name: String) -> Bool {
        switch name {
        case "Ctrl": contains(.ctrl)
        case "Shift": contains(.shift)
        case "Alt": contains(.alt)
        default: contains(.sup)
        }
    }
}

/// Modificateurs de l'accord : ceux qui sont tenus, hors celui de la touche elle-même
/// (Ctrl gauche n'affiche pas « Ctrl+LeftCtrl »).
public func chordMods(held: HeldMods, imguiName: String?) -> [(name: String, bit: Int)] {
    let own = imguiMods.first { m in imguiName.map { $0.contains(m.name) } ?? false }?.name
    return imguiMods.filter { held.holds($0.name) && $0.name != own }
}

/// Une touche ou un bouton détecté, prêt à afficher. `name` est la clé française (nil : non reconnue).
public struct Detection: Equatable {
    public var name: String?
    public var code: Int?
    public var imguiName: String?
    public var mods: [String]   // noms des modificateurs de l'accord
    public var char: String

    public init(name: String?, code: Int?, imguiName: String?, mods: [(name: String, bit: Int)] = [], char: String = "") {
        self.name = name
        self.code = code
        self.imguiName = imguiName
        self.mods = mods.map(\.name)
        self.char = char
    }
}

/// Les cinq lignes de l'affichage.
public struct Readout: Equatable {
    public var keyName: String
    public var hex: String
    public var decimal: String
    public var imgui: String
    public var chord: String
    /// Vrai quand la touche n'a aucun code DirectInput (valeur en rouge).
    public var hexIsDanger: Bool
}

/// Texte affiché pour une détection (nil : rien de pressé encore), dans la langue active.
public func readout(_ d: Detection?) -> Readout {
    guard let d else {
        return Readout(keyName: L("Touche détectée : {name}", ["name": "—"]),
                       hex: L("Format .ini court : {value}", ["value": "—"]),
                       decimal: L("Code décimal : {value}", ["value": "—"]),
                       imgui: L("ImGuiKey : {value}", ["value": "—"]),
                       chord: L("Accord ImGui : {value}", ["value": "—"]), hexIsDanger: false)
    }
    var shown = d.name.map { L($0) } ?? L("non reconnue")
    if !d.char.isEmpty { shown = L("{name} (caractère '{c}')", ["name": shown, "c": d.char]) }
    var r = Readout(keyName: L("Touche détectée : {name}", ["name": shown]), hex: "", decimal: "", imgui: "", chord: "",
                    hexIsDanger: d.code == nil)
    if let code = d.code {
        r.hex = L("Format .ini court : {value}", ["value": "0x" + String(format: "%02x", code)])
        r.decimal = L("Code décimal : {value}", ["value": code])
    } else {
        r.hex = L("Format .ini court : {value}", ["value": L("aucun")])
        r.decimal = L("Code décimal : {value}", ["value": "—"])
    }
    guard let imguiName = d.imguiName, let key = imgui[imguiName] else {
        r.imgui = L("ImGuiKey : {value}", ["value": L("aucune")])
        r.chord = L("Accord ImGui : {value}", ["value": "—"])
        return r
    }
    r.imgui = L("ImGuiKey : {value}", ["value": "\(imguiName) = \(key)"])
    var chord = "—"
    if !d.mods.isEmpty {
        let bits = d.mods.map { name in imguiMods.first { $0.name == name }?.bit ?? 0 }
        let value = bits.reduce(key) { $0 | $1 }
        chord = (d.mods + [imguiName]).joined(separator: "+") + " = \(value) (0x" + String(format: "%04x", value) + ")"
    }
    r.chord = L("Accord ImGui : {value}", ["value": chord])
    return r
}

/// Détection d'une touche du clavier.
public func detectKey(virtualKey: Int, iso: Bool, held: HeldMods, char: String) -> Detection {
    guard let found = dikFor(virtualKey: virtualKey, iso: iso) else {
        return Detection(name: nil, code: nil, imguiName: nil, char: char)
    }
    let im = dikToImgui[found.code]
    return Detection(name: found.name, code: found.code, imguiName: im,
                     mods: chordMods(held: held, imguiName: im), char: char)
}

/// Détection d'un clic (numéro de bouton NSEvent), nil pour un bouton inconnu.
public func detectMouse(button: Int, held: HeldMods) -> Detection? {
    guard let m = mouseButtons[button] else { return nil }
    return Detection(name: m.name, code: m.code, imguiName: m.imgui, mods: chordMods(held: held, imguiName: m.imgui))
}

/// Détection de la molette ; nil si aucun défilement.
public func detectWheel(deltaX: Double, deltaY: Double, held: HeldMods) -> Detection? {
    let d: Detection
    if deltaY != 0 {
        d = deltaY > 0 ? Detection(name: N_("Molette haut"), code: 264, imguiName: "MouseWheelY")
                       : Detection(name: N_("Molette bas"), code: 265, imguiName: "MouseWheelY")
    } else if deltaX != 0 {
        d = Detection(name: N_("Molette horizontale"), code: nil, imguiName: "MouseWheelX")
    } else {
        return nil
    }
    var out = d
    out.mods = chordMods(held: held, imguiName: d.imguiName).map(\.name)
    return out
}

/// Caractère affiché entre parenthèses : seulement s'il est imprimable (ni contrôle, ni espace, ni touche de fonction).
public func printableChar(_ text: String?) -> String {
    guard let text, !text.isEmpty else { return "" }
    let blocked: Set<Unicode.GeneralCategory> = [.control, .format, .surrogate, .privateUse, .unassigned,
                                                  .lineSeparator, .paragraphSeparator, .spaceSeparator]
    guard text.unicodeScalars.allSatisfy({ !blocked.contains($0.properties.generalCategory) }) else { return "" }
    return text
}

/// Les modificateurs seuls arrivent par `flagsChanged` : touche virtuelle -> bit « appuyé » de ce côté (flags
/// dépendants du périphérique, NX_DEVICE*KEYMASK). Verr. Maj n'a pas de bit de côté (bascule).
public let modifierDeviceBits: [Int: UInt] = [
    0x3B: 0x1, 0x38: 0x2, 0x3C: 0x4, 0x37: 0x8, 0x36: 0x10, 0x3A: 0x20, 0x3D: 0x40, 0x3E: 0x2000,
]
public let capsLockKey = 0x39
