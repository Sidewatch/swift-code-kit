//
//  DeclaredTypeNameTests.swift
//  CodeHighlightingTests
//
//  A class-like name wears the type colour where it is declared, inherited or tested, not only as a type annotation.
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
final class DeclaredTypeNameTests: XCTestCase {
    private struct Colours: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            switch kind {
            case .type: return .systemYellow
            case .identifier: return .systemRed
            case .function: return .systemBlue
            case .keyword: return .systemPurple
            default: return .systemGray
            }
        }
    }

    /// The colour on the first character of the `occurrence`-th `marker`, painted by the vendored
    /// `queries/highlights.scm` of `language`'s grammar (read from the source tree: a test process has no
    /// query bundles beside it).
    private func colour(of marker: String, _ occurrence: Int = 1, in text: String, _ language: CodeLanguage.Language) throws -> NSColor? {
        let colours = Colours()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colours
        defer { HighlightTheme.colors = saved }
        let folder = try XCTUnwrap(
            ["php": "tree-sitter-php", "csharp": "tree-sitter-csharp", "java": "tree-sitter-java"][language.rawValue])
        let ts = try XCTUnwrap(TreeSitterHighlighter.tsLanguage(for: language), "no grammar for \(language)")
        let grammars = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Grammars")
        let source = try String(contentsOf: grammars.appendingPathComponent("\(folder)/queries/highlights.scm"), encoding: .utf8)
        let query = try Query(language: ts, data: Data(TreeSitterHighlighter.prunedQuerySource(source).utf8))
        let parser = Parser()
        try parser.setLanguage(ts)
        let tree = try XCTUnwrap(parser.parse(text))
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        let clip = NSRange(location: 0, length: storage.length)
        var base = 0
        let hits = TreeSitterHighlighter.collectHits(query, tree: tree, source: text as NSString, offset: 0, clip: clip, nextBase: &base)
        TreeSitterHighlighter.applyResolved(hits: hits, clip: clip, defaultColor: colours.foreground, into: storage)
        let ns = text as NSString
        var r = NSRange(location: 0, length: 0)
        for _ in 0..<occurrence {
            let from = NSMaxRange(r)
            r = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
            if r.location == NSNotFound { XCTFail("no \(marker) in the snippet"); return nil }
        }
        return storage.attribute(.foregroundColor, at: r.location, effectiveRange: nil) as? NSColor
    }

    /// PHP's upstream query painted a class name only as a type annotation; declared, inherited,
    /// implemented, trait-used and `instanceof` names drew in the plain-name colour.
    func testPHPClassLikeNamesAreTypes() throws {
        let php = """
            <?php
            class Alpha extends Beta implements Gamma, \\Ns\\Delta {
                use Epsilon;
                public function f( Zeta $z ) { return $z instanceof Theta; }
            }
            interface Lambda extends Mu {}
            trait Nu {}
            enum Xi: string {}
            $a = new class extends Pi {};
            """
        for name in ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Theta", "Lambda", "Mu", "Nu", "Xi", "Pi"] {
            XCTAssertEqual(try colour(of: name, in: php, .php), .systemYellow, name)
        }
        XCTAssertEqual(try colour(of: "class", in: php, .php), .systemPurple)
        XCTAssertNotEqual(try colour(of: "Ns", in: php, .php), .systemYellow, "the namespace prefix still recedes")
    }

    /// `exit` / `die` without parentheses are bare names in the PHP grammar; they paint like `exit( 1 )`.
    func testPHPBareExitAndDieAreBuiltinFunctions() throws {
        let php = "<?php\ndefined( 'ABSPATH' ) || exit;\nif ( $x ) { die; }\nexit( 1 );\n"
        XCTAssertEqual(try colour(of: "exit", 1, in: php, .php), .systemBlue)
        XCTAssertEqual(try colour(of: "die", in: php, .php), .systemBlue)
        XCTAssertEqual(try colour(of: "exit", 2, in: php, .php), .systemBlue)
    }

    /// A C# method's return type lives in the `returns` field, which the generic `type:` pattern missed.
    func testCSharpMethodReturnTypeIsAType() throws {
        let cs = "class Shop { Order Find(int id) { return null; } }"
        XCTAssertEqual(try colour(of: "Order", in: cs, .csharp), .systemYellow)
    }

    /// Java records and annotation types are declarations like classes.
    func testJavaRecordAndAnnotationNamesAreTypes() throws {
        let java = "record Point(int x, int y) {}\n@interface Audited {}\n"
        XCTAssertEqual(try colour(of: "Point", in: java, .java), .systemYellow)
        XCTAssertEqual(try colour(of: "Audited", in: java, .java), .systemYellow)
    }

    /// A namespace declaration's whole path recedes, as a qualified name's prefix does (`new Admin\\Fields`);
    /// an all-caps segment is not painted as a constant.
    func testPHPNamespaceDeclarationRecedes() throws {
        let php = "<?php\nnamespace Vendor\\EDD\\Discounts;\nnew Admin\\Fields();\n"
        let muted = try colour(of: "Admin", in: php, .php)
        XCTAssertNotEqual(muted, .systemYellow, "the prefix of a qualified name recedes")
        for segment in ["Vendor", "EDD", "Discounts"] {
            XCTAssertEqual(try colour(of: segment, in: php, .php), muted, segment)
        }
        XCTAssertEqual(try colour(of: "Fields", in: php, .php), .systemYellow, "the class itself keeps the type colour")
    }
}
