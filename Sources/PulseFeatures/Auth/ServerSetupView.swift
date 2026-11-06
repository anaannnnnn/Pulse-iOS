#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// First launch: point the app at your Pulse server, or try the demo library.
struct ServerSetupView: View {
    @Environment(AppSession.self) private var session
    @State private var address = ""
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 40)
                PulseMark(size: 44)
                VStack(spacing: 10) {
                    Text("Connect to your server").font(PulseFont.display(22, relativeTo: .title2)).foregroundStyle(Theme.text).multilineTextAlignment(.center)
                    Text("Enter the address of the machine running Pulse. On your home Wi-Fi that looks like 192.168.1.20:8787, or use your Tailscale or tunnel address.")
                        .font(.subheadline).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
                }
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "server.rack").foregroundStyle(Theme.accentSoft)
                        TextField("pulse.example.com or 192.168.1.20:8787", text: $address)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .submitLabel(.go)
                            .focused($focused)
                            .onSubmit { Task { await session.connect(to: address) } }
                    }
                    .padding(.horizontal, 16).frame(minHeight: 54)
                    .pulseGlass(in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))

                    if let message = session.pinError {
                        Label(message, systemImage: "exclamationmark.triangle.fill").font(.footnote).foregroundStyle(Theme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task { await session.connect(to: address) }
                    } label: {
                        if session.phase == .connecting { ProgressView().tint(.white).frame(maxWidth: .infinity) }
                        else { Text("Connect").frame(maxWidth: .infinity) }
                    }
                    .buttonStyle(.pulsePrimary)
                    .disabled(address.trimmingCharacters(in: .whitespaces).isEmpty || session.phase == .connecting)
                }
                Button("Explore the demo library") { session.enterDemo() }
                    .buttonStyle(.pulseGlass)
                Text("Pulse never sends anything to us. Your passcode and library stay between this phone and your server.")
                    .font(.caption).foregroundStyle(Theme.textTertiary).multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background { AuroraBackground() }
        .onAppear { address = session.serverURL?.absoluteString ?? address }
    }
}
#endif
