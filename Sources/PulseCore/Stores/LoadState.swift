import Foundation

public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(PulseError)

    public var value: Value? { if case .loaded(let v) = self { v } else { nil } }
    public var isLoading: Bool { if case .loading = self { true } else { false } }
    public var error: PulseError? { if case .failed(let e) = self { e } else { nil } }
}

extension Error {
    /// Collapses any thrown error into a `PulseError`.
    public var asPulseError: PulseError {
        if let e = self as? PulseError { return e }
        if self is CancellationError { return .cancelled }
        return .server(status: 0, message: localizedDescription)
    }
}
