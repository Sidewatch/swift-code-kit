//
//  OraclePassA2Tests.swift
//  CodeHighlightingTests
//
//  The tree-sitter queries paint what VS Code and Pygments agree on: declared names, soft keywords,
//  interpolations as code inside strings, and the keywords the upstream queries left plain.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import SwiftTreeSitter
import XCTest

@testable import CodeHighlighting

@MainActor
final class OraclePassA2Tests: XCTestCase {
    /// One colour per role, so a painted colour reads back as exactly one role.
    private struct Colours: TokenColorProviding {
        static let roles: [(TokenKind, String)] = [
            (.comment, "comment"), (.string, "string"), (.keyword, "keyword"), (.type, "type"), (.number, "number"),
            (.function, "function"), (.variable, "variable"), (.identifier, "identifier"), (.property, "property"),
            (.attribute, "attribute"),
        ]
        let foreground = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        func color(for kind: TokenKind) -> NSColor {
            let index = Self.roles.firstIndex { $0.0 == kind } ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
        func role(of colour: NSColor?) -> String {
            guard let c = colour else { return "plain" }
            if c == foreground { return "plain" }
            if c.alphaComponent < 1 { return "muted" }
            return Self.roles.first { color(for: $0.0) == c }?.1 ?? "other"
        }
    }

    /// Each language's vendored query folder, the query files it inherits, and its plain-name nodes,
    /// mirroring `TreeSitterHighlighter.grammarBuilders`.
    private static let grammars: [CodeLanguage.Language: (folder: String, inherits: [String], names: [String])] = [
        .kotlin: ("tree-sitter-kotlin", [], ["simple_identifier"]),
        .swift: ("tree-sitter-swift", [], ["simple_identifier"]),
        .python: ("tree-sitter-python", [], ["identifier"]),
        .ruby: ("tree-sitter-ruby", [], ["identifier"]),
        .scala: ("tree-sitter-scala", [], ["identifier"]),
        .dart: ("tree-sitter-dart", [], ["identifier"]),
        .javascript: ("tree-sitter-javascript", [], ["identifier"]),
        .typescript: ("tree-sitter-typescript", ["tree-sitter-javascript"], ["identifier"]),
        .php: ("tree-sitter-php", [], ["name"]),
        .c: ("tree-sitter-c", [], ["identifier"]),
        .cpp: ("tree-sitter-cpp", ["tree-sitter-c"], ["identifier"]),
        .csharp: ("tree-sitter-csharp", [], ["identifier"]),
        .java: ("tree-sitter-java", [], ["identifier"]),
        .go: ("tree-sitter-go", [], ["identifier"]),
        .lua: ("tree-sitter-lua", [], ["identifier"]),
    ]

    /// `text` painted by the vendored `queries/highlights.scm` (read from the source tree: a test process has
    /// no query bundles beside it), assembled as the highlighter assembles it.
    private struct Painted {
        let storage: NSTextStorage
        let colours: Colours

        /// The role on the first character of the `occurrence`-th `marker`.
        func role(_ marker: String, _ occurrence: Int = 1) -> String {
            let ns = storage.string as NSString
            var r = NSRange(location: 0, length: 0)
            for _ in 0..<occurrence {
                let from = NSMaxRange(r)
                r = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
                if r.location == NSNotFound { return "missing \(marker)" }
            }
            return colours.role(of: storage.attribute(.foregroundColor, at: r.location, effectiveRange: nil) as? NSColor)
        }
    }

    private func paint(_ text: String, _ language: CodeLanguage.Language) throws -> Painted {
        let colours = Colours()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colours
        defer { HighlightTheme.colors = saved }
        let entry = try XCTUnwrap(Self.grammars[language])
        let ts = try XCTUnwrap(TreeSitterHighlighter.tsLanguage(for: language), "no grammar for \(language)")
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Grammars")
        let source = try (entry.inherits + [entry.folder]).map {
            try String(contentsOf: root.appendingPathComponent("\($0)/queries/highlights.scm"), encoding: .utf8)
        }.joined(separator: "\n")
        let lead = entry.names.map { "(\($0)) @identifier.plain" }.joined(separator: "\n")
        let query = try Query(language: ts, data: Data(TreeSitterHighlighter.prunedQuerySource(lead + "\n" + source).utf8))
        let parser = Parser()
        try parser.setLanguage(ts)
        let tree = try XCTUnwrap(parser.parse(text))
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        let clip = NSRange(location: 0, length: storage.length)
        var base = 0
        let hits = TreeSitterHighlighter.collectHits(query, tree: tree, source: text as NSString, offset: 0, clip: clip, nextBase: &base)
        TreeSitterHighlighter.applyResolved(hits: hits, clip: clip, defaultColor: colours.foreground, into: storage)
        return Painted(storage: storage, colours: colours)
    }

