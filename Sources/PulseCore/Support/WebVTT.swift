import Foundation

/// Minimal WebVTT / SRT parser for the in-app subtitle overlay.
public enum WebVTT {
    public static func parse(_ text: String) -> [SubtitleCue] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var cues: [SubtitleCue] = []
        for block in normalized.components(separatedBy: "\n\n") {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard let timingIndex = lines.firstIndex(where: { $0.contains("-->") }) else { continue }
            let parts = lines[timingIndex].components(separatedBy: "-->")
            guard parts.count == 2,
                  let start = seconds(parts[0]),
                  let end = seconds(parts[1].split(separator: " ").first.map(String.init) ?? parts[1])
            else { continue }
            let body = lines[(timingIndex + 1)...].joined(separator: "\n")
            let clean = strip(body)
            if !clean.isEmpty { cues.append(SubtitleCue(start: start, end: end, text: clean)) }
        }
        return cues.sorted { $0.start < $1.start }
    }

    /// Cue showing at `time`, or nil. `cues` must be sorted by start.
    public static func cue(at time: Double, in cues: [SubtitleCue]) -> SubtitleCue? {
        var low = 0, high = cues.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let cue = cues[mid]
            if time < cue.start { high = mid - 1 }
            else if time > cue.end { low = mid + 1 }
            else { return cue }
        }
        return nil
    }

    static func seconds(_ raw: String) -> Double? {
        let value = raw.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        let parts = value.split(separator: ":").map(String.init)
        guard (2...3).contains(parts.count) else { return nil }
        var total = 0.0
        for part in parts {
            guard let n = Double(part) else { return nil }
            total = total * 60 + n
        }
        return total
    }

    static func strip(_ text: String) -> String {
        var out = ""
        var inTag = false
        for ch in text {
            if ch == "<" { inTag = true } else if ch == ">" { inTag = false } else if !inTag { out.append(ch) }
        }
        return out
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
