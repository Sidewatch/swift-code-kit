//
//  DetectionInvariantTests.swift
//  Tests for CodeLanguage — the structural rules detection depends on.
//
//  The existing suite checks that particular filenames map to particular languages. These
//  check the INVARIANTS underneath: the lookup lowercases its input, so an uppercase key is
//  dead data; the compound-extension scan iterates a dictionary, so overlapping keys would
//  resolve nondeterministically; and metadata drives the editor's comment toggling, so a
//  malformed entry breaks a feature rather than a lookup.
//
//  Created by David Sherlock on 8/5/26.
//

import XCTest
@testable import CodeLanguage

/// Invariants over the detection tables: every map key is lowercased, so no entry is
/// unreachable.
final class DetectionInvariantTests: XCTestCase {

    // MARK: - Map hygiene (dead or unreachable data)

    /// `detect(filename:)` lowercases before every lookup, so a key with any uppercase can
    /// never match — it is dead weight that reads as support for a format that is not there.
    func testAllMapKeysAreLowercased() {
        for key in Language.extensionMap.keys {
            XCTAssertEqual(key, key.lowercased(), "extensionMap key '\(key)' is unreachable")
        }
        for key in Language.filenameMap.keys {
            XCTAssertEqual(key, key.lowercased(), "filenameMap key '\(key)' is unreachable")
        }
        for key in Language.compoundExtensionMap.keys {
            XCTAssertEqual(key, key.lowercased(), "compoundExtensionMap key '\(key)' is unreachable")
        }
    }

    /// Extension keys are compared against the text AFTER the final dot, so a leading dot
    /// in the key can never match.
    func testExtensionKeysCarryNoLeadingDot() {
        for key in Language.extensionMap.keys {
            XCTAssertFalse(key.hasPrefix("."), "extensionMap key '\(key)' has a leading dot and is unreachable")
        }
    }

    /// Compound keys must contain a dot — that is what makes them compound. A dotless one
    /// belongs in `extensionMap`, where it would be found sooner and more cheaply.
    func testCompoundKeysContainADot() {
        for key in Language.compoundExtensionMap.keys {
            XCTAssertTrue(key.contains("."), "compoundExtensionMap key '\(key)' is not compound")
        }
    }

    /// THE LATENT TRAP: the compound scan is `for (ext, lang) in dictionary where …`, and
    /// Swift's dictionary iteration order is not stable across runs. Two keys where one is a
    /// suffix of the other would therefore resolve to EITHER language depending on hash
    /// seed — a bug that reproduces on one machine and not another. Not currently violated;
    /// this test is what keeps it that way when a third entry is added.
    func testCompoundKeysDoNotOverlap() {
        let keys = Array(Language.compoundExtensionMap.keys)
        for a in keys {
            for b in keys where a != b {
                XCTAssertFalse(a.hasSuffix("." + b),
                               "'\(a)' and '\(b)' both match one filename; dictionary order decides the winner")
            }
        }
    }

    // MARK: - Precedence ladder

    /// Documented order: exact filename → prefix rule → compound extension → plain
    /// extension. Each case below is only correct if the rule ABOVE it wins.
    func testPrecedenceLadderHoldsAtEveryRung() {
        // filename beats extension: a file literally named for a known filename key
        if let (name, expected) = Language.filenameMap.first(where: { $0.key.contains(".") }) {
            XCTAssertEqual(Language.detect(filename: name), expected,
                           "exact filename must beat the plain-extension rule")
        }
        // prefix beats extension: Dockerfile.dev has extension "dev" (unknown) → dockerfile
        XCTAssertEqual(Language.detect(filename: "Dockerfile.dev"), .dockerfile)
        // prefix beats extension even when the extension IS known: .env.json stays dotenv
        XCTAssertEqual(Language.detect(filename: ".env.json"), .dotenv)
        // compound beats plain: blade.php is blade, not php
        XCTAssertEqual(Language.detect(filename: "page.blade.php"), .blade)
        XCTAssertNotEqual(Language.detect(filename: "page.blade.php"), .php)
        // plain extension is the floor
        XCTAssertEqual(Language.detect(filename: "main.swift"), .swift)
    }

