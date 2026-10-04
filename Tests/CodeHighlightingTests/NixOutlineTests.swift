//
//  NixOutlineTests.swift
//  CodeHighlightingTests
//
//  Nix bindings: attribute sets and lets, two levels, strings and comments skipped.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeHighlighting

final class NixOutlineTests: XCTestCase {
    private func tree(_ text: String) -> [String] {
        var out: [String] = []
        func walk(_ nodes: [OutlineNode], _ depth: Int) {
            for n in nodes {
                out.append("\(depth):\(n.symbol.name)")
                walk(n.children, depth + 1)
            }
        }
        walk(OutlineTree.build(from: NixOutline.symbols(in: text)), 0)
        return out
    }

    func testBindingsNestByTheirValueToTwoLevels() {
        let nix = """
            { pkgs ? import <nixpkgs> {} }:
            let
              version = "1.0";
            in {
              packages.default = pkgs.hello;
              shell = { deep = { deeper = 1; }; other = 2; };
              checks = x == y;
            }
            """
        XCTAssertEqual(tree(nix), ["0:version", "0:packages.default", "0:shell", "1:deep", "1:other", "0:checks"])
        let kinds = NixOutline.symbols(in: nix).map(\.kind)
        XCTAssertEqual(kinds.first, .variable, "a let binding is a variable, an attribute a property")
    }

    func testStringsAndCommentsHoldNoBindings() {
        let nix = """
            {
              # commented = 1;
              script = ''
                FOO=bar
                set -e; result = done;
                echo ''${FOO} = done;
              '';
              /* also = 2; */
              after = "a = b;";
            }
            """
        XCTAssertEqual(tree(nix), ["0:script", "0:after"])
    }
}