    // MARK: - The `@code` capture

    /// A capture strictly containing a `@code` range paints around it, so a lower-ranked hit inside keeps its
    /// colour; a capture of exactly that range still paints.
    func testCodeCaptureLeavesItsSpanToTheTokensInside() {
        let colours = Colours()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colours
        defer { HighlightTheme.colors = saved }
        let storage = NSTextStorage(string: "\"a ${n} b\"", attributes: [.foregroundColor: colours.foreground])
        let string = colours.color(for: .string), number = colours.color(for: .number)
        let hits: [TreeSitterHighlighter.Hit] = [
            (NSRange(location: 5, length: 1), 1, number),
            (NSRange(location: 0, length: 10), 5, string),
            (NSRange(location: 3, length: 4), 6, TreeSitterHighlighter.codeHole),
        ]
        let clip = NSRange(location: 0, length: storage.length)
        TreeSitterHighlighter.applyResolved(hits: hits, clip: clip, defaultColor: colours.foreground, into: storage)
        let painted = Painted(storage: storage, colours: colours)
        XCTAssertEqual(painted.role("\"a"), "string")
        XCTAssertEqual(painted.role("${"), "plain")
        XCTAssertEqual(painted.role("n"), "number")
        XCTAssertEqual(painted.role(" b"), "string")
    }

    // MARK: - Kotlin

    /// A declared function's name is a function behind modifiers, type parameters and a receiver, and when
    /// the name is a soft keyword (`get`, `inner`); soft keywords elsewhere are plain names.
    func testKotlinDeclaredNamesAndSoftKeywords() throws {
        let kt = """
            override fun area(): Double = 1.0
            fun Point.ext() {}
            operator fun get(i: Int) = 1
            fun inner() = 1
            fun <T> nonNull(value: T): T = value
            abstract class Base<T> where T : Any
            class Node(val left: Int)
            """
        let p = try paint(kt, .kotlin)
        XCTAssertEqual(p.role("area"), "function")
        XCTAssertEqual(p.role("ext"), "function")
        XCTAssertEqual(p.role("get"), "function")
        XCTAssertEqual(p.role("inner"), "function")
        XCTAssertEqual(p.role("value"), "variable", "a parameter named `value` is not the `value class` keyword")
        XCTAssertEqual(p.role("where"), "keyword")
        XCTAssertEqual(p.role("left"), "property", "a primary constructor's parameters are not the type colour")
    }

    /// A jump keyword paints alone, not the expression it starts.
    func testKotlinJumpExpressionPaintsOnlyTheKeyword() throws {
        let p = try paint("fun f() { throw IllegalStateException(\"x\") }", .kotlin)
        XCTAssertEqual(p.role("throw"), "keyword")
        XCTAssertEqual(p.role("IllegalStateException"), "function")
    }

    /// `$name` and `${expr}` are code inside the string.
    func testKotlinInterpolationIsCode() throws {
        let p = try paint("val s = \"a $name and ${qty + 1} end\"", .kotlin)
        XCTAssertEqual(p.role("\"a"), "string")
        XCTAssertEqual(p.role("name"), "identifier")
        XCTAssertEqual(p.role("qty"), "identifier")
        XCTAssertEqual(p.role("1"), "number")
        XCTAssertEqual(p.role(" end"), "string")
    }

    // MARK: - Python, Ruby, Scala, Dart

    func testPythonFStringFieldIsCode() throws {
        let p = try paint("s = f\"total {qty * 2} left\"\n", .python)
        XCTAssertEqual(p.role("qty"), "identifier")
        XCTAssertEqual(p.role("2"), "number")
        XCTAssertEqual(p.role("left"), "string")
    }

