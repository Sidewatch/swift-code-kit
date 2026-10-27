//
//  RuleScopeTests.swift
//  CodeHighlightingTests
//
//  A scope's scan reads `^` and `$` as a line's, like every rule: a line comment it steps over is stepped over
//  wherever it stands, so a quote inside one cannot put the strings after it out of step.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class RuleScopeTests: XCTestCase {
    func testAnApostropheInAHaxeLineCommentLeavesTheStringsAfterItAlone() {
        let painted = PaintedKinds("// it's a comment\nvar s = 'a ${b} c';\nvar t = 'plain';\n", .haxe)
        XCTAssertEqual(painted.kind(" c'"), .string, "the text after a hole")
        XCTAssertEqual(painted.kind("plain"), .string)
        XCTAssertNotEqual(painted.kind("';\nvar t", 1), .string, "the code between two strings")
    }

    func testAQuoteInANixCommentLeavesTheStringsAfterItAlone() {
        let painted = PaintedKinds("{\n  # say \"hi\n  a = \"x ${b} c\";\n  t = \"plain\";\n}\n", .nix)
        XCTAssertEqual(painted.kind(" c\""), .string, "the text after a hole")
        XCTAssertEqual(painted.kind("plain"), .string)
        XCTAssertNotEqual(painted.kind("\";\n  t", 1), .string, "the code between two strings")
    }
}
