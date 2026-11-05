// Interface : consigne, nom de la touche, format .ini court, code décimal, ImGuiKey, accord, aide.
// Mêmes tailles et mêmes marges que la version Python (Socle : textes × 1,1).

import KeyCore
import Observation
import SwiftUI

@MainActor @Observable
final class KeyModel {
    var last: Detection?
    var tick = 0  // change à chaque retraduction (changement de langue)

    var readout: Readout { _ = tick; return KeyCore.readout(last) }

    func show(_ d: Detection) { last = d }
    func retranslate() { tick += 1 }
}

// Fenêtre : 750 × 400 pour des textes à 100 %, mise à l'échelle des textes Socle (110 %).
let WINDOW_SIZE = CGSize(width: (750 * max(1, Socle.scale)).rounded(), height: (400 * max(1, Socle.scale)).rounded())

private extension Socle.TextStyle {
    static let iniValue = Socle.TextStyle(size: 32, weight: .bold, tracking: 0, mono: true)
    static let decValue = Socle.TextStyle(size: 18, weight: .regular, tracking: 0, mono: true)
}

struct ContentView: View {
    var model: KeyModel

    var body: some View {
        let r = model.readout
        VStack(spacing: Socle.M.space2) {
            Text(L("Appuyez sur n'importe quelle touche de votre clavier"))
                .socle(Socle.T.bodyLg).foregroundStyle(Socle.C.textMuted)
                .frame(maxWidth: .infinity)
                .padding(.top, Socle.M.space4)
                .padding(.trailing, Socle.M.space4)
            Spacer(minLength: 0)
            Text(verbatim: r.keyName).socle(Socle.T.heading).foregroundStyle(Socle.C.textStrong)
            Text(verbatim: r.hex).socle(.iniValue)
                .foregroundStyle(r.hexIsDanger ? Socle.C.danger : Socle.C.accentText)
            Text(verbatim: r.decimal).socle(.decValue).foregroundStyle(Socle.C.text)
            Text(verbatim: r.imgui).socle(.decValue).foregroundStyle(Socle.C.text)
            Text(verbatim: r.chord).socle(Socle.T.bodyLg).foregroundStyle(Socle.C.textMuted)
            Spacer(minLength: 0)
            Text(L("Codes DirectInput et ImGuiKey, selon la position physique de la touche (comme sous Windows)."))
                .socle(Socle.T.meta).foregroundStyle(Socle.C.textSubtle)
        }
        .multilineTextAlignment(.center)
        .lineLimit(1)
        .padding(.leading, Socle.M.space8).padding(.top, Socle.M.space4)
        .padding(.trailing, Socle.M.space4).padding(.bottom, Socle.M.space6)
        .frame(width: WINDOW_SIZE.width, height: WINDOW_SIZE.height)
        .background(Socle.C.bg)
    }
}
