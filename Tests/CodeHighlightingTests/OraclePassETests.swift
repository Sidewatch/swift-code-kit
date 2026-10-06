//
//  OraclePassETests.swift
//  CodeHighlightingTests
//
//  The regex-tier fixes the oracle pass found for the C-like dialects, the stylesheet supersets, the schema
//  languages and the smaller C-family languages: each snippet is the smallest piece of a showcase that the
//  whole-file comparison against Pygments and Shiki found painted wrong.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

@MainActor
final class OraclePassETests: XCTestCase {
    nonisolated private static let kinds: [TokenKind] = [
        .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property, .identifier,
    ]

    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            let index = OraclePassETests.kinds.firstIndex(of: kind) ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The kind every character of the `occurrence`-th `marker` in `text` is painted; nil when it is
    /// unpainted or mixed.
    private func kind(of marker: String, in text: String, _ language: Language, occurrence: Int = 1) -> TokenKind? {
        let colours = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var range = NSRange(location: NSNotFound, length: 0)
        var from = 0
        for _ in 0..<occurrence {
            range = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
            guard range.location != NSNotFound else { break }
            from = NSMaxRange(range)
        }
        XCTAssertNotEqual(range.location, NSNotFound, "marker \(marker) missing")
        guard range.location != NSNotFound else { return nil }
        let found = Set(
            (range.location..<NSMaxRange(range)).map { storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor })
        guard found.count == 1, let colour = found.first ?? nil, colour != colours.foreground else { return nil }
        return Self.kinds.first { colours.color(for: $0) == colour }
    }

    // MARK: Hack

    func testHackHeredocEndsOnlyAtAClosingLabelAtTheLineStart() {
        let closed = "$a = <<<EOT\nbody text\nEOT;\n$after = 1;\n"
        XCTAssertEqual(kind(of: "body text", in: closed, .hack), .string)
        XCTAssertEqual(kind(of: "$after", in: closed, .hack), .property)
        XCTAssertNotEqual(kind(of: "EOT", in: closed, .hack), .string)
        let indented = "$a = <<<EOT\nbody\n  EOT;\n$after = 1;\n"
        XCTAssertEqual(kind(of: "$after", in: indented, .hack), .string)
    }

    func testHackHashIsNotAComment() {
        XCTAssertNotEqual(kind(of: "note", in: "# note\n$x = 1;\n", .hack), .comment)
    }

    func testHackDeclaredNamesAndNamespacePrefixes() {
        let text = "type StockRow = int;\nfunction first<T>(T $x): T { return \\HH\\Lib\\C\\reduce($x); }\n"
        XCTAssertEqual(kind(of: "StockRow", in: text, .hack), .type)
        XCTAssertEqual(kind(of: "first", in: text, .hack), .function)
        XCTAssertEqual(kind(of: "Lib", in: text, .hack), .type)
        XCTAssertEqual(kind(of: "elseif", in: "} elseif ($x) {}\n", .hack), .function)
    }

    // MARK: SCSS, Sass, Less, PostCSS, Stylus

    func testStylesheetUnitsWearTheTypeColour() {
        let text = "a { width: 10px; margin: 2.5rem; }\n"
        XCTAssertEqual(kind(of: "px", in: text, .scss), .type)
        XCTAssertEqual(kind(of: "10", in: text, .scss), .number)
        XCTAssertEqual(kind(of: "rem", in: text, .less), .type)
        XCTAssertEqual(kind(of: "2n+1", in: "li:nth-child(2n+1) { }\n", .stylus), .number)
    }

    func testSCSSInterpolationHolesStayCode() {
        let text = "$a: \"x#{1 + 2}y\" 'p#{\"q\"}r';\n"
        XCTAssertEqual(kind(of: "1", in: text, .scss), .number)
        XCTAssertEqual(kind(of: "y\"", in: text, .scss), .string)
        XCTAssertEqual(kind(of: "r'", in: text, .scss), .string)
        XCTAssertNotEqual(kind(of: "+", in: text, .scss), .string)
        // A hole after a closed literal starts no string; the quote right after a hole closes its literal.
        XCTAssertEqual(kind(of: "\"z\"", in: "$a: \"x\" #{$y} \"z\";\n", .scss), .string)
        XCTAssertEqual(kind(of: "end", in: "puts \"a #{x}\"\nend\nputs \"b\"\n", .crystal), .keyword)
        XCTAssertEqual(kind(of: "expr", in: "puts \"#{ {{expr}} } = 1\"\n", .crystal), .identifier)
    }