    /// Locals are plain names (no locals pass backs upstream's `#is-not? local`), symbols are constants,
    /// operator methods are functions, and Kernel methods called bare are keywords.
    func testRubyNamesSymbolsAndSpecialMethods() throws {
        let rb = """
            class Widget
              include Comparable
              attr_reader :name
              def <=>(other) = price <=> other.price
              def name=(value); end
              def total(count)
                label = "n: #{count + 1}"
                words = %W[alpha #{count}]
                raise Error, label
              rescue Error
                raise
              end
            end
            """
        let p = try paint(rb, .ruby)
        XCTAssertEqual(p.role("include"), "keyword")
        XCTAssertEqual(p.role("attr_reader"), "keyword")
        XCTAssertEqual(p.role("raise"), "keyword")
        XCTAssertEqual(p.role("raise\n"), "keyword", "a bare re-raise is an identifier to the grammar")
        XCTAssertEqual(p.role(":name"), "number", "a symbol wears the constant colour")
        XCTAssertEqual(p.role("<=>"), "function")
        XCTAssertEqual(p.role("name="), "function")
        XCTAssertEqual(p.role("=(value"), "function", "the `=` of a setter's name")
        XCTAssertEqual(p.role("label"), "identifier")
        XCTAssertEqual(p.role("count", 2), "identifier", "inside `#{…}`")
        XCTAssertEqual(p.role("1"), "number")
        XCTAssertEqual(p.role("count", 3), "identifier", "a `%W` word that is only `#{…}`")
        XCTAssertEqual(p.role("alpha"), "string")
    }

    func testScalaDirectivesDefinitionsAndInterpolation() throws {
        let scala = """
            //> using scala 3.7
            import scala.math.Ordering.Implicits.given
            class A:
              def this() = this(0)
              def ++(a: Int): Int = a
              @throws[Exception] def f(): Unit = ()
              val s = s"item $n and ${n + 1}"
            """
        let p = try paint(scala, .scala)
        XCTAssertEqual(p.role("scala 3"), "comment")
        XCTAssertEqual(p.role("3.7"), "comment")
        XCTAssertEqual(p.role("given"), "keyword")
        XCTAssertEqual(p.role("this"), "function")
        XCTAssertEqual(p.role("++"), "function")
        XCTAssertEqual(p.role("Exception"), "type")
        XCTAssertEqual(p.role("n and"), "identifier")
        XCTAssertEqual(p.role("1"), "number")
    }

    func testDartTearOffAndInterpolation() throws {
        let p = try paint("void f() { var c = Item.new; print('a $x ${y + 1} z'); }", .dart)
        XCTAssertEqual(p.role("new"), "keyword")
        XCTAssertEqual(p.role("x "), "identifier")
        XCTAssertEqual(p.role("y"), "identifier")
        XCTAssertEqual(p.role("1"), "number")
        XCTAssertEqual(p.role(" z"), "string")
    }

    // MARK: - Swift

    func testSwiftModulesInitAndStatementKeywords() throws {
        let swift = """
            import struct Foundation.URL
            precedencegroup Joining {
                associativity: left
            }
            class A {
                unowned(unsafe) var owner: A
                convenience init() { self.init(x: 1) }
                func f(_ x: Int) {
                    switch x { case 1: fallthrough
                    default: break }
                }
            }
            let m: (Int).Type = Int.self
            @objc class B {}
            #if swift(>=5.9) && compiler(>=6.0)
            #endif
            """
        let p = try paint(swift, .swift)
        XCTAssertEqual(p.role("Foundation"), "type")
        XCTAssertEqual(p.role("URL"), "type")
        XCTAssertEqual(p.role("associativity"), "keyword")
        XCTAssertEqual(p.role("left"), "keyword")
        XCTAssertEqual(p.role("unowned"), "keyword")
        XCTAssertEqual(p.role("init"), "keyword")
        XCTAssertEqual(p.role("init", 2), "keyword")
        XCTAssertEqual(p.role("fallthrough"), "keyword")
        XCTAssertEqual(p.role("Type"), "keyword")
        XCTAssertEqual(p.role("@objc"), "attribute", "an attribute wears the attribute colour (the type colour in the app)")
        XCTAssertEqual(p.role(".9"), "number")
        XCTAssertEqual(p.role(".0"), "number")
    }

    // MARK: - JavaScript, TypeScript

