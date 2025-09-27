import Foundation

public enum Log {
    private static let esc = "\u{001B}["
    private static func color(_ c: String) -> String { esc + c + "m" }
    private static let reset = esc + "0m"
    private static let dim = esc + "2m"
    private static let gray = esc + "90"
    private static let red = esc + "31"
    private static let green = esc + "32"
    private static let yellow = esc + "33"
    private static let cyan = esc + "36"

    private static func ts() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }

    public static func section(_ title: String) {
        let line = String(repeating: "═", count: max(12, title.count + 8))
        print("\n\(color(gray))\(line)\(reset)")
        print("\(color(cyan))◼︎ \(title)\(reset)  \(dim)[\(ts())]\(reset)")
        print("\(color(gray))\(line)\(reset)")
    }

    public static func info(_ msg: String) { print("\(color(cyan))ℹ︎\(reset) \(msg)") }
    public static func success(_ msg: String) { print("\(color(green))✔\(reset) \(msg)") }
    public static func warn(_ msg: String) { print("\(color(yellow))⚠︎\(reset) \(msg)") }
    public static func error(_ msg: String) { print("\(color(red))✖\(reset) \(msg)") }

    public static func json<T: Encodable>(_ value: T, label: String? = nil) {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let label { info(label) }
        if let data = try? enc.encode(value),
            let str = String(data: data, encoding: .utf8)
        {
            print(str)
        } else {
            warn("Could not encode value as JSON. Falling back to description.")
            print(value)
        }
    }

    public static func jsonAny(_ value: Any, label: String? = nil) {
        if let label { info(label) }
        if JSONSerialization.isValidJSONObject(value),
            let data = try? JSONSerialization.data(
                withJSONObject: value, options: [.prettyPrinted]),
            let str = String(data: data, encoding: .utf8)
        {
            print(str)
        } else {
            warn("Value is not a valid JSON object. Printing description.")
            print(value)
        }
    }

    @discardableResult
    public static func measure<T>(_ label: String, _ block: () async throws -> T) async rethrows
        -> (T, TimeInterval)
    {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let ms = (CFAbsoluteTimeGetCurrent() - start) * 1000
        success("\(label) finished in \(String(format: "%.1f", ms)) ms")
        return (result, ms)
    }
}
