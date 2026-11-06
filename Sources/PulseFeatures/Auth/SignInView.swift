#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Same account as the Pulse web app: email and password. Face ID can fill them in next time.
struct SignInView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.scenePhase) private var scenePhase
    @State private var email = ""
    @State private var password = ""
    @State private var useBiometrics = BiometricVault.isAvailable
    @State private var canUseBiometrics = false
    @State private var showAdvanced = false
    @State private var serverText = ""
    @State private var didAutoPrompt = false
    @FocusState private var focus: Field?

    private enum Field { case email, password, server }

    @State private var appeared = false
    private var busy: Bool { session.phase == .signingIn }

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                Spacer(minLength: 56)
                PulseMark(size: 40)
                    .scaleEffect(appeared ? 1 : 0.7).opacity(appeared ? 1 : 0)
                VStack(spacing: 8) {
                    Text("Welcome back").font(PulseFont.display(34, relativeTo: .largeTitle, weight: .heavy)).tracking(-0.6).foregroundStyle(Theme.text)
                    Text(session.isDemo ? "Demo library" : "Use the same account as your Pulse server.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
                }
                VStack(spacing: 12) {
                    field(systemImage: "envelope.fill") {
                        TextField("Email", text: $email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.next)
                            .focused($focus, equals: .email)
                            .onSubmit { focus = .password }
                    }
                    field(systemImage: "lock.fill") {
                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .submitLabel(.go)
                            .focused($focus, equals: .password)
                            .onSubmit { Task { await signIn() } }
                    }
                    if BiometricVault.isAvailable {
                        Toggle(isOn: $useBiometrics) {
                            Label("Sign in with \(BiometricVault.name) next time", systemImage: BiometricVault.symbol).font(.subheadline)
                        }
                        .tint(Theme.accent)
                    }
                    if let message = session.authError {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote).foregroundStyle(Theme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityAddTraits(.updatesFrequently)
                    }
                    Button { Task { await signIn() } } label: {
                        if busy { ProgressView().tint(Theme.onAccent).frame(maxWidth: .infinity) }
                        else { Text("Sign in").frame(maxWidth: .infinity) }
                    }
                    .buttonStyle(.pulsePrimary)
                    .disabled(busy || email.isEmpty || password.isEmpty)
                    .sensoryFeedback(.error, trigger: session.authError) { _, new in new != nil }

                    if canUseBiometrics {
                        Button { Task { await signInWithBiometrics() } } label: {
                            Label("Use \(BiometricVault.name)", systemImage: BiometricVault.symbol).frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.pulseGlass)
                        .disabled(busy)
                    }
                }
                .padding(18)
                .pulseGlass(in: RoundedRectangle(cornerRadius: 32, style: .continuous))
                .pulseGlowBorder(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .frame(maxWidth: 420)
                .offset(y: appeared ? 0 : 40).opacity(appeared ? 1 : 0)

                Button("Explore the demo library") { session.enterDemo() }
                    .font(.footnote).foregroundStyle(Theme.textSecondary).frame(minHeight: 44)

                advanced
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { AuroraBackground() }
        .onAppear { withAnimation(.spring(duration: 0.8, bounce: 0.25).delay(0.1)) { appeared = true } }
        .task {
            email = session.email
            serverText = session.usesCustomServer ? session.serverURL.absoluteString : ""
            canUseBiometrics = BiometricVault.isAvailable && BiometricVault.hasStoredCredentials
            if canUseBiometrics, !didAutoPrompt { didAutoPrompt = true; await signInWithBiometrics() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, canUseBiometrics, session.phase == .signedOut, !busy { Task { await signInWithBiometrics() } }
        }
    }

    private func field<Content: View>(systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage).foregroundStyle(Theme.accent).frame(width: 22)
            content()
        }
        .padding(.horizontal, 16).frame(minHeight: 54)
        .pulseGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
    }

    private var advanced: some View {
        DisclosureGroup(isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Pulse connects to \(PulseDefaults.serverURL.host() ?? "your server") by default. Only change this if you run your own copy.")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
                TextField(PulseDefaults.serverURL.absoluteString, text: $serverText)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    .focused($focus, equals: .server)
                    .padding(.horizontal, 14).frame(minHeight: 46)
                    .pulseGlass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                HStack {
                    Button("Use this server") { Task { await session.useServer(serverText) } }.buttonStyle(.pulseGlass)
                    if session.usesCustomServer {
                        Button("Reset") { serverText = ""; Task { await session.useServer(nil) } }
                            .font(.footnote).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(.top, 8)
        } label: {
            Label("Server", systemImage: "server.rack").font(.footnote).foregroundStyle(Theme.textSecondary)
        }
        .tint(Theme.textSecondary)
        .frame(maxWidth: 420)
        .padding(.bottom, 30)
    }

    private func signIn() async {
        focus = nil
        let ok = await session.signIn(email: email, password: password)
        if ok, useBiometrics, BiometricVault.isAvailable { BiometricVault.store(email: email.lowercased(), password: password) }
        if ok { password = "" }
    }

    private func signInWithBiometrics() async {
        guard let credentials = await BiometricVault.read(reason: "Sign in to Pulse") else { return }
        let ok = await session.signIn(email: credentials.email, password: credentials.password)
        if !ok, session.authError != nil { BiometricVault.remove(); canUseBiometrics = false }
    }
}
#endif