    func testJavaScriptConstructorExportDefaultAndTemplates() throws {
        let js = "class C { constructor() {} }\nconst s = `a ${n + 1} b`;\n"
        let p = try paint(js, .javascript)
        XCTAssertEqual(p.role("constructor"), "keyword")
        XCTAssertEqual(p.role("n +"), "identifier")
        XCTAssertEqual(p.role("1"), "number")
        XCTAssertEqual(p.role(" b"), "string")
        let ts = try paint("type S = `get${Capitalize<K>}`;\nexport type { A as default };\n", .typescript)
        XCTAssertEqual(ts.role("`get"), "string")
        XCTAssertEqual(ts.role("Capitalize"), "type")
        XCTAssertEqual(ts.role("default"), "keyword")
    }

    // MARK: - PHP

    func testPHPScopesShellCommandsAndInterpolation() throws {
        let php = """
            <?php
            class A { var $v = 1; function f() { parent::f(); static::$x++; } }
            $b = `echo shell`;
            $s = "prop $obj->prop, tab\\t";
            """
        let p = try paint(php, .php)
        XCTAssertEqual(p.role("var"), "keyword")
        XCTAssertEqual(p.role("parent"), "keyword")
        XCTAssertEqual(p.role("static"), "keyword")
        XCTAssertEqual(p.role("`echo"), "string")
        XCTAssertEqual(p.role("->"), "plain")
        XCTAssertEqual(p.role("\\t"), "string")
    }

    // MARK: - C, C++

    func testCKeywordsTypesAndDisabledBlocks() throws {
        let c = """
            unsigned _BitInt(8) u;
            int __based(seg) *p;
            void __cdecl g(void);
            void f(void) { asm volatile("nop"); x = va_arg(a, int); }
            #if 0
            # error "off"
            #else
            int on;
            #endif
            """
        let p = try paint(c, .c)
        XCTAssertEqual(p.role("8"), "number")
        XCTAssertEqual(p.role("__based"), "keyword")
        XCTAssertEqual(p.role("__cdecl"), "keyword")
        XCTAssertEqual(p.role("asm"), "keyword")
        XCTAssertEqual(p.role("int)"), "type")
        XCTAssertEqual(p.role("# error"), "comment")
        XCTAssertEqual(p.role("#if"), "keyword")
        XCTAssertEqual(p.role("#endif"), "keyword")
        XCTAssertEqual(p.role("int on"), "type", "an `#else` branch is live code")
        let cpp = try paint("int f(int n) { using enum Color; return auto(n) + 1; }", .cpp)
        XCTAssertEqual(cpp.role("Color"), "type")
        XCTAssertEqual(cpp.role("auto"), "keyword")
    }

    // MARK: - C#, Java, Go, Lua

    func testCSharpConstructorAndOperatorNames() throws {
        let cs = "class Bin { public Bin() { } public static bool operator true(Bin a) => true; }"
        let p = try paint(cs, .csharp)
        XCTAssertEqual(p.role("Bin()"), "function")
        XCTAssertEqual(p.role("true("), "function")
    }

    func testJavaDeclarationsLiteralsAndPatterns() throws {
        let java = """
            class Box<T extends Comparable<? super T>> {
                int b = 0b1010_0101;
                Box(T value) {}
                void f(Object o) { switch (o) { case null, default -> {} } if (o instanceof Item(String s)) {} }
            }
            @interface Audited { String value() default "none"; }
            """
        let p = try paint(java, .java)
        XCTAssertEqual(p.role("super"), "keyword")
        XCTAssertEqual(p.role("0b1010"), "number")
        XCTAssertEqual(p.role("Box(T"), "function")
        XCTAssertEqual(p.role("default ->"), "keyword")
        XCTAssertEqual(p.role("Item"), "type")
        XCTAssertEqual(p.role("value()"), "function")
    }

    func testGoConversionsAndLuaMethodTables() throws {
        let go = try paint("package main\nvar f = float64(n)\nvar m = MaxOf[int]\n", .go)
        XCTAssertEqual(go.role("float64"), "type")
        XCTAssertEqual(go.role("int]"), "type")
        let lua = try paint("function Vector2:magnitude() end\nfunction obj.a.b:other() end\n", .lua)
        XCTAssertEqual(lua.role("Vector2"), "type")
        XCTAssertEqual(lua.role("b:"), "type")
    }
}
