//
//  ShellDockerSwiftGrammarTests.swift
//  CodeHighlightingTests
//
//  The local bash, Dockerfile and Swift grammar patches: each construct parses, and colours as it should.
//
//  Created by David Sherlock on 10/3/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import SwiftTreeSitter
import XCTest

@testable import CodeHighlighting

/// Upstream tree-sitter-bash v0.25.1, tree-sitter-dockerfile main and tree-sitter-swift main put ERROR
/// nodes on these (or hid a keyword from the query), and an ERROR early in a file spoils the colours of
/// every line after it. The patches in `Grammars/*/sidewatch-*.patch` fix them; re-vendoring an
/// unpatched upstream fails here.
@MainActor
final class ShellDockerSwiftGrammarTests: XCTestCase {
    /// One distinct colour per role, so the role at a position reads back exactly.
    private struct OneColourPerRole: TokenColorProviding {
        static let kinds: [TokenKind] = [.comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property]
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }
            let index = Self.kinds.firstIndex(of: kind) ?? Self.kinds.count
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The role on the first character of the `occurrence`-th `marker`, painted by the vendored
    /// `queries/highlights.scm` of `language`'s grammar (read from the source tree: a test process has no
    /// query bundles beside it); nil when it stays the default foreground.
    private func role(of marker: String, occurrence: Int = 1, in text: String, _ language: CodeLanguage.Language) -> TokenKind? {
        let colors = OneColourPerRole()
        let saved = HighlightTheme.colors
        HighlightTheme.colors = colors
        defer { HighlightTheme.colors = saved }
        let folder = ["bash": "tree-sitter-bash", "dockerfile": "tree-sitter-dockerfile", "swift": "tree-sitter-swift"][language.rawValue]
        guard let folder, let ts = TreeSitterHighlighter.tsLanguage(for: language) else {
            XCTFail("no grammar for \(language)")
            return nil
        }
        let grammars = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Grammars")
        let source = (try? String(contentsOf: grammars.appendingPathComponent("\(folder)/queries/highlights.scm"), encoding: .utf8)) ?? ""
        guard let query = try? Query(language: ts, data: Data(TreeSitterHighlighter.prunedQuerySource(source).utf8)) else {
            XCTFail("\(folder)'s highlights.scm does not compile against the vendored parser")
            return nil
        }
        let parser = Parser()
        try? parser.setLanguage(ts)
        guard let tree = parser.parse(text) else { return nil }
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colors.foreground])
        let clip = NSRange(location: 0, length: storage.length)
        var base = 0
        let hits = TreeSitterHighlighter.collectHits(query, tree: tree, source: text as NSString, offset: 0, clip: clip, nextBase: &base)
        TreeSitterHighlighter.applyResolved(hits: hits, clip: clip, defaultColor: colors.foreground, into: storage)
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

    private func failingToParse(_ cases: [(String, String)], _ language: CodeLanguage.Language) -> [String] {
        cases.filter { TreeSitterHighlighter.parseErrorCount(in: $0.1, language: language) != 0 }.map(\.0)
    }

    // MARK: Bash

    func testBashConstructsParseWithoutErrors() {
        let cases = [
            ("funsub", "text=${ echo \"no subshell\"; }\n"),
            ("valsub", "count=${| REPLY=42; }\n"),
            ("funsub in a string", "echo \"${ date +%F; }\" \"${| REPLY=$((1 + 1)); }\"\n"),
            ("read-write redirect", "cmd <> rw\nexec 5<>/tmp/rw.txt\n"),
            ("escaped string comparison", "if [ \"$a\" \\< \"b\" ] || [ \"$a\" \\> \"c\" ]; then echo x; fi\n"),
            ("escaped grouping", "[ \\( -f /etc/passwd -o -d /etc \\) -a ! -e /nope ] || :\n"),
        ]
        XCTAssertEqual(failingToParse(cases, .bash), [])
    }

    /// A function substitution's body is commands, not one word: `ls -l` is a command and a flag.
    func testBashFunctionSubstitutionBodyIsCommands() {
        let text = "listing=${ ls -l; }\n"
        XCTAssertEqual(role(of: "ls", in: text, .bash), .function)
        XCTAssertNotEqual(role(of: "-l", in: text, .bash), .function, "the flag is an argument, not part of the command name")
    }

    /// The case the highlighting pass found: an escaped `\<` early in a script made the rest of the file
    /// one ERROR, so a here-document inside `"$( … )"` further down lost its colours.
    func testAHereDocumentAfterAnEscapedComparisonKeepsItsColours() {
        let text = """
            if [ "$today" \\< "2100" ]; then
                echo "string comparisons"
            fi
            echo "$(cat <<IN_SUBST
            inside command substitution
            IN_SUBST
            )"
            for sku in alpha beta gamma; do echo "$sku"; done

            """
        XCTAssertEqual(role(of: "cat", in: text, .bash), .function)
        XCTAssertEqual(role(of: "for", in: text, .bash), .keyword)
        XCTAssertEqual(role(of: "inside command", in: text, .bash), .string)
    }

    // MARK: Dockerfile

    func testDockerfileConstructsParseWithoutErrors() {
        let cases = [
            ("several ARGs", "FROM alpine\nARG TARGETARCH TARGETOS=linux\nARG A=1 B=\"two\" C\n"),
            ("boolean COPY flags", "COPY --link --from=build /a /b\nCOPY --parents ./src/**/*.go /app/\n"),
            ("boolean ADD flag", "ADD --keep-git-dir=true --link https://example.com/repo.git#main /src\n"),
            ("mount option without a value", "RUN --mount=type=bind,source=.,target=/src,rw make\n"),
        ]
        XCTAssertEqual(failingToParse(cases, .dockerfile), [])
    }

    /// The lines after a multi-name `ARG` keep their colours (an ERROR there used to take the file).
    func testLinesAfterSeveralArgumentsKeepTheirColours() {
        let text = """
            FROM alpine:3.19 AS extras
            ARG TARGETARCH TARGETOS=linux
            ARG VERSION=1.0.0 \\
                CHANNEL=stable
            ENV A=1 B="two words"
            LABEL version="${VERSION}"

            """
        XCTAssertEqual(role(of: "ENV", in: text, .dockerfile), .keyword)
        XCTAssertEqual(role(of: "\"two words\"", in: text, .dockerfile), .string)
        XCTAssertEqual(role(of: "LABEL", in: text, .dockerfile), .keyword)
    }

    // MARK: Swift

    /// `throws(E)` hid its keyword from the query; `defer { }` parses as a call and read as a function.
    func testTypedThrowsAndDeferAreKeywords() {
        let text = """
            func load() throws(LoadError) -> Int {
                defer { cleanup() }
                return 1
            }

            """
        XCTAssertEqual(role(of: "throws", in: text, .swift), .keyword)
        XCTAssertEqual(role(of: "LoadError", in: text, .swift), .type)
        XCTAssertEqual(role(of: "defer", in: text, .swift), .keyword)
        XCTAssertEqual(role(of: "cleanup", in: text, .swift), .function)
    }

    /// A function that happens to be called `deferred` stays a function.
    func testOnlyTheDeferKeywordIsRecoloured() {
        XCTAssertEqual(role(of: "deferred", in: "deferred { work() }\n", .swift), .function)
    }
}
