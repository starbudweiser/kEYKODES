// Capture du clavier et de la souris : vue AppKit en premier répondeur, qui reçoit tous les événements.
//
// - keyDown : touches ordinaires (position physique = event.keyCode, comme sous Windows) ; Tab est une touche
//   comme une autre (la vue ne passe jamais l'événement à super, donc pas de navigation au clavier).
// - flagsChanged : Maj, Ctrl, Option, Cmd seuls et Verr. Maj n'arrivent pas par keyDown.
// - souris : boutons 1 à 5 ; molette verticale et horizontale.

import AppKit
import Carbon.HIToolbox
import KeyCore
import SwiftUI

@MainActor
final class KeyCaptureView: NSView {
    var onDetect: ((Detection) -> Void)?
    let iso: Bool = {
        // Clavier ISO (AZERTY…) : la touche à gauche de « W » envoie kVK_ANSI_Grave (OEM_102 sous Windows)
        KBGetLayoutType(Int16(LMGetKbdType())) == Int32(kKeyboardISO)
    }()

    override var acceptsFirstResponder: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? { frame.contains(point) ? self : nil }  // aucun contrôle dessous
    override func becomeFirstResponder() -> Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    static func held(_ flags: NSEvent.ModifierFlags) -> HeldMods {
        var m: HeldMods = []
        if flags.contains(.control) { m.insert(.ctrl) }
        if flags.contains(.shift) { m.insert(.shift) }
        if flags.contains(.option) { m.insert(.alt) }
        if flags.contains(.command) { m.insert(.sup) }
        return m
    }

    override func keyDown(with event: NSEvent) {
        let char = printableChar(event.characters)
        onDetect?(detectKey(virtualKey: Int(event.keyCode), iso: iso, held: Self.held(event.modifierFlags), char: char))
    }

    override func keyUp(with event: NSEvent) {}

    override func flagsChanged(with event: NSEvent) {
        let vk = Int(event.keyCode)
        let raw = event.modifierFlags.rawValue
        let pressed: Bool
        if vk == capsLockKey {
            pressed = true  // bascule : un affichage à chaque changement
        } else if let bit = modifierDeviceBits[vk] {
            let anyDeviceBit = modifierDeviceBits.values.contains { raw & $0 != 0 }
            // Bits de côté absents (événement synthétique) : on se rabat sur l'indicateur général de la famille
            pressed = anyDeviceBit ? raw & bit != 0 : Self.held(event.modifierFlags).contains(Self.family(vk))
        } else {
            return  // fn et autres : pas dans DirectInput
        }
        guard pressed else { return }  // le relâchement n'affiche rien (comme keyPressEvent)
        onDetect?(detectKey(virtualKey: vk, iso: iso, held: Self.held(event.modifierFlags), char: ""))
    }

    private static func family(_ vk: Int) -> HeldMods {
        switch vk {
        case 0x3B, 0x3E: .ctrl
        case 0x38, 0x3C: .shift
        case 0x3A, 0x3D: .alt
        default: .sup
        }
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Les raccourcis du menu (⌘Q, ⌘H, ⌘M) restent actifs ; le reste arrive par keyDown.
        super.performKeyEquivalent(with: event)
    }

    private func click(_ event: NSEvent) {
        if let d = detectMouse(button: event.buttonNumber, held: Self.held(event.modifierFlags)) { onDetect?(d) }
    }
    override func mouseDown(with event: NSEvent) { click(event) }
    override func rightMouseDown(with event: NSEvent) { click(event) }
    override func otherMouseDown(with event: NSEvent) { click(event) }

    override func scrollWheel(with event: NSEvent) {
        if let d = detectWheel(deltaX: Double(event.scrollingDeltaX), deltaY: Double(event.scrollingDeltaY),
                               held: Self.held(event.modifierFlags)) { onDetect?(d) }
    }
}
