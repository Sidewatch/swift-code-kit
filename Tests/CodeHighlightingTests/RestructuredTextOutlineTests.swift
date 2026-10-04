//
//  RestructuredTextOutlineTests.swift
//  CodeHighlightingTests
//
//  reST section titles: levels by first appearance, overline distinct from underline alone.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeHighlighting

final class RestructuredTextOutlineTests: XCTestCase {
    private func tree(_ text: String) -> [String] {
        var out: [String] = []
        func walk(_ nodes: [OutlineNode], _ depth: Int) {
            for n in nodes {
                out.append("\(depth):\(n.symbol.name)")
                walk(n.children, depth + 1)
            }
        }
        walk(OutlineTree.build(from: RestructuredTextOutline.symbols(in: text)), 0)
        return out
    }

    func testLevelsFollowTheOrderStylesFirstAppear() {
        let rst = """
            =====
            Guide
            =====

            Setup
            =====

            Install
            -------

            text

            ----

            Usage
            =====
            """
        XCTAssertEqual(
            tree(rst), ["0:Guide", "1:Setup", "2:Install", "1:Usage"],
            "an overlined = is its own style above an underlined =; a transition is no title")
    }

    func testIndentedLinesAndShortRunsAreNoTitles() {
        XCTAssertEqual(tree("Para\n--\n\n    code\n    ====\n"), [])
    }
}
