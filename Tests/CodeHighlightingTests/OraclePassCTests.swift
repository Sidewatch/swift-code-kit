//
//  OraclePassCTests.swift
//  CodeHighlightingTests
//
//  The ML family (Haskell, PureScript, Idris, Agda, Reason, SML, F#, Elm, Lean), the Lisps (Clojure,
//  Fennel, Scheme, Racket, Common Lisp, Emacs Lisp), Erlang and Prolog: each construct the whole-file
//  reference check found painted differently from VS Code and Pygments.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest form of a showcase line the reference highlighters paint one way and the
/// rule tables painted another: a declared name left plain, a reserved word or symbol left plain, a
/// literal cut short or run on.
@MainActor
final class OraclePassCTests: XCTestCase {
    nonisolated private static let kinds: [TokenKind] = [
        .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property,
    ]

    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }  // plain names read as plain text here
            let index = OraclePassCTests.kinds.firstIndex(of: kind) ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The kind every character of the `occurrence`-th `marker` in `text` is painted, nil when plain or mixed.
    private func kind(of marker: String, in text: String, _ language: Language, occurrence: Int = 0) -> TokenKind? {
        let colours = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var range = NSRange(location: NSNotFound, length: 0)
        var from = 0
        for _ in 0...occurrence {
            range = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
            guard range.location != NSNotFound else { break }
            from = NSMaxRange(range)
        }
        XCTAssertNotEqual(range.location, NSNotFound, "marker \(marker) missing")
        guard range.location != NSNotFound else { return nil }
        let found = Set(
            (range.location..<NSMaxRange(range)).map { storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor })
        guard found.count == 1, let colour = found.first ?? nil else { return nil }
        return Self.kinds.first { colours.color(for: $0) == colour }
    }

    // MARK: Haskell and PureScript

    func testHaskellSignatureNamesAreFunctions() {
        let text = "parseOrder :: String -> Maybe Order\nstage1, stage2 :: Int -> Int\nparseOrder s = Nothing\n"
        XCTAssertEqual(kind(of: "parseOrder", in: text, .haskell), .function)
        XCTAssertEqual(kind(of: "stage1, stage2", in: text, .haskell), .function)
        XCTAssertNil(kind(of: "parseOrder", in: text, .haskell, occurrence: 1))  // the definition stays plain
    }

    func testHaskellImportAndExportListNamesAreFunctions() {
        let text =
            "module Main\n  ( Order (..)\n  , revenue\n  ) where\n\n"
            + "import Data.List (foldl', sortBy)\nimport qualified Data.Map as Map\n\nx = revenue\n"
        XCTAssertEqual(kind(of: "revenue", in: text, .haskell), .function)
        XCTAssertEqual(kind(of: "sortBy", in: text, .haskell), .function)
        XCTAssertEqual(kind(of: "foldl'", in: text, .haskell), .function)
        XCTAssertNil(kind(of: "revenue", in: text, .haskell, occurrence: 1))  // a use outside the lists stays plain
    }

    func testHaskellPrimedTypeAndMagicHashLiteral() {
        let text = "data Nat' = Z | S Nat'\nmagic = ('a'#, 1)\n"
        XCTAssertEqual(kind(of: "Nat'", in: text, .haskell), .type)
        XCTAssertEqual(kind(of: "'a'", in: text, .haskell), .string)
        XCTAssertNil(kind(of: "#", in: text, .haskell))
    }

    func testPureScriptReservedSymbolsAndDataEqualsAreKeywords() {
        let text = "data Status\n  = Pending\nnewtype Sku = Sku String\nrevenue :: Array Order -> Number\nf = \\o -> o\n"
        XCTAssertEqual(kind(of: "::", in: text, .purescript), .keyword)
        XCTAssertEqual(kind(of: "->", in: text, .purescript), .keyword)
        XCTAssertEqual(kind(of: "=", in: text, .purescript), .keyword)  // a data declaration's continuation
        XCTAssertEqual(kind(of: "=", in: text, .purescript, occurrence: 1), .keyword)  // a newtype head's
        XCTAssertNil(kind(of: "=", in: text, .purescript, occurrence: 2))  // a definition's stays plain
        XCTAssertEqual(kind(of: "revenue", in: text, .purescript), .function)
    }

    func testPureScriptNumbersWithSeparators() {
        XCTAssertEqual(kind(of: "123_456.789_0", in: "n = 123_456.789_0\n", .purescript), .number)
    }

    // MARK: Idris and Agda

    func testIdrisSignatureNamesAreFunctionsEvenWhenTheyAreKeywords() {
        let text = "record Order where\n  total  : Double\n  status : Status\nprim__puts : String -> PrimIO ()\n"
        XCTAssertEqual(kind(of: "total", in: text, .idris), .function)
        XCTAssertEqual(kind(of: "prim__puts", in: text, .idris), .function)
    }

    func testIdrisReservedSymbolsWildcardAndOperators() {
        let text = "f : Nat -> Nat\nf _ = x ++ y\n"
        XCTAssertEqual(kind(of: ":", in: text, .idris), .keyword)
        XCTAssertEqual(kind(of: "->", in: text, .idris), .keyword)
        XCTAssertEqual(kind(of: "=", in: text, .idris), .keyword)
        XCTAssertEqual(kind(of: "_", in: text, .idris), .keyword)
        XCTAssertNil(kind(of: "++", in: text, .idris))  // a user operator stays plain
    }

    func testIdrisRawStringsAndSeparatedNumbers() {
        let text = "raw = #\"has \"quotes\" inside\"#\nbig = 1_000_000\n"
        XCTAssertEqual(kind(of: "#\"has \"quotes\" inside\"#", in: text, .idris), .string)
        XCTAssertEqual(kind(of: "1_000_000", in: text, .idris), .number)
    }

    func testAgdaSignatureNamesIrrelevanceDotAndSeparatedNumbers() {
        let text = "_+-identityʳ : ∀ n → n\nf : {A : Set} → .A → A\nbig = 1_000_000\n"
        XCTAssertEqual(kind(of: "_+-identityʳ", in: text, .agda), .function)
        XCTAssertEqual(kind(of: ".", in: text, .agda), .keyword)
        XCTAssertEqual(kind(of: "1_000_000", in: text, .agda), .number)
    }

    // MARK: Reason, SML and F#

    func testReasonWordOperatorsAndWildcardAreKeywords() {
        let text = "let a = x mod 2 land 3;\nlet f = (_, _unused) => 0;\n"
        XCTAssertEqual(kind(of: "mod", in: text, .reason), .keyword)
        XCTAssertEqual(kind(of: "land", in: text, .reason), .keyword)
        XCTAssertEqual(kind(of: "_", in: text, .reason), .keyword)
        XCTAssertNil(kind(of: "_unused", in: text, .reason))
    }

    func testSMLFunctionClausesAndTypeBindings() {
        let text =
            "fun fact 0 = 1\n  | fact n = n * fact (n - 1)\nval g = fn 0 => 1 | other => other\ndatatype 'a rose = Rose of 'a\nexception Fatal of sku\n"
        XCTAssertEqual(kind(of: "fact", in: text, .sml), .function)
        XCTAssertEqual(kind(of: "fact", in: text, .sml, occurrence: 1), .function)
        XCTAssertNil(kind(of: "other", in: text, .sml))  // a fn arm is not a clause
        XCTAssertEqual(kind(of: "rose", in: text, .sml), .type)
        XCTAssertEqual(kind(of: "sku", in: text, .sml), .type)
    }

    func testFSharpPrefixedStringsBangKeywordsAndMeasureTypes() {
        let text = "let j = $$\"\"\"{{ \"k\": 1 }}\"\"\"\nlet! r = x\n[<Measure>] type kg\noverride _.M() = base.M()\n"
        XCTAssertEqual(kind(of: "$$\"\"\"{{ \"k\": 1 }}\"\"\"", in: text, .fsharp), .string)
        XCTAssertEqual(kind(of: "let!", in: text, .fsharp), .keyword)
        XCTAssertEqual(kind(of: "kg", in: text, .fsharp), .type)
        XCTAssertEqual(kind(of: "base", in: text, .fsharp), .keyword)
    }

    // MARK: Elm and Lean

    func testElmReservedWordsSignaturesAndExposingLists() {
        let text =
            "port module Main exposing (Model, main, view)\nimport Html as H exposing (class)\n"
            + "type alias Sku = String\nview : Model -> Html\n"
        XCTAssertEqual(kind(of: "port", in: text, .elm), .keyword)
        XCTAssertEqual(kind(of: "alias", in: text, .elm), .keyword)
        XCTAssertEqual(kind(of: "as", in: text, .elm, occurrence: 0), .keyword)
        XCTAssertEqual(kind(of: "main", in: text, .elm), .function)
        XCTAssertEqual(kind(of: "class", in: text, .elm), .function)  // Elm has no class keyword
        XCTAssertEqual(kind(of: "view", in: text, .elm, occurrence: 1), .function)
    }

    func testLeanAttributesHidingAndNestedInterpolation() {
        let text = "open Lean hiding Name\n@[inline] def fast := 1\ndef s := s!\"nested {s!\"inner {n}\"} end\"\n"
        XCTAssertEqual(kind(of: "hiding", in: text, .lean), .keyword)
        XCTAssertEqual(kind(of: "@[inline]", in: text, .lean), .attribute)
        XCTAssertEqual(kind(of: "\"nested {s!\"inner {n}\"} end\"", in: text, .lean), .string)
        XCTAssertEqual(kind(of: "s!", in: text, .lean), .keyword)
    }

    // MARK: Lisps

    func testClojureCallHeadsSpecialFormsAndCharacters() {
        let text = "(defn- helper [x] (System/nanoTime))\n(cond-> x)\n[\\a \\\" \\;]\n(str \"s\")\n"
        XCTAssertEqual(kind(of: "System/nanoTime", in: text, .clojure), .function)
        XCTAssertEqual(kind(of: "cond->", in: text, .clojure), .function)
        XCTAssertEqual(kind(of: "defn-", in: text, .clojure), .keyword)
        XCTAssertEqual(kind(of: "\\\"", in: text, .clojure), .string)
        XCTAssertNil(kind(of: "]", in: text, .clojure, occurrence: 1))  // the character opened no string
        XCTAssertEqual(kind(of: "\"s\"", in: text, .clojure), .string)
    }

    func testClojureReaderNumbers() {
        let text = "[-17 22/7 2r1010 1.E2 1N ##-Inf]\n"
        for literal in ["-17", "22/7", "2r1010", "1.E2", "1N", "##-Inf"] {
            XCTAssertEqual(kind(of: literal, in: text, .clojure), .number, literal)
        }
    }

    func testFennelOperatorsAreSpecialFormsAndNumbersTakeSeparators() {
        let text = "(local n [(+ 1 2) (.. \"a\" \"b\") (# t) 1_000_000 0x1.8p1])\n(fn [x#] x#)\n"
        XCTAssertEqual(kind(of: "+", in: text, .fennel), .keyword)
        XCTAssertEqual(kind(of: "..", in: text, .fennel), .keyword)
        XCTAssertEqual(kind(of: "#", in: text, .fennel), .keyword)
        XCTAssertNil(kind(of: "#", in: text, .fennel, occurrence: 1))  // x# is one name
        XCTAssertEqual(kind(of: "1_000_000", in: text, .fennel), .number)
        XCTAssertEqual(kind(of: "0x1.8p1", in: text, .fennel), .number)
    }

    func testLispDefinitionNamesAreFunctions() {
        XCTAssertEqual(kind(of: "make-counter", in: "(define (make-counter step) step)\n", .scheme), .function)
        XCTAssertEqual(kind(of: "make-counter", in: "(define (make-counter step) step)\n", .racket), .function)
        XCTAssertEqual(kind(of: "square", in: "(defun square (x) (* x x))\n", .commonlisp), .function)
        XCTAssertEqual(kind(of: "warehouse--path", in: "(defun warehouse--path () nil)\n", .elisp), .function)
        XCTAssertEqual(kind(of: "define", in: "(define (f) 1)\n", .scheme), .keyword)  // the form word stays a keyword
    }

    func testRacketNumbersCharactersAndQuotedSymbols() {
        let text = "(list 1+2i 3.0-4.5i 1@2 -i 1#.# 12## #\\101 'a\\ b '#%app)\n"
        for literal in ["1+2i", "3.0-4.5i", "1@2", "-i", "1#.#", "12##"] {
            XCTAssertEqual(kind(of: literal, in: text, .racket), .number, literal)
        }
        XCTAssertEqual(kind(of: "#\\101", in: text, .racket), .string)
        XCTAssertEqual(kind(of: "'a\\ b", in: text, .racket), .string)
        XCTAssertEqual(kind(of: "'#%app", in: text, .racket), .string)
    }

    // MARK: Erlang and Prolog

    func testErlangQuoteAndPercentCharactersOpenNothing() {
        let text = "C = [$\\n, $\", $', $%, x],\nY = ok.\n"
        XCTAssertEqual(kind(of: "$\\n", in: text, .erlang), .number)
        XCTAssertEqual(kind(of: "$\"", in: text, .erlang), .string)
        XCTAssertEqual(kind(of: "$%", in: text, .erlang), .string)
        XCTAssertNil(kind(of: "x", in: text, .erlang))  // neither $" nor $' nor $% opened a string, atom or comment
        XCTAssertNil(kind(of: "ok", in: text, .erlang))
    }

    func testPrologArgumentlessClauseHeadsAreFunctions() {
        let text = "main :-\n    report.\nws --> [C], ws.\n"
        XCTAssertEqual(kind(of: "main", in: text, .prolog), .function)
        XCTAssertEqual(kind(of: "ws", in: text, .prolog), .function)
        XCTAssertNil(kind(of: "report", in: text, .prolog))
    }
}