    func testUnquotedURLArgumentIsAStringButNotItsBracket() {
        let text = "a { b: url(images/x.png); }\n"
        XCTAssertEqual(kind(of: "images/x.png", in: text, .less), .string)
        XCTAssertNotEqual(kind(of: "(", in: text, .less), .string)
        XCTAssertEqual(kind(of: "url(images/x.png)", in: "a\n  b: url(images/x.png)\n", .sass), .string)
    }

    func testStylesheetMixinNamesCallsAndMediaWords() {
        XCTAssertEqual(kind(of: "flex", in: "@mixin flex($d) { }\n", .scss), .function)
        XCTAssertEqual(kind(of: "rounded", in: "=rounded($r)\n  border-radius: $r\n", .sass), .function)
        XCTAssertEqual(kind(of: "rgba", in: "a { c: rgba(0, 0, 0, .5); }\n", .scss), .function)
        XCTAssertEqual(kind(of: "screen", in: "@media screen and (min-width: 1px) { }\n", .scss), .keyword)
        XCTAssertEqual(kind(of: "in", in: "for i in (1..3)\n  a b\n", .stylus), .keyword)
    }

    // MARK: C dialects and Objective-C

    func testCDialectDeclaredTypeNames() {
        XCTAssertEqual(kind(of: "VertexIn", in: "struct VertexIn { float4 p; };\n", .metal), .type)
        XCTAssertEqual(kind(of: "T", in: "template <typename T> T twice(T v);\n", .cuda), .type)
        XCTAssertEqual(kind(of: "StockError", in: "errordomain StockError { EMPTY }\n", .vala), .type)
        XCTAssertEqual(kind(of: "new", in: "void *p = ::operator new(n);\n", .objectivecpp, occurrence: 1), .function)
    }

    func testObjectiveCClassNamesAndSelectors() {
        let text = "@interface Order : NSObject\n- (void)setObject:(id)o forKey:(id)k;\n- (void)dealloc;\n@end\n"
        XCTAssertEqual(kind(of: "Order", in: text, .objectivec), .type)
        XCTAssertEqual(kind(of: "setObject:", in: text, .objectivec), .function)
        XCTAssertEqual(kind(of: "forKey:", in: text, .objectivec), .function)
        XCTAssertEqual(kind(of: "dealloc", in: text, .objectivec), .function)
        XCTAssertEqual(kind(of: "if", in: "if (x) { y(); }\n", .objectivecpp), .keyword)
        XCTAssertEqual(kind(of: "nonatomic", in: "@property (nonatomic) int a;\n", .objectivecpp), .keyword)
    }

    // MARK: Crystal

    func testCrystalDeclarationsAndInterpolation() {
        let text = "class Store(T)\n  def total : Int32\n  end\n  def <=>(o)\n  end\nend\nputs \"a #{x} b\"\n"
        XCTAssertEqual(kind(of: "Store(T)", in: text, .crystal), .type)
        XCTAssertEqual(kind(of: "total", in: text, .crystal), .function)
        XCTAssertEqual(kind(of: "<=>", in: text, .crystal), .function)
        XCTAssertEqual(kind(of: "x", in: text, .crystal, occurrence: 1), .identifier)
        XCTAssertEqual(kind(of: " b\"", in: text, .crystal), .string)
        XCTAssertNotEqual(kind(of: "sym", in: "a = %s(sym)\n", .crystal), .string)
        XCTAssertEqual(kind(of: "'\\''", in: "q = '\\''\n", .crystal), .string)
    }

    // MARK: Move, Cap'n Proto, Odin, Cairo

    func testMoveTypesFunctionsAndStorageOperators() {
        let text = "struct Coin has key { v: u64 }\nmacro fun apply(x: u64) { exists<Coin>(a) }\n"
        XCTAssertEqual(kind(of: "Coin", in: text, .move), .type)
        XCTAssertEqual(kind(of: "apply", in: text, .move), .function)
        XCTAssertEqual(kind(of: "exists", in: text, .move), .function)
    }

    func testCapnpTypeNamesAreTypesNotCalls() {
        let text = "struct Pair {\n  value @0 :Wrapper(Text, Point);\n}\n"
        XCTAssertEqual(kind(of: "Wrapper", in: text, .capnp), .type)
        XCTAssertEqual(kind(of: "Point", in: text, .capnp), .type)
    }

