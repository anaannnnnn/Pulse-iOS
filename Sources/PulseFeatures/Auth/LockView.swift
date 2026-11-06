#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Glass keypad over a slow aurora. The server enforces the PIN; this is just the front door.
struct LockView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @State private var digits = ""
    @State private var shake = 0
    @State private var checking = false
    @State private var offerBiometrics = false
    @State private var didAutoPrompt = false
    @AppStorage("pulse.pinLength") private var pinLength = 0

    private let keys: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["bio", "0", "del"]]

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)
            PulseMark(size: 34)
            VStack(spacing: 8) {
                Text(session.isDemo ? "Demo library" : "Enter passcode").font(PulseFont.title(.title3)).foregroundStyle(Theme.text)
                dots
                Text(statusText).font(.footnote).foregroundStyle(session.pinError == nil ? Theme.textSecondary : Theme.danger)
                    .frame(minHeight: 34).multilineTextAlignment(.center).padding(.horizontal, 30)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            keypad
            Button(session.isDemo ? "Exit demo" : "Change server") { pinLength = 0; session.forgetServer() }
                .font(.footnote).foregroundStyle(Theme.textSecondary).frame(minHeight: 44)
            Spacer(minLength: 10)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { AuroraBackground() }
        .sensoryFeedback(.error, trigger: shake)
        .task {
            offerBiometrics = BiometricVault.isAvailable && BiometricVault.hasStoredPIN && !session.isDemo
            if offerBiometrics, !didAutoPrompt { didAutoPrompt = true; await unlockWithBiometrics() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, offerBiometrics, session.phase == .locked { Task { await unlockWithBiometrics() } }
        }
    }

    private var statusText: String {
        if let error = session.pinError { return error }
        return session.isDemo ? "Demo passcode is 6442." : "Your library is locked."
    }

    private var dots: some View {
        HStack(spacing: 16) {
            ForEach(0..<max(pinLength > 0 ? pinLength : 6, digits.count), id: \.self) { index in
                Circle()
                    .fill(index < digits.count ? AnyShapeStyle(Theme.gradient) : AnyShapeStyle(Color.white.opacity(0.18)))
                    .frame(width: 14, height: 14)
                    .scaleEffect(index < digits.count ? 1.15 : 1)
                    .animation(.snappy(duration: 0.18), value: digits.count)
            }
        }
        .modifier(Shake(travel: 10, shakesPerUnit: 3, animatableData: CGFloat(shake)))
        .animation(.default, value: shake)
        .accessibilityElement()
        .accessibilityLabel("\(digits.count) digits entered")
    }

    private var keypad: some View {
        PulseGlassGroup(spacing: 14) {
            VStack(spacing: 14) {
                ForEach(keys, id: \.self) { row in
                    HStack(spacing: 14) {
                        ForEach(row, id: \.self) { key in keyButton(key) }
                    }
                }
            }
        }
        .disabled(checking)
    }

    @ViewBuilder
    private func keyButton(_ key: String) -> some View {
        switch key {
        case "bio":
            if pinLength == 0, digits.count >= 4 {
                Button { Task { await submit() } } label: { Image(systemName: "checkmark.circle.fill").font(.title) }
                    .buttonStyle(KeyStyle(plain: true)).foregroundStyle(Theme.accentSoft).accessibilityLabel("Unlock")
            } else if offerBiometrics {
                Button { Task { await unlockWithBiometrics() } } label: { Image(systemName: BiometricVault.symbol).font(.title2) }
                    .buttonStyle(KeyStyle(plain: true)).accessibilityLabel("Unlock with \(BiometricVault.name)")
            } else { Color.clear.frame(width: 78, height: 78) }
        case "del":
            Button { if !digits.isEmpty { digits.removeLast() } } label: { Image(systemName: "delete.left").font(.title2) }
                .buttonStyle(KeyStyle(plain: true)).accessibilityLabel("Delete")
        default:
            Button { press(key) } label: { Text(key).font(PulseFont.display(28, relativeTo: .title)) }
                .buttonStyle(KeyStyle(plain: false))
        }
    }

    private func press(_ key: String) {
        guard digits.count < 8 else { return }
        digits.append(key)
        session.pinError = nil
        // Once the passcode length is known, submit automatically. Until then the check-mark key submits,
        // so a half-typed passcode never burns one of the server's five attempts.
        if pinLength > 0, digits.count == pinLength { Task { await submit() } }
    }

    private func submit() async {
        let snapshot = digits
        guard snapshot.count >= 4, !checking else { return }
        checking = true
        let ok = await session.unlock(pin: snapshot)
        checking = false
        if ok {
            pinLength = snapshot.count
            if BiometricVault.isAvailable, !session.isDemo, !BiometricVault.hasStoredPIN { _ = BiometricVault.store(pin: snapshot) }
            digits = ""
        } else {
            shake += 1
            digits = ""
        }
    }

    private func unlockWithBiometrics() async {
        guard let pin = await BiometricVault.readPIN(reason: "Unlock Pulse") else { return }
        checking = true
        let ok = await session.unlock(pin: pin)
        checking = false
        if !ok { BiometricVault.remove(); offerBiometrics = false }
    }
}

private struct KeyStyle: ButtonStyle {
    let plain: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Theme.text)
            .frame(width: 78, height: 78)
            .modifier(KeyBackground(plain: plain))
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: configuration.isPressed) { _, pressed in pressed }
    }
}

private struct KeyBackground: ViewModifier {
    let plain: Bool
    func body(content: Content) -> some View {
        if plain { content } else { content.pulseGlass(in: Circle(), interactive: true) }
    }
}

struct Shake: GeometryEffect {
    var travel: CGFloat
    var shakesPerUnit: Int
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: travel * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0))
    }
}
#endif
