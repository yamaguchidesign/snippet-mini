import Foundation

enum VariableExpander {
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    static func expand(_ text: String, on date: Date = Date()) -> String {
        var result = text.replacingOccurrences(of: "\\n", with: "\n")
        result = result.replacingOccurrences(of: "{{newline}}", with: "\n")
        result = result.replacingOccurrences(of: "{{date}}", with: dateFormatter.string(from: date))
        return result
    }
}
