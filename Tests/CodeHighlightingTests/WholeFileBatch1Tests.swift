//
//  WholeFileBatch1Tests.swift
//  CodeHighlightingTests
//
//  The C dialects, the Lisps, HCL, Git config, INI, Groovy, Starlark, Rego, Fortran, Prolog, Makefile,
//  Nix, Smalltalk and WAT: each showcase coloured right from its first line to its last.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest thing from a corpus showcase that the whole-file check found painted
/// wrong: a literal that opened a string or comment it was not, a string that ended early, a dialect's
/// own words left plain, a keyword painted as a call.
@MainActor
final class WholeFileBatch1Tests: XCTestCase {
    nonisolated private static let kinds: [TokenKind] = [
        .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property, .added, .removed,
    ]

    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            let index = WholeFileBatch1Tests.kinds.firstIndex(of: kind) ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
    }

    /// The kind every character of the first `marker` in `text` is painted, nil when plain or mixed.
    private func kind(of marker: String, in text: String, _ language: Language) -> TokenKind? {
        let colours = OneColourPerKind()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let range = (text as NSString).range(of: marker)
        XCTAssertNotEqual(range.location, NSNotFound, "marker \(marker) missing")
        guard range.location != NSNotFound else { return nil }
        let found = Set(
            (range.location..<NSMaxRange(range)).map { storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor })
        guard found.count == 1, let colour = found.first ?? nil else { return nil }
        return Self.kinds.first { colours.color(for: $0) == colour }
    }

    // MARK: Smalltalk

    func testSmalltalkCharacterLiteralsNeverOpenAStringOrComment() {
        let text = "chars := {$'. $\"}.\nnote := 'NOTE'.\nx := 3.14s2.\n"
        XCTAssertEqual(kind(of: "NOTE", in: text, .smalltalk), .string)
        XCTAssertEqual(kind(of: "note", in: text, .smalltalk), nil)
        XCTAssertEqual(kind(of: "3.14s2", in: text, .smalltalk), .number)
    }

    // MARK: Terraform / HCL

    func testHCLBlockLabelsAreNamesAndTypeConstraintsAreTypes() {
        let text = "resource \"aws_instance\" \"web\" {\n  type = string\n  name = \"webserver\"\n}\n"
        XCTAssertEqual(kind(of: "aws_instance", in: text, .terraform), .type)
        XCTAssertEqual(kind(of: "string", in: text, .terraform), .type)
        XCTAssertEqual(kind(of: "\"webserver\"", in: text, .terraform), .string)
        // A label holding a comment opener stays a string, so the opener opens no comment.
        let path = "path \"secret/data/*\" {\n  capabilities = [\"read\"]\n}\n"
        XCTAssertEqual(kind(of: "capabilities", in: path, .hcl), .function)
    }

    func testHCLInterpolationMayHoldQuotedStrings() {
        XCTAssertEqual(kind(of: "INNER", in: "x = \"a ${upper(\"INNER\")} b\"\n", .hcl), .string)
        XCTAssertEqual(kind(of: "TAIL", in: "nested = \"a ${\"b ${\"c\"}\"} TAIL\"\n", .hcl), .string)
    }

    func testHCLHeredocBodyIsAString() {
        let text = "description = <<-EOT\n    Heredoc BODY text\n    EOT\nnext = 1\n"
        XCTAssertEqual(kind(of: "BODY", in: text, .terraform), .string)
        XCTAssertEqual(kind(of: "next", in: text, .terraform), .function)
    }

    // MARK: Git config and INI

    func testGitConfigEscapedQuoteOutsideQuotesOpensNoString() {
        let text = "[alias]\n\tx = echo \\\"one\\\" two\n\ty = 1 ; NOTE\n\tz = \"end\"\n"
        XCTAssertEqual(kind(of: "NOTE", in: text, .gitconfig), .comment)
    }

    func testINIKeyMayStartWithADigit() {
        XCTAssertEqual(kind(of: "1numeric", in: "1numeric = start with digit\n", .ini), .function)
    }

    // MARK: C dialects

    func testGLSLWordsAndTypesAndAKeywordWrittenLikeACall() {
        let text = "uniform vec3 tint;\nvoid main() { if (tint.x > 0.0) { gl_FragColor = vec4(tint, 1.f); } }\n"
        XCTAssertEqual(kind(of: "uniform", in: text, .glsl), .keyword)
        XCTAssertEqual(kind(of: "vec3", in: text, .glsl), .type)
        XCTAssertEqual(kind(of: "if", in: text, .glsl), .keyword)
        XCTAssertEqual(kind(of: "1.f", in: text, .glsl), .number)
    }

    func testHLSLVectorTypesAndQualifiers() {
        let text = "cbuffer Frame : register(b0) { float4x4 world; };\ngroupshared uint cache[64];\n"
        XCTAssertEqual(kind(of: "float4x4", in: text, .hlsl), .type)
        XCTAssertEqual(kind(of: "groupshared", in: text, .hlsl), .keyword)
        XCTAssertEqual(kind(of: "cbuffer", in: text, .hlsl), .keyword)
    }

    func testCUDADigitSeparatorIsNotACharacterLiteral() {
        let text = "__global__ void k() { long long big = 1'000'000LL; const char* r = R\"(a \" b)\"; int AFTER = 0; }\n"
        XCTAssertEqual(kind(of: "__global__", in: text, .cuda), .keyword)
        XCTAssertEqual(kind(of: "1'000'000LL", in: text, .cuda), .number)
        XCTAssertEqual(kind(of: "a \" b", in: text, .cuda), .string)
        XCTAssertEqual(kind(of: "AFTER", in: text, .cuda), nil)
    }

    func testMetalAndOpenCLQualifiersAndVectors() {
        XCTAssertEqual(kind(of: "kernel", in: "kernel void k(device half4* p) {}\n", .metal), .keyword)
        XCTAssertEqual(kind(of: "half4", in: "kernel void k(device half4* p) {}\n", .metal), .type)
        XCTAssertEqual(kind(of: "__global", in: "__kernel void k(__global float4* p) {}\n", .opencl), .keyword)
        XCTAssertEqual(kind(of: "float4", in: "__kernel void k(__global float4* p) {}\n", .opencl), .type)
    }

    func testWGSLBlockCommentsNest() {
        let text = "/* a /* b */ STILL */\nfn main() { loop { break; } }\n"
        XCTAssertEqual(kind(of: "STILL", in: text, .wgsl), .comment)
        XCTAssertEqual(kind(of: "loop", in: text, .wgsl), .keyword)
    }

    func testObjectiveCAtStringsAndPropertyAttributes() {
        let text = "@property (nonatomic, copy) NSString *name;\nNSString *s = @\"hi\";\n"
        XCTAssertEqual(kind(of: "nonatomic", in: text, .objectivec), .keyword)
        XCTAssertEqual(kind(of: "@\"hi\"", in: text, .objectivec), .string)
        XCTAssertEqual(kind(of: "@property", in: text, .objectivec), .keyword)
    }

    func testValaVerbatimStringHoldsQuotes() {
        let text = "string v = \"\"\"Verbatim with \"quotes\" TAIL\"\"\";\nsignal void changed();\n"
        XCTAssertEqual(kind(of: "TAIL", in: text, .vala), .string)
        XCTAssertEqual(kind(of: "signal", in: text, .vala), .keyword)
    }

    func testShaderLabStructureWords() {
        let text = "Shader \"A/B\" {\n  SubShader {\n    Pass { HLSLPROGRAM\n    float4 c;\n    ENDHLSL }\n  }\n}\n"
        XCTAssertEqual(kind(of: "SubShader", in: text, .shaderlab), .keyword)
        XCTAssertEqual(kind(of: "HLSLPROGRAM", in: text, .shaderlab), .keyword)
        XCTAssertEqual(kind(of: "float4", in: text, .shaderlab), .type)
    }

    // MARK: Groovy, Starlark, Rego, Fortran, Prolog, Makefile, Nix

    func testGroovySlashyStringsAndTypes() {
        let text = "def re = ~/^v\\d+$/\nint count = 3\n"
        XCTAssertEqual(kind(of: "\\d+", in: text, .groovy), .string)
        XCTAssertEqual(kind(of: "int", in: text, .gradle), .type)
        XCTAssertEqual(kind(of: "def", in: text, .gradle), .keyword)
    }

    func testStarlarkKeywords() {
        XCTAssertEqual(kind(of: "def", in: "def rule(name):\n    pass\n", .starlark), .keyword)
    }

    func testRegoRawStringsAndKeywords() {
        let text = "raw := `^AC-\\d{4}$`\nallow if { some x in input.items }\n"
        XCTAssertEqual(kind(of: "\\d{4}", in: text, .rego), .string)
        XCTAssertEqual(kind(of: "some", in: text, .rego), .keyword)
    }

    func testFortranContainsInTheFirstColumnIsTheStatement() {
        let text = "module m\ncontains\n  subroutine s()\n    if (x > 0) then\n    end if\n  end subroutine\nend module\n"
        XCTAssertEqual(kind(of: "contains", in: text, .fortran), .keyword)
        XCTAssertEqual(kind(of: "if", in: text, .fortran), .keyword)
    }

    func testPrologCharacterCodeOpensNoQuotedAtom() {
        let text = "t :- D = 0'c, E = 'x'.\n% NOTE\nu :- F = 'y'.\n"
        XCTAssertEqual(kind(of: "NOTE", in: text, .prolog), .comment)
        XCTAssertEqual(kind(of: "16'FF", in: "n(16'FF).\n", .prolog), .number)
    }

    func testMakefileEscapedHashIsNoComment() {
        XCTAssertNotEqual(kind(of: "not", in: "SPECIAL = \\# not a comment\n", .makefile), .comment)
    }

    func testNixIndentedStringEscapesAndNestedQuotes() {
        XCTAssertEqual(kind(of: "TAIL", in: "x = '' a ''$ b ''\\n c ''' TAIL '';\n", .nix), .string)
        XCTAssertEqual(kind(of: "INNER", in: "y = \"a ${f \"b\" INNER} c\";\n", .nix), .string)
        XCTAssertNotEqual(kind(of: "//", in: "z = { a = 1; } // { b = 2; };\n", .nix), .string)
    }

    // MARK: Lisps and WAT

    func testCommonLispCharacterLiteralOpensNoComment() {
        let text = "(defun f (x &optional y) (list #\\; x #xFF))\n"
        XCTAssertEqual(kind(of: "#xFF", in: text, .commonlisp), .number)
        XCTAssertEqual(kind(of: "&optional", in: text, .commonlisp), .keyword)
    }

    func testEmacsLispCharacterAndEscapedSemicolonOpenNoComment() {
        let text = "(list ?\\; symbol\\;semi AFTER)\n(interactive)\n"
        XCTAssertNotEqual(kind(of: "AFTER", in: text, .elisp), .comment)
        XCTAssertEqual(kind(of: "interactive", in: text, .elisp), .keyword)
    }

    func testSchemeCharacterQuoteOpensNoString() {
        let text = "(list #\\\" AFTER)\n(set! x \"y\")\n"
        XCTAssertNotEqual(kind(of: "AFTER", in: text, .scheme), .string)
        XCTAssertEqual(kind(of: "set!", in: text, .scheme), .keyword)
    }

    func testRacketRegexpLiteralsAndHereStrings() {
        let text = "#lang racket\n(define-values (a b) (values #rx\"^a\" #<<END\nHERE body\nEND\n))\n"
        XCTAssertEqual(kind(of: "#rx\"^a\"", in: text, .racket), .string)
        XCTAssertEqual(kind(of: "HERE", in: text, .racket), .string)
        XCTAssertEqual(kind(of: "define-values", in: text, .racket), .keyword)
    }

    func testFennelSpecialForms() {
        XCTAssertEqual(kind(of: "local", in: "(local x (icollect [_ v (ipairs t)] v))\n", .fennel), .keyword)
        XCTAssertEqual(kind(of: "icollect", in: "(local x (icollect [_ v (ipairs t)] v))\n", .fennel), .keyword)
    }

    func testWATNestingCommentsAndModuleWords() {
        let text = "(; a (; b ;) STILL ;)\n(func $f (param i32) (result i32) (i32.add (local.get 0) (i32.const 0x1.8p3)))\n"
        XCTAssertEqual(kind(of: "STILL", in: text, .wat), .comment)
        XCTAssertEqual(kind(of: "param", in: text, .wat), .keyword)
        XCTAssertEqual(kind(of: "0x1.8p3", in: text, .wat), .number)
    }
}
