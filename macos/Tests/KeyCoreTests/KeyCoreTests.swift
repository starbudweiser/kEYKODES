import Foundation
import Testing
@testable import KeyCore

func withLang<T>(_ code: String, _ body: () throws -> T) rethrows -> T {
    I18n.setLang(code)
    defer { I18n.setLang("fr") }
    return try body()
}

@Suite(.serialized) struct KeyCoreTests {
    @Test func everyMacCodeIsTranslated() {
        #expect(macToDik.count == 104)
        for (vk, key) in macToDik {
            #expect(dikFor(virtualKey: vk, iso: false) == key)
            #expect(dikFor(virtualKey: vk, iso: true) == key)
            #expect(key.code > 0 && key.code < 0x100)
        }
    }

    @Test func isoAndAnsiGrave() {
        #expect(dikFor(virtualKey: 0x32, iso: true) == DikKey(code: 0x56, name: "Touche < >"))
        #expect(dikFor(virtualKey: 0x32, iso: false) == DikKey(code: 0x29, name: "Grave"))
        #expect(dikFor(virtualKey: 0x0A, iso: true)?.code == 0x29)  // « § » ISO : même code que Grave
        #expect(dikFor(virtualKey: 0x7F, iso: false) == nil)
    }

    @Test func azertyFollowsPhysicalPosition() {
        // « A » d'un AZERTY est la touche physique Q (kVK 0x0C) : 0x10
        #expect(dikFor(virtualKey: 0x0C, iso: true)?.code == 0x10)
        #expect(dikFor(virtualKey: 0x00, iso: true)?.code == 0x1E)
    }

    @Test func chordCtrlShiftQ() {
        let d = detectKey(virtualKey: 0x0C, iso: false, held: [.ctrl, .shift], char: "")
        let r = readout(d)
        #expect(r.chord == "Accord ImGui : Ctrl+Shift+Q = 12850 (0x3232)")
        #expect(r.imgui == "ImGuiKey : Q = 562")
        #expect(r.hex == "Format .ini court : 0x10")
        #expect(r.decimal == "Code décimal : 16")
    }

    @Test func ownModifierExcluded() {
        // Ctrl gauche tenu : pas de « Ctrl+LeftCtrl »
        let d = detectKey(virtualKey: 0x3B, iso: false, held: [.ctrl], char: "")
        #expect(d.mods.isEmpty)
        #expect(readout(d).chord == "Accord ImGui : —")
        let s = detectKey(virtualKey: 0x38, iso: false, held: [.ctrl, .shift], char: "")
        #expect(s.mods == ["Ctrl"])
        let cmd = detectKey(virtualKey: 0x37, iso: false, held: [.sup, .alt], char: "")
        #expect(cmd.mods == ["Alt"])
    }

    @Test func noDirectInputCodeIsDanger() {
        let r = readout(detectKey(virtualKey: 0x7F, iso: false, held: [], char: ""))
        #expect(r.hexIsDanger)
        #expect(r.hex == "Format .ini court : aucun")
        #expect(r.keyName == "Touche détectée : non reconnue")
        #expect(r.imgui == "ImGuiKey : aucune")
    }

    @Test func mouseAndWheel() {
        #expect(detectMouse(button: 0, held: [])?.code == 256)
        #expect(detectMouse(button: 4, held: [])?.code == 260)
        #expect(detectMouse(button: 9, held: []) == nil)
        #expect(detectWheel(deltaX: 0, deltaY: 3, held: [])?.code == 264)
        #expect(detectWheel(deltaX: 0, deltaY: -3, held: [])?.code == 265)
        #expect(detectWheel(deltaX: 2, deltaY: 0, held: [])?.code == nil)
        #expect(detectWheel(deltaX: 0, deltaY: 0, held: []) == nil)
    }

    @Test func printableChars() {
        #expect(printableChar("a") == "a")
        #expect(printableChar("é") == "é")
        #expect(printableChar(" ") == "")
        #expect(printableChar("\r") == "")
        #expect(printableChar("\u{1}") == "")
        #expect(printableChar("\u{F700}") == "")  // flèche haut
        #expect(printableChar(nil) == "")
    }