    func testOdinDeclaredTypesAndPackage() {
        let text = "package sample\nItem :: struct { qty: int }\nhexf := 0h3FF0\nadd :: proc(a, b: $T) -> T { return a }\n"
        XCTAssertEqual(kind(of: "sample", in: text, .odin), .type)
        XCTAssertEqual(kind(of: "Item", in: text, .odin), .type)
        XCTAssertEqual(kind(of: "0h3FF0", in: text, .odin), .number)
        XCTAssertEqual(kind(of: "add", in: text, .odin), .function)
        XCTAssertEqual(kind(of: "$T", in: text, .odin), .type)
    }

    func testCairoStructsFunctionsAndMacros() {
        let text = "struct Item {\n    qty: u64,\n}\nfn restock(ref self: T) {\n    let (a, b) = t;\n    assert!(a > 0, 'x');\n}\n"
        XCTAssertEqual(kind(of: "Item", in: text, .cairo), .type)
        XCTAssertEqual(kind(of: "restock", in: text, .cairo), .function)
        XCTAssertEqual(kind(of: "let", in: text, .cairo), .keyword)
        XCTAssertEqual(kind(of: "assert!", in: text, .cairo), .function)
    }

    // MARK: Schemas: Protobuf, Thrift

    func testProtobufDeclarationsSingleQuotesAndReservedRanges() {
        let text = "message Order {\n  reserved 10 to 20;\n  optional string s = 1 [default = 'single'];\n}\n"
        XCTAssertEqual(kind(of: "Order", in: text, .protobuf), .type)
        XCTAssertEqual(kind(of: "to", in: text, .protobuf), .keyword)
        XCTAssertEqual(kind(of: "'single'", in: text, .protobuf), .string)
    }

    func testThriftDeclarationsMethodsAndNegativeNumbers() {
        let text = "const i16 SMALL = -7\nservice Orders extends shared.Base {\n  Order getOrder(1: string id),\n}\n"
        XCTAssertEqual(kind(of: "Orders", in: text, .thrift), .type)
        XCTAssertEqual(kind(of: "shared.Base", in: text, .thrift), .type)
        XCTAssertEqual(kind(of: "getOrder", in: text, .thrift), .function)
        XCTAssertEqual(kind(of: "-7", in: text, .thrift), .number)
    }

    // MARK: Carbon, D, Haxe, Zig, GDScript, Solidity, Groovy

    func testSmallerCFamilyFixes() {
        XCTAssertEqual(kind(of: "is", in: "fn F[T:! type where T is Copy](x: T) {}\n", .carbon), .keyword)
        XCTAssertEqual(kind(of: "0x1.8p3", in: "let f: f64 = 0x1.8p3;\n", .carbon), .number)
        XCTAssertEqual(kind(of: "auto", in: "string t = q{auto x = 1;};\n", .d), .keyword)
        XCTAssertEqual(kind(of: "0x1.8p3", in: "const h = 0x1.8p3;\n", .zig), .number)
        XCTAssertEqual(kind(of: "5.", in: "var t := 5.\n", .gdscript), .number)
        XCTAssertEqual(kind(of: "hex", in: "bytes b = hex\"00ff\";\n", .solidity), .keyword)
    }

    func testHaxeFunctionNamesInterpolationAndLeadingDotNumbers() {
        let text = "function get(i:Int) return 'a $x and ${y * 2} b';\nvar l = .5;\n"
        XCTAssertEqual(kind(of: "get", in: text, .haxe), .function)
        XCTAssertEqual(kind(of: "x", in: text, .haxe, occurrence: 1), .identifier)
        XCTAssertEqual(kind(of: "2", in: text, .haxe), .number)
        XCTAssertEqual(kind(of: " b'", in: text, .haxe), .string)
        XCTAssertEqual(kind(of: ".5", in: text, .haxe), .number)
    }

    func testGroovyDollarSlashyAndDeclaredClasses() {
        let text = "def s = $/a/${n}/$$ b/$\nclass Release implements Describable {}\n"
        XCTAssertEqual(kind(of: "$$ b/$", in: text, .gradle), .string)
        XCTAssertEqual(kind(of: "Release", in: text, .groovy), .type)
        XCTAssertEqual(kind(of: "Describable", in: text, .groovy), .type)
    }
}
