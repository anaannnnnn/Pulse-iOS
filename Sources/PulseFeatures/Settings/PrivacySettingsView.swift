#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct PrivacySettingsView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(AppSession.self) private var session
    @State private var showChangePassword = false
    @State private var biometricsOn = BiometricVault.hasStoredCredentials
    @State private var enrolling = false
    @State private var enrollPassword = ""

    var body: some View {
        @Bindable var store = stores.settings
        SettingsForm(title: "Privacy & security") {
            Section {
                LabeledContent("Signed in as", value: session.isDemo ? "Demo" : (session.email.isEmpty ? "—" : session.email))
                if !session.isDemo { Button("Change password", systemImage: "key.fill") { showChangePassword = true } }
                if BiometricVault.isAvailable && !session.isDemo {
                    Toggle(isOn: Binding(get: { biometricsOn }, set: { setBiometrics($0) })) {
                        Label("Sign in with \(BiometricVault.name)", systemImage: BiometricVault.symbol)
                    }
                }
                Picker("Sign out when idle", selection: $store.settings.autoLockMinutes) {
                    Text("Never").tag(0)
                    ForEach([1, 5, 15, 30, 60], id: \.self) { Text("After \($0) min").tag($0) }
                }
            } header: { Text("Account") } footer: {
                Text("Your account is checked by your Pulse server. After several wrong tries sign-in is paused for a while.")
            }
            Section {
                Toggle("Blur thumbnails", isOn: $store.settings.blurThumbnails)
                Toggle("Hide in app switcher", isOn: $store.settings.hideFromRecents)
            } header: { Text("Screen") } footer: {
                Text("Blur hides artwork until you open a video. The app switcher cover hides Pulse when you leave the app.")
            }
        }
        .onChange(of: store.settings.autoLockMinutes) { _, minutes in session.configureAutoLock(minutes: minutes); store.scheduleSave() }
        .onChange(of: store.settings.blurThumbnails) { _, _ in store.scheduleSave() }
        .onChange(of: store.settings.hideFromRecents) { _, _ in store.scheduleSave() }
        .sheet(isPresented: $showChangePassword) { ChangePasswordSheet().presentationDetents([.medium]) }
        .alert("Confirm your password", isPresented: $enrolling) {
            SecureField("Password", text: $enrollPassword)
            Button("Enable") { enableBiometrics() }
            Button("Cancel", role: .cancel) { biometricsOn = false; enrollPassword = "" }
        } message: { Text("It is kept in the Keychain and released only by \(BiometricVault.name).") }
        .task { await store.load() }
    }

    private func setBiometrics(_ on: Bool) {
        if on { enrollPassword = ""; enrolling = true } else { BiometricVault.remove(); biometricsOn = false }
    }

    private func enableBiometrics() {
        let password = enrollPassword
        enrollPassword = ""
        Task {
            // Prove the password is right before saving it.
            let ok = await session.verify(password: password)
            biometricsOn = ok && BiometricVault.store(email: session.email, password: password)
        }
    }
}

struct ChangePasswordSheet: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var busy = false
    @State private var error: String?

    private var valid: Bool { new.count >= 8 && new == confirm && !current.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current") { SecureField("Current password", text: $current).textContentType(.password) }
                Section {
                    SecureField("New password (8+ characters)", text: $new).textContentType(.newPassword)
                    SecureField("Repeat new password", text: $confirm).textContentType(.newPassword)
                } header: { Text("New") } footer: {
                    if let error { Text(error).foregroundStyle(Theme.danger) }
                    else if !confirm.isEmpty && new != confirm { Text("The passwords don't match.").foregroundStyle(Theme.danger) }
                    else { Text("Changing your password signs you out everywhere else.") }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Change password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        busy = true
                        Task {
                            let ok = await stores.settings.changePassword(current: current, new: new)
                            busy = false
                            if ok { BiometricVault.remove(); dismiss() } else { error = stores.settings.message; stores.settings.message = nil }
                        }
                    }
                    .disabled(!valid || busy)
                }
            }
        }
    }
}
#endif
