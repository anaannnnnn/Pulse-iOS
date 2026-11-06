import Foundation

public enum PulseError: Error, Equatable, Sendable, LocalizedError {
    case locked
    case badPin
    case rateLimited(retryAfter: TimeInterval?)
    case notFound
    case badRequest(String)
    case pcloudNotConnected
    case torboxNotLinked
    case upstream(String)
    case server(status: Int, message: String)
    case invalidServerURL
    case offline
    case decoding(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .locked: "Pulse is locked. Enter your passcode."
        case .badPin: "That passcode is wrong."
        case .rateLimited(let wait):
            if let wait { "Too many tries. Try again in \(Int(wait.rounded(.up))) seconds." }
            else { "Too many tries. Try again later." }
        case .notFound: "That item no longer exists."
        case .badRequest(let m): m
        case .pcloudNotConnected: "pCloud is not connected yet."
        case .torboxNotLinked: "TorBox is not linked yet."
        case .upstream(let m): "A metadata service failed: \(m)"
        case .server(_, let m): m
        case .invalidServerURL: "That server address is not valid."
        case .offline: "Can't reach your Pulse server."
        case .decoding(let m): "Unexpected reply from the server (\(m))."
        case .cancelled: "Cancelled."
        }
    }

    public var isLocked: Bool { self == .locked }
}

struct ServerErrorEnvelope: Decodable {
    struct Body: Decodable { let code: String?; let message: String? }
    let error: Body?
}