    /// A filename that is only a dot-extension (`.swift`) must not be read as an
    /// extensionless dotfile — and a trailing dot has no extension at all.
    func testDegenerateNamesDoNotCrashOrMisResolve() {
        XCTAssertEqual(Language.detect(filename: "main."), .plainText, "trailing dot = no extension")
        XCTAssertEqual(Language.detect(filename: "."), .plainText)
        XCTAssertEqual(Language.detect(filename: ""), .plainText)
        XCTAssertEqual(Language.detect(filename: "..."), .plainText)
    }

    /// Detection reads the last path component only — a directory that looks like a
    /// filename must not leak into the result.
    func testDirectoryComponentsAreIgnored() {
        let url = URL(fileURLWithPath: "/tmp/Makefile/notes.txt")
        XCTAssertEqual(Language.detect(for: url), Language.detect(filename: "notes.txt"))
        XCTAssertNotEqual(Language.detect(for: url), .makefile)
    }

    // MARK: - Metadata consistency

    /// Every language the maps can PRODUCE must have a metadata entry, or the editor
    /// silently loses its display name and comment tokens for a file it claims to know.
    ///
    /// Deliberately does NOT require a non-`.plain` family: `.plain` is a real answer for
    /// the many languages with no dedicated grammar (fortran, diff, mermaid, abap…), which
    /// fall back to the regex highlighter by design.
    func testEveryReachableLanguageHasMetadata() {
        let reachable = Set(Language.extensionMap.values)
            .union(Language.filenameMap.values)
            .union(Language.compoundExtensionMap.values)
        for language in reachable {
            XCTAssertNotNil(Language.metadata[language], "\(language) is reachable but has no metadata entry")
            XCTAssertFalse(language.displayName.isEmpty, "\(language) has no display name")
        }
    }

    /// Comment tokens drive Toggle Line Comment. An empty token would wrap lines in nothing
    /// and an unbalanced block pair would corrupt the buffer.
    func testCommentTokensAreWellFormed() {
        for language in Language.allCases {
            if let token = language.lineCommentToken {
                XCTAssertFalse(token.trimmingCharacters(in: .whitespaces).isEmpty,
                               "\(language) has an empty line-comment token")
            }
            if let block = language.blockComment {
                // Symmetric delimiters are legitimate — asciidoc uses //// for both ends and
                // coffeescript ###, the way Python uses \"\"\". Only emptiness is a defect.
                XCTAssertFalse(block.open.isEmpty, "\(language) block comment has no opener")
                XCTAssertFalse(block.close.isEmpty, "\(language) block comment has no closer")
            }
        }
    }

    /// Raw values identify languages in persisted state (session, custom-language
    /// definitions), so a duplicate would silently alias two languages to one.
    func testRawValuesAreUnique() {
        let raws = Language.allCases.map(\.rawValue)
        XCTAssertEqual(Set(raws).count, raws.count, "duplicate rawValue among Language cases")
    }

    // MARK: - Real filenames from this repository

    /// Detection is exercised constantly on this repo's own files; these are the shapes it
    /// actually meets, including the ones that tripped it before (dotfiles, lock files).
    func testRealWorldFilenamesFromThisRepo() {
        let expectations: [(String, Language)] = [
            ("Package.swift", .swift),
            ("Package.resolved", .json),
            ("CLAUDE.md", .markdown),
            (".gitignore", .gitignore),
            ("bundle.sh", .bash),
            ("Info.plist", .plist),
            ("skills.json", .json),
            ("project.yml", .yaml),
        ]
        for (name, expected) in expectations {
            XCTAssertEqual(Language.detect(filename: name), expected, "detect(\(name))")
        }
    }
}
