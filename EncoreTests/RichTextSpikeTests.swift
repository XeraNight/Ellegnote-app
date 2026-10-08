import Testing
import SwiftUI
import Foundation

struct RichTextSpikeTests {

    private func sample() -> AttributedString {
        var s = AttributedString("Hlavné slovo a bežný text")
        if let r = s.range(of: "Hlavné") {
            s[r].font = .system(size: 24, weight: .bold)
            s[r].foregroundColor = Color(red: 0.8, green: 0.1, blue: 0.2)
            s[r].underlineStyle = .single
        }
        if let r = s.range(of: "slovo") {
            s[r].backgroundColor = Color.yellow
            s[r].font = .system(size: 18, design: .serif).italic()
        }
        return s
    }

    @Test func roundTripThroughJSONWithSwiftUIScope() throws {
        let original = sample()
        let data = try JSONEncoder().encode(original, configuration: AttributeScopes.SwiftUIAttributes.self)
        let decoded = try JSONDecoder().decode(AttributedString.self, from: data, configuration: AttributeScopes.SwiftUIAttributes.self)
        #expect(String(decoded.characters) == String(original.characters))
        // Which attributes survived?
        var survived: [String] = []
        if let r = decoded.range(of: "Hlavné") {
            if decoded[r].foregroundColor != nil { survived.append("color") }
            if decoded[r].underlineStyle != nil { survived.append("underline") }
            if decoded[r].font != nil { survived.append("font") }
        }
        if let r = decoded.range(of: "slovo"), decoded[r].backgroundColor != nil { survived.append("background") }
        print("RICHSPIKE survived:", survived.joined(separator: ","), "bytes:", data.count)
        #expect(survived.contains("color"))
        #expect(survived.contains("underline"))
        #expect(survived.contains("background"))
        #expect(survived.contains("font"))
        // The restored font must equal the original one, not just exist
        if let r1 = original.range(of: "Hlavné"), let r2 = decoded.range(of: "Hlavné") {
            #expect(original[r1].font == decoded[r2].font)
        }
    }

    @Test func paragraphAlignmentExists() {
        var s = AttributedString("Stred")
        s.alignment = .center
        #expect(s.alignment == .center)
    }
}
