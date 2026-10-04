//
//  MarkupOutlineTests.swift
//  CodeHighlightingTests
//
//  Pages and templates: headings by level, ids, landmarks, containers at the top, template code.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

final class MarkupOutlineTests: XCTestCase {
    /// The outline as "depth:name", the whole tree.
    private func tree(_ text: String, _ language: Language) -> [String] {
        var out: [String] = []
        func walk(_ nodes: [OutlineNode], _ depth: Int) {
            for n in nodes {
                out.append("\(depth):\(n.symbol.name)")
                walk(n.children, depth + 1)
            }
        }
        walk(OutlineTree.build(from: MarkupOutline.symbols(in: text, language: language)), 0)
        return out
    }

    func testHeadingsNestByLevelWithinTheirElement() {
        let page = """
            <main id="app"><h1>Orders <small>today</small></h1>
            <section><h2>Open &amp; late</h2><p>x</p></section>
            <h2>Closed</h2></main>
            <footer><h2>About</h2></footer>
            """
        XCTAssertEqual(
            tree(page, .html), ["0:#app", "1:Orders today", "2:Open & late", "2:Closed", "0:footer", "1:About"],
            "an h2 inside a section stays under the h1; the footer's h2 is not under main's h1")
    }

    func testIdsLandmarksAndCommentsAndComputedIds() {
        let page = """
            <!-- <div id="commented"></div> -->
            <nav aria-label="Primary"><a id="home">Home</a></nav>
            <div :id="dyn" data-id="x" id="{computed}"></div><br id="gap">
            """
        XCTAssertEqual(tree(page, .html), ["0:nav (Primary)", "1:#home", "0:#gap"])
    }

    func testAContainerIsNotTheChildOfTheHeadingBeforeIt() {
        let razor = """
            <h1>Counter</h1>
            <p>@count</p>
            @code {
                private int count;
                void Increment() { count++; }
            }
            """
        let outline = tree(razor, .razor)
        XCTAssertEqual(outline.first, "0:Counter")
        XCTAssertTrue(outline.contains("0:@code") && outline.contains("1:Increment"), "\(outline)")
    }

    func testTemplateCodeFragmentsListTheirDefinitions() {
        XCTAssertEqual(tree("<% def total(items) %><%= items.sum %><% end %>\n<h1><%= @title %></h1>", .erb), ["0:total", "0:@title"])
        XCTAssertEqual(tree("<% function row(o) { %><tr></tr><% } %>", .ejs), ["0:row"])
        XCTAssertEqual(
            tree("<% const note = \"function fake() {\"; function real() {} %>", .ejs), ["0:real"], "words in a string are no definition")
        XCTAssertEqual(
            tree("<%! int hits; String say() { return \"class x\"; } %>\n<h1>T</h1>\n<%! void later() {} %>", .jsp),
            ["0:say", "0:T", "0:later"], "a declaration's methods (parsed as Java), at the top level, a string's words ignored")
    }

    func testComponentsAreListedOnceAndScriptsUnderTheirTag() {
        let vue = """
            <script setup>
            function save() {}
            </script>
            <template><div><Card/><Card/><order-row></order-row></div></template>
            """
        XCTAssertEqual(tree(vue, .vue), ["0:script setup", "1:save", "0:template", "1:Card", "1:order-row"])
    }
}
