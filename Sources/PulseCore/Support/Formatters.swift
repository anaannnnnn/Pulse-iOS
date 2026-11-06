import Foundation

public enum Format {
    /// 3725 -> "1:02:05", 95 -> "1:35"
    public static func clock(_ seconds: Double?) -> String {
        guard let seconds, seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds.rounded(.down))
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    /// 3725 -> "1h 2m", 1500 -> "25 min"
    public static func runtime(_ seconds: Double?) -> String? {
        guard let seconds, seconds > 0 else { return nil }
        let minutes = Int((seconds / 60).rounded())
        if minutes < 60 { return "\(max(minutes, 1)) min" }
        let h = minutes / 60, m = minutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    public static func bytes(_ value: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var size = Double(value)
        var unit = 0
        while size >= 1000, unit < units.count - 1 { size /= 1000; unit += 1 }
        return unit == 0 ? "\(Int(size)) B" : String(format: size >= 100 ? "%.0f %@" : "%.1f %@", size, units[unit])
    }

    public static func speed(_ bytesPerSecond: Double) -> String { bytes(Int64(bytesPerSecond)) + "/s" }

    public static func percent(_ fraction: Double) -> String { "\(Int((fraction * 100).rounded()))%" }

    public static func eta(_ seconds: Double?) -> String? {
        guard let seconds, seconds > 0, seconds.isFinite else { return nil }
        return runtime(seconds) ?? "<1 min"
    }

    public static func count(_ n: Int) -> String {
        n >= 1000 ? String(format: "%.1fk", Double(n) / 1000) : "\(n)"
    }
}
