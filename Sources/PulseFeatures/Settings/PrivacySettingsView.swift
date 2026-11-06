#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

struct PrivacySettingsView: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(AppSession.self) private var session
    @State private var biometrics = BiometricVault.hasStoredPIN
    @State private var showChangePin = false
    @State private var enroll = false

    var body: some View {
        @Bindable var store = stores.settings
        SettingsForm(title: "Privacy & security") {
            Section {
                Picker("Auto-lock", selection: $store.settings.autoLockMinutes) {
                    Text("Never").tag(0)
                    ForEach([1, 5, 15, 30, 60], id: \.self) { Text("After \($0) min").tag($0) }
                }
                if BiometricVault.isAvailable && !session.isDemo {
                    Toggle(isOn: Binding(get: { biometrics }, set: { setBiometrics($0) })) {
                        Label("Unlock with \(BiometricVault.name)", systemImage: BiometricVault.symbol)
                    }
                }
                Button("Change passcode", systemImage: "key.fill") { showChangePin = true }
            } header: { Text("Passcode") } footer: {
                Text("The passcode is checked by your server. Six wrong tries lock you out for a minute, then longer.")
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
        .sheet(isPresented: $showChangePin) { ChangePinSheet().presentationDetents([.medium]) }
        .alert("Re-enter your passcode", isPresented: $enroll) {
            SecureField("Passcode", text: $pinForEnroll).keyboardType(.numberPad)
            Button("Enable") { storePinForBiometrics() }
            Button("Cancel", role: .cancel) { biometrics = false }
        } message: { Text("It is stored in the Keychain and released only by \(BiometricVault.name).") }
        .task { await store.load() }
    }

    @State private var pinForEnroll = ""

    private func setBiometrics(_ on: Bool) {
        if on { pinForEnroll = ""; enroll = true } else { BiometricVault.remove(); biometrics = false }
    }

    private func storePinForBiometrics() {
        let pin = pinForEnroll
        Task {
            let ok = await stores.settings.changePin(current: pin, new: pin)
            biometrics = ok && BiometricVault.store(pin: pin)
            pinForEnroll = ""
        }
    }
}

struct ChangePinSheet: View {
    @Environment(StoreBundle.self) private var stores
    @Environment(\.dismiss) private var dismiss
    @State private var current = ""
    @State private var new = ""
    @State private var confirm = ""
    @State private var busy = false
    @State private var error: String?

    private var valid: Bool {
        (4...8).contains(new.count) && new.allSatisfy(\.isNumber) && new == confirm && !current.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current") { SecureField("Current passcode", text: $current).keyboardType(.numberPad).textContentType(.password) }
                Section {
                    SecureField("New passcode (4–8 digits)", text: $new).keyboardType(.numberPad).textContentType(.newPassword)
                    SecureField("Repeat new passcode", text: $confirm).keyboardType(.numberPad).textContentType(.newPassword)
                } header: { Text("New") } footer: {
                    if let error { Text(error).foregroundStyle(Theme.danger) }
                    else if !confirm.isEmpty && new != confirm { Text("The passcodes don't match.").foregroundStyle(Theme.danger) }
                    else { Text("Changing the passcode signs out every other device.") }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Change passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        busy = true
                        Task {
                            let ok = await stores.settings.changePin(current: current, new: new)
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
