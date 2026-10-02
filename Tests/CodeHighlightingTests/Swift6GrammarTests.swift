//
//  Swift6GrammarTests.swift
//  CodeHighlightingTests
//
//  The vendored Swift grammar parses Swift 6.x syntax.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

/// Upstream tree-sitter-swift (main, Sep 2026) produced ERROR nodes on each of these, and a parse error
/// spoils the colours around it. The local patch (`Grammars/tree-sitter-swift/sidewatch-swift-6.patch`)
/// fixes them; this pins it, so re-vendoring an unpatched upstream fails here.
final class Swift6GrammarTests: XCTestCase {
    static let swift6: [(String, String)] = [
        ("sending parameter", "func f(_ x: sending Item) {}"),
        ("sending result", "func f() -> sending Item { Item() }"),
        ("isolated parameter", "func f(actor: isolated Ledger) {}"),
        ("#isolation default", "func f(isolation: isolated (any Actor)? = #isolation) async {}"),
        ("isolated deinit", "actor A { isolated deinit { print(\"x\") } }"),
        ("copy expression", "let y = copy x"),
        ("value generics", "struct Matrix<let rows: Int, let cols: Int> {}"),
        ("inline array sugar", "let a: [3 of Int] = [1, 2, 3]"),
        ("integer type argument", "var b = InlineArray<4, Int>(repeating: 0)"),
        ("@backDeployed", "@backDeployed(before: macOS 14) public func f() {}"),
        ("optional bracket-qualified type", "let i: [Int].Index? = nil"),
        ("multiline regex with an indented close", "let r = #/\n    (?<sku> [A-Z]+ )  # letters\n    /#\n"),
    ]

    func testSwift6SyntaxParsesWithoutErrors() {
        var failing: [String] = []
        for (name, code) in Self.swift6 where TreeSitterHighlighter.parseErrorCount(in: code, language: .swift) != 0 {
            failing.append(name)
        }
        XCTAssertEqual(failing, [])
    }

    /// The new contextual keywords must still work as plain names.
    func testTheNewKeywordsAreStillIdentifiers() {
        let code = "let sending = 1\nlet isolated = 2\nlet copy = 3\nlet of = 4\nprint(sending + isolated + copy + of)\n"
        XCTAssertEqual(TreeSitterHighlighter.parseErrorCount(in: code, language: .swift), 0)
    }
}
