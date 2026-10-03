//
//  ExecutableMarkdownTests.swift
//  CodeHighlightingTests
//
//  Quarto and R Markdown: each chunk's code in its own language.
//
//  Created by David Sherlock on 10/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

/// Chunks (```` ```{r} ````, ```` ```{python echo=FALSE} ````) used to be painted as one string; they are
/// regions of ``EmbeddedMarkupHighlighter`` now, painted in the chunk's language, with the fence lines
/// as keywords, `#|` option names as attributes and the front matter as YAML.
@MainActor
final class ExecutableMarkdownTests: XCTestCase {
    private typealias H = EmbeddedMarkupHighlighter

    private struct OneColourPerRole: TokenColorProviding {
        static let kinds: [TokenKind] = [.comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property]
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }
            let index = Self.kinds.firstIndex(of: kind) ?? Self.kinds.count
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    private func role(of marker: String, occurrence: Int = 1, in text: String, _ language: Language) -> TokenKind? {
        let colors = OneColourPerRole()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colors
        defer { HighlightTheme.colors = saved }
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colors.foreground])
        guard let highlighter = H(language: language, colors: colors) else {
            XCTFail("\(language) is not painted by the embedded tier")
            return nil
        }
        highlighter.highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var at = NSRange(location: 0, length: 0)
        for _ in 0..<occurrence {
            at = ns.range(of: marker, range: NSRange(location: NSMaxRange(at), length: ns.length - NSMaxRange(at)))
            XCTAssertNotEqual(at.location, NSNotFound, "no \(marker) in the snippet")
            if at.location == NSNotFound { return nil }
        }
        let colour = storage.attribute(.foregroundColor, at: at.location, effectiveRange: nil) as? NSColor
        return OneColourPerRole.kinds.first { colors.color(for: $0) == colour }
    }

    static let quarto = """
        ---
        title: "Weekly stock"
        format: html
        ---

        Some *emphasis* before the chunk.

        ```{r}
        #| label: load
        #| echo: false
        orders <- read.csv("orders.csv")  # the export
        total <- 42
        ```

        Prose between chunks stays prose.

        ```{python echo=FALSE}
        def ship(order):
            return "shipped"
        ```

        ```{julia}
        function stock(n)
            n * 2
        end
        ```

        ```
        A fenced block without a language.
        ```

        ```{theorem}
        A theorem written as a chunk engine.
        ```

        ````{.markdown}
        ```{r}
        shown <- "not run"
        ```
        ````

        Closing prose with *emphasis*.

        """

    func testBothFormatsUseTheEmbeddedTier() {
        XCTAssertTrue(H.supports(.quarto))
        XCTAssertTrue(H.supports(.rmarkdown))
        XCTAssertFalse(H.supports(.markdown))
    }

    func testChunkCodeIsPaintedInTheChunksLanguage() {
        for language in [Language.quarto, .rmarkdown] {
            XCTAssertEqual(role(of: "\"orders.csv\"", in: Self.quarto, language), .string, "\(language)")
            XCTAssertEqual(role(of: "# the export", in: Self.quarto, language), .comment, "\(language)")
            XCTAssertEqual(role(of: "42", in: Self.quarto, language), .number, "\(language)")
            XCTAssertEqual(role(of: "function stock", in: Self.quarto, language), .keyword, "\(language)")
            XCTAssertEqual(role(of: "end\n", in: Self.quarto, language), .keyword, "\(language)")
            XCTAssertNil(role(of: "orders <-", in: Self.quarto, language), "a name in R code is plain, not text")
        }
    }

    func testChunkEdgesFrontMatterAndProse() {
        let text = Self.quarto
        XCTAssertEqual(role(of: "```{r}", in: text, .quarto), .keyword)
        XCTAssertEqual(role(of: "```", occurrence: 2, in: text, .quarto), .keyword, "the chunk's closing fence")
        XCTAssertEqual(role(of: "#| label", in: text, .quarto), .attribute)
        XCTAssertEqual(role(of: "*emphasis* before", in: text, .quarto), .type)
        XCTAssertNil(role(of: "Prose between", in: text, .quarto), "prose between chunks stays plain")
        XCTAssertEqual(role(of: "*emphasis*.", in: text, .quarto), .type, "the last paragraph is still Markdown")
    }

    /// Chunks with a bundled grammar (Python) and the front matter (YAML) are tree-sitter regions; a test
    /// process has no query bundles to colour them with, so the split itself is what is checked.
    func testRegionsAreTheFrontMatterAndEachChunksCode() {
        let ns = Self.quarto as NSString
        let regions = H.regions(in: ns, language: .quarto).map { (ns.substring(with: $0.range), $0.language) }
        XCTAssertEqual(regions.map(\.1), [.yaml, .r, .python, .julia])
        XCTAssertEqual(regions.first?.0, "title: \"Weekly stock\"\nformat: html\n")
        XCTAssertTrue(regions[1].0.hasPrefix("orders <- read.csv"), "the option lines are not R code: \(regions[1].0)")
        XCTAssertTrue(regions[2].0.hasPrefix("def ship(order):"))
    }

    func testBlocksWithoutAKnownLanguageAreText() {
        let text = Self.quarto
        XCTAssertEqual(role(of: "A fenced block without", in: text, .quarto), .string)
        XCTAssertEqual(role(of: "A theorem written", in: text, .quarto), .string)
        XCTAssertEqual(role(of: "shown <-", in: text, .quarto), .string, "a chunk inside a longer fence is shown, not run")
    }

    func testEngineNames() {
        XCTAssertEqual(H.chunkLanguage("r"), .r)
        XCTAssertEqual(H.chunkLanguage("Rcpp"), .cpp)
        XCTAssertEqual(H.chunkLanguage("ojs"), .javascript)
        XCTAssertEqual(H.chunkLanguage("julia"), .julia)
        XCTAssertEqual(H.chunkLanguage("sql"), .sql)
        XCTAssertNil(H.chunkLanguage("theorem"))
        XCTAssertNil(H.chunkLanguage("markdown"))
        XCTAssertNil(H.chunkLanguage(""))
    }

    func testChunkScanFindsOptionsAndFences() {
        let chunks = H.chunks(in: Self.quarto as NSString)
        XCTAssertEqual(chunks.count, 6, "r, python, julia, plain, theorem, and the four-backtick block (its inner fence is text)")
        XCTAssertEqual(chunks.first?.language, .r)
        XCTAssertEqual(chunks.first?.options.count, 2)
        XCTAssertEqual(chunks.first?.fences.count, 2)
    }
}