    @Test func translationsHaveSamePlaceholders() throws {
        let field = try Regex(#"\{([A-Za-z_][A-Za-z0-9_]*)[^}]*\}"#)
        func fields(_ s: String) -> Set<String> { Set(s.matches(of: field).map { String($0.output[1].substring ?? "") }) }
        for (k, tr) in translations {
            #expect(tr.count == 3, "\(k)")
            for t in tr { #expect(!t.trimmingCharacters(in: .whitespaces).isEmpty, "\(k)") }
            // le nom de l'appli et la ligne des auteurs ne sont pas traduits
            for t in tr { #expect(fields(t) == fields(k), "\(k) -> \(t)") }
        }
    }

    @Test func languageSwitch() {
        withLang("en") { #expect(L("Touche détectée : {name}", ["name": L("Échap")]) == "Detected key: Esc") }
        withLang("it") { #expect(L("Espace") == "Spazio") }
        withLang("es") { #expect(L("aucune") == "ninguna") }
        #expect(L("Espace") == "Espace")
        #expect(I18n.systemLang(["it-IT", "en-US"]) == "it")
        #expect(I18n.systemLang(["de-DE", "es-ES"]) == "es")
        #expect(I18n.systemLang(["de-DE"]) == "en")
    }

    @Test func aboutKeysTranslated() {
        for k in ["À propos de kEYKODES", "Quitter kEYKODES", "Langue", "Automatique (système)"] {
            #expect(translations[k] != nil, "\(k)")
        }
    }

    @Test func configRoundTrip() throws {
        let url = URL(fileURLWithPath: NSTemporaryDirectory() + "keykodes-test-\(UUID().uuidString)/config.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        #expect(Config.load(url).isEmpty)
        var c: [String: Any] = ["autre": 1]
        c["language"] = Config.normalize("it")
        Config.save(c, to: url)
        let back = Config.load(url)
        #expect(Config.choice(back) == "it")
        #expect(back["autre"] as? Int == 1)
        #expect(Config.normalize("xx") == "auto")
        #expect(Config.resolve("auto", preferred: ["es-ES"]) == "es")
        #expect(Config.resolve("fr", preferred: ["es-ES"]) == "fr")
    }

    /// Mêmes textes que la version Python (golden.json produit par KEYCODES.py : toutes les touches, 4 langues).
    @Test func matchesPythonVersion() throws {
        struct Case: Decodable {
            let lang: String, `case`: String
            let vk: Int?, iso: Bool?, button: Int?, mods: [String]?, char: String?
            let lines: [String?]
        }
        let url = try #require(Bundle.module.url(forResource: "golden", withExtension: "json"))
        let cases = try JSONDecoder().decode([Case].self, from: Data(contentsOf: url))
        #expect(cases.count > 1500)
        func held(_ names: [String]) -> HeldMods {
            names.reduce(into: HeldMods()) {
                switch $1 { case "ctrl": $0.insert(.ctrl); case "shift": $0.insert(.shift); case "alt": $0.insert(.alt); default: $0.insert(.sup) }
            }
        }
        for c in cases {
            I18n.setLang(c.lang)
            let d: Detection?
            switch c.case {
            case "initial": d = nil
            case "key": d = detectKey(virtualKey: c.vk!, iso: c.iso!, held: held(c.mods!), char: c.char!)
            case "mouse": d = detectMouse(button: c.button!, held: held(c.mods!))
            case "wheelUp": d = detectWheel(deltaX: 0, deltaY: 1, held: held(c.mods!))
            case "wheelDown": d = detectWheel(deltaX: 0, deltaY: -1, held: held(c.mods!))
            default: d = detectWheel(deltaX: 1, deltaY: 0, held: held(c.mods!))
            }
            let r = readout(d)
            let got = [r.keyName, r.hex, r.decimal, r.imgui, r.chord]
            let want = c.lines.prefix(5).map { $0 ?? "" }
            #expect(got == want, "\(c.lang) \(c.case) vk=\(c.vk.map(String.init) ?? "-") mods=\(c.mods ?? [])")
            if c.case == "key" || c.case == "mouse" { #expect(r.hexIsDanger == (c.lines[5] == "danger")) }
        }
        I18n.setLang("fr")
    }
}
