// Point d'entrée : fenêtre AppKit unique (taille fixe) dont le contenu reçoit tout le clavier et la souris.

import AppKit
import KeyCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let model = KeyModel()
    var config = Config.load()
    var capture: KeyCaptureView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        Socle.apply()
        // « k » dans le gris argent du logo
        Socle.brand("kEYKODES", color: Color(red: 0xa1 / 255, green: 0xa1 / 255, blue: 0xaa / 255))
        buildMenu()

        let host = NSHostingView(rootView: ContentView(model: model))
        host.translatesAutoresizingMaskIntoConstraints = false
        capture = KeyCaptureView(frame: NSRect(origin: .zero, size: WINDOW_SIZE))
        capture.addSubview(host)
        NSLayoutConstraint.activate([
            host.leadingAnchor.constraint(equalTo: capture.leadingAnchor), host.trailingAnchor.constraint(equalTo: capture.trailingAnchor),
            host.topAnchor.constraint(equalTo: capture.topAnchor), host.bottomAnchor.constraint(equalTo: capture.bottomAnchor),
        ])
        // Essais (développement) : KEYKODES_LOG=<fichier> ajoute chaque affichage au fichier
        let logPath = ProcessInfo.processInfo.environment["KEYKODES_LOG"]
        capture.onDetect = { [model] d in
            model.show(d)
            if let logPath {
                let r = model.readout
                let line = [r.keyName, r.hex, r.decimal, r.imgui, r.chord].joined(separator: " | ") + "\n"
                if let h = FileHandle(forWritingAtPath: logPath) { h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close() }
            }
        }

        window = NSWindow(contentRect: NSRect(origin: .zero, size: WINDOW_SIZE), styleMask: [.titled, .closable, .miniaturizable],
                          backing: .buffered, defer: false)
        window.title = "kEYKODES"
        window.contentView = capture
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor(Socle.C.bg)
        window.socleCenter()
        window.makeFirstResponder(capture)
        // Essais en arrière-plan : KEYKODES_QUIET=1 lance l'appli sans prendre le focus
        if ProcessInfo.processInfo.environment["KEYKODES_QUIET"] != nil {
            window.orderBack(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate()
        }
        UpdateEngine.shared.configure(repo: "kEYKODES", lang: { I18n.lang })
        UpdateEngine.shared.start()  // nouvelle version ? (au plus une fois par jour)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { UpdateEngine.shared.installAppMenuItem() }

        // Vérification visuelle (développement) : KEYKODES_SNAPSHOT=<fichier.png> enregistre la fenêtre et quitte
        if let out = ProcessInfo.processInfo.environment["KEYKODES_SNAPSHOT"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                let view = window.contentView!
                if let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                    view.cacheDisplay(in: view.bounds, to: rep)
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: out))
                }
                NSApp.terminate(nil)
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Le clavier reste réservé à la détection
        if let window, window.isKeyWindow { window.makeFirstResponder(capture) }
    }

    // MARK: Langue

    /// Change la langue (code ou « auto »), la mémorise et retraduit l'interface.
    @objc func chooseLanguage(_ sender: NSMenuItem) {
        let choice = Config.normalize(sender.representedObject as? String)
        config["language"] = choice
        Config.save(config)
        I18n.setLang(Config.resolve(choice))
        model.retranslate()
        buildMenu()
        UpdateEngine.shared.insertMenuItem()
        window.makeFirstResponder(capture)
    }

    @objc func showAbout(_ sender: Any?) { About.show() }

    private func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        // Pas de couleur dans les menus : le nom de l'appli y est en texte normal
        let about = appMenu.addItem(withTitle: L("À propos de kEYKODES"), action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L("Masquer kEYKODES"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let others = appMenu.addItem(withTitle: L("Masquer les autres"),
                                     action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        others.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: L("Tout afficher"), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L("Quitter kEYKODES"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        // Menu « Langue » : Automatique + 4 langues, coche sur le choix courant
        let langItem = NSMenuItem()
        let langMenu = NSMenu(title: L("Langue"))
        let current = Config.choice(config)
        func add(_ title: String, _ code: String) {
            let item = langMenu.addItem(withTitle: title, action: #selector(chooseLanguage), keyEquivalent: "")
            item.target = self
            item.representedObject = code
            item.state = code == current ? .on : .off
        }
        add(L("Automatique (système)"), Config.auto)
        langMenu.addItem(.separator())
        for (code, label) in Config.menuLangs { add(label, code) }
        langItem.submenu = langMenu
        main.addItem(langItem)

        let winItem = NSMenuItem()
        let winMenu = NSMenu(title: L("Fenêtre"))
        winMenu.addItem(withTitle: L("Réduire"), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        winItem.submenu = winMenu
        main.addItem(winItem)
        NSApp.mainMenu = main
        NSApp.windowsMenu = winMenu
    }
}

I18n.setLang(Config.resolve(Config.choice(Config.load())))
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)
    app.run()
}
