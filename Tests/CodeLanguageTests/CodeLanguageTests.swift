//
//  CodeLanguageTests.swift
//  CodeLanguageTests
//
//  Tests for `Language` detection by extension and filename over the common cases.
//
//  Created by David Sherlock on 7/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
@testable import CodeLanguage

/// Tests for `Language` detection by extension and filename over the common cases.
final class CodeLanguageTests: XCTestCase {

    // MARK: - Detection by extension

    func testDetectsCommonExtensions() {
        let cases: [(String, Language)] = [
            ("main.swift", .swift), ("app.py", .python), ("index.js", .javascript),
            ("main.ts", .typescript), ("lib.rs", .rust), ("main.go", .go),
            ("model.rb", .ruby), ("App.java", .java), ("engine.cpp", .cpp),
            ("page.html", .html), ("style.css", .css), ("data.json", .json),
            ("config.yaml", .yaml), ("Cargo.toml", .toml), ("README.md", .markdown),
        ]
        for (name, expected) in cases {
            XCTAssertEqual(Language.detect(filename: name), expected, "for \(name)")
        }
    }

    // MARK: - Ambiguous-extension conflict resolution

    func testResolvesAmbiguousExtensions() {
        XCTAssertEqual(Language.detect(filename: "vec.h"), .c)  // C wins over Objective-C
        XCTAssertEqual(Language.detect(filename: "View.m"), .objectivec)  // .m → Objective-C, not MATLAB
        XCTAssertEqual(Language.detect(filename: "cpu.v"), .verilog)  // .v → Verilog
        XCTAssertEqual(Language.detect(filename: "deploy.sh"), .bash)  // .sh → Bash
    }

    // MARK: - Detection by filename & special rules

    func testDetectsSpecialFilenames() {
        XCTAssertEqual(Language.detect(filename: ".htaccess"), .apacheconf)
        XCTAssertEqual(Language.detect(filename: "Dockerfile"), .dockerfile)
        XCTAssertEqual(Language.detect(filename: "Dockerfile.prod"), .dockerfile)  // prefix rule
        XCTAssertEqual(Language.detect(filename: ".env"), .dotenv)
        XCTAssertEqual(Language.detect(filename: ".env.local"), .dotenv)  // prefix rule
    }

    func testDetectsMarkdownVariants() {
        for name in [
            "README.md", "notes.markdown", "a.mdown", "b.mdwn", "c.mkd", "d.mkdn",
            "on-writing-less.mdoc",
        ] {  // Markdoc → Markdown
            XCTAssertEqual(Language.detect(filename: name), .markdown, "for \(name)")
        }
        XCTAssertEqual(Language.detect(filename: "page.mdx"), .mdx)  // MDX stays its own language
    }

    func testDetectsExtensionlessJSONLockAndConfigFiles() {
        // These are JSON by content but carry no `.json` extension, so they'd fall to
        // plain text without an exact-filename rule.
        XCTAssertEqual(Language.detect(filename: "Package.resolved"), .json)  // SwiftPM lock
        XCTAssertEqual(Language.detect(filename: "Pipfile.lock"), .json)  // Python
        XCTAssertEqual(Language.detect(filename: "flake.lock"), .json)  // Nix
        XCTAssertEqual(Language.detect(filename: "deno.lock"), .json)  // Deno
        XCTAssertEqual(Language.detect(filename: "bun.lock"), .jsonc)  // Bun (JSONC)
        XCTAssertEqual(Language.detect(filename: ".swcrc"), .json)
        XCTAssertEqual(Language.detect(filename: ".stylelintrc"), .json)
        XCTAssertEqual(Language.detect(filename: ".arcconfig"), .json)
    }

    func testEnvrcIsBashNotDotenv() {
        XCTAssertEqual(Language.detect(filename: ".envrc"), .bash)  // direnv bash script
        XCTAssertEqual(Language.detect(filename: ".env"), .dotenv)  // exact name still dotenv
        XCTAssertEqual(Language.detect(filename: ".env.staging"), .dotenv)  // .env.* prefix still dotenv
    }

    func testDetectionIsCaseInsensitive() {
        XCTAssertEqual(Language.detect(filename: "MAIN.SWIFT"), .swift)
        XCTAssertEqual(Language.detect(filename: "DOCKERFILE"), .dockerfile)
    }

    func testUnknownAndExtensionlessFallBackToPlainText() {
        XCTAssertEqual(Language.detect(filename: "mystery.zzq"), .plainText)
        XCTAssertEqual(Language.detect(filename: "LICENSE"), .plainText)
        XCTAssertEqual(Language.detect(filename: "trailing."), .plainText)  // empty extension
    }

    func testDetectForURL() {
        let url = URL(fileURLWithPath: "/tmp/project/Sources/main.swift")
        XCTAssertEqual(Language.detect(for: url), .swift)
    }

    // MARK: - Metadata

    func testDisplayNames() {
        XCTAssertEqual(Language.cpp.displayName, "C++")
        XCTAssertEqual(Language.swift.displayName, "Swift")
        XCTAssertEqual(Language.plainText.displayName, "Plain Text")
    }

    func testLineCommentTokens() {
        XCTAssertEqual(Language.swift.lineCommentToken, "//")
        XCTAssertEqual(Language.ruby.lineCommentToken, "#")
        XCTAssertEqual(Language.haskell.lineCommentToken, "--")
        XCTAssertNil(Language.html.lineCommentToken)
        XCTAssertNil(Language.plainText.lineCommentToken)
    }

    func testBlockComments() {
        XCTAssertEqual(Language.cpp.blockComment, BlockComment(open: "/*", close: "*/"))
        XCTAssertNil(Language.plainText.blockComment)
    }

    func testFamilies() {
        XCTAssertEqual(Language.c.family, .cLike)
        XCTAssertEqual(Language.cpp.family, .cLike)
        XCTAssertEqual(Language.ruby.family, .rubyLike)
        XCTAssertEqual(Language.haskell.family, .mlLike)
        XCTAssertEqual(Language.bash.family, .shellLike)
        XCTAssertEqual(Language.html.family, .markup)
        XCTAssertEqual(Language.plainText.family, .plain)
    }

    // MARK: - Invariants

    func testEveryCaseHasMetadata() {
        for lang in Language.allCases {
            XCTAssertNotNil(Language.metadata[lang], "missing metadata for \(lang.rawValue)")
        }
        XCTAssertEqual(Language.metadata.count, Language.allCases.count)
    }

    func testCatalogIsComprehensive() {
        // Sanity floor: the curated catalog should recognize 200+ languages.
        XCTAssertGreaterThan(Language.allCases.count, 200)
    }

    func testRawValueRoundTrips() {
        // The tree-sitter injection fallback relies on Language(rawValue:) working.
        XCTAssertEqual(Language(rawValue: "swift"), .swift)
        XCTAssertEqual(Language(rawValue: "plaintext"), .plainText)
    }
}
