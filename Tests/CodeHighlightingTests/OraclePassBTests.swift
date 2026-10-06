//
//  OraclePassBTests.swift
//  CodeHighlightingTests
//
//  The SQL dialects (HiveQL, PL/SQL, PL/pgSQL), XQuery, Prisma, PRQL and the config and data formats
//  (Apache, NGINX, Bicep, dotenv, HCL, JSON5, JSON Lines, KDL, Meson, RON): each construct the
//  whole-file reference check found painted differently from VS Code and Pygments.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import AppKit
import CodeLanguage
@testable import CodeHighlighting

/// Each snippet is the smallest form of a showcase line the reference highlighters paint one way and the
/// rule tables painted another: a dialect's own word left plain, a literal's prefix or operator painted as
/// part of it, a key painted as a value, a declared name left plain.
@MainActor
final class OraclePassBTests: XCTestCase {
    nonisolated private static let kinds: [TokenKind] = [
        .comment, .string, .keyword, .type, .number, .function, .attribute, .variable, .property,
    ]

    private struct OneColourPerKind: TokenColorProviding {
        let foreground = NSColor.black
        func color(for kind: TokenKind) -> NSColor {
            if kind == .identifier { return foreground }  // plain names read as plain text here
            let index = OraclePassBTests.kinds.firstIndex(of: kind) ?? 0
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

    // MARK: SQL dialects

    func testHiveQLResourceWordsAreKeywords() {
        XCTAssertEqual(kind(of: "FILE", in: "ADD FILE /tmp/lookup.txt;\n", .hiveql), .keyword)
        XCTAssertEqual(kind(of: "JAR", in: "ADD JAR /tmp/udf.jar;\n", .hiveql), .keyword)
    }

    func testPLpgSQLBlockCommentsNest() {
        let text = "/* outer\n   /* inner */\n   STILL inside */\nSELECT 1;\n"
        XCTAssertEqual(kind(of: "STILL", in: text, .plpgsql), .comment)
        XCTAssertEqual(kind(of: "SELECT", in: text, .plpgsql), .keyword)
    }

    func testPLpgSQLBitAndHexPrefixesStayCode() {
        let text = "SELECT B'1010', X'1F';\n"
        XCTAssertEqual(kind(of: "B'", in: text, .plpgsql), nil)
        XCTAssertEqual(kind(of: "'1010'", in: text, .plpgsql), .string)
    }

    func testPLpgSQLOneLineDoBodyIsCode() {
        let text = "DO LANGUAGE plpgsql $do$ BEGIN PERFORM 1; END $do$;\nSELECT $$text$$;\n"
        XCTAssertEqual(kind(of: "PERFORM", in: text, .plpgsql), .keyword)
        XCTAssertEqual(kind(of: "$$text$$", in: text, .plpgsql), .string)
    }

    func testPLpgSQLDialectWordsAndQuotedNames() {
        let text = "CREATE EVENT TRIGGER t ON ddl_command_end EXECUTE FUNCTION f();\nSELECT 'a' COLLATE \"C\";\n"
        XCTAssertEqual(kind(of: "EVENT", in: text, .plpgsql), .keyword)
        XCTAssertEqual(kind(of: "\"C\"", in: text, .plpgsql), .string)
    }

    func testPLSQLPromptLineIsAComment() {
        XCTAssertEqual(kind(of: "Creating the package", in: "PROMPT Creating the package\nSET DEFINE OFF\n", .plsql), .comment)
    }

    func testPLSQLLiteralPrefixesStayCode() {
        let text = "x := q'[it's here]' || N'national';\n"
        XCTAssertEqual(kind(of: "q'", in: text, .plsql), nil)
        XCTAssertEqual(kind(of: "'[it's here]'", in: text, .plsql), .string)
        XCTAssertEqual(kind(of: "N'", in: text, .plsql), nil)
        XCTAssertEqual(kind(of: "'national'", in: text, .plsql), .string)
    }

    func testPLSQLDeclaredNamesAndQuotedNames() {
        let text = "CREATE OR REPLACE PACKAGE BODY stock_pkg AS\n  FUNCTION low_stock RETURN NUMBER;\n  x := XMLELEMENT(\"sku\", 1);\n"
        XCTAssertEqual(kind(of: "stock_pkg", in: text, .plsql), .type)
        XCTAssertEqual(kind(of: "low_stock", in: text, .plsql), .function)
        XCTAssertEqual(kind(of: "\"sku\"", in: text, .plsql), .string)
    }

    func testPLSQLOracleWordsAndTypes() {
        let text = "PRAGMA SERIALLY_REUSABLE;\nv SIMPLE_DOUBLE := 0d;\nFUNCTION f RETURN NUMBER AS LANGUAGE C NAME \"f\";\n"
        XCTAssertEqual(kind(of: "SERIALLY_REUSABLE", in: text, .plsql), .keyword)
        XCTAssertEqual(kind(of: "SIMPLE_DOUBLE", in: text, .plsql), .type)
        XCTAssertEqual(kind(of: "C", in: text, .plsql, occurrence: 1), .keyword)
    }

    // MARK: XQuery

    func testXQueryStringConstructorIsAString() {
        XCTAssertEqual(kind(of: "TEMPLATE", in: "let $t := ``[a TEMPLATE string]``\nreturn $t\n", .xquery), .string)
    }

    func testXQueryKindTestsInTypesAreKeywordsAndPathStepsCalls() {
        let text = "declare variable $m as map(*) := map {};\nlet $p as item()* := $o/node()\n"
        XCTAssertEqual(kind(of: "map", in: text, .xquery), .keyword)
        XCTAssertEqual(kind(of: "item", in: text, .xquery), .keyword)
        XCTAssertEqual(kind(of: "node", in: text, .xquery), .function)
    }

    func testXQueryPrefixedCallsAndFunctionReferences() {
        let text = "let $q := xs:QName(\"x\")\nlet $f := ex:money#1\nlet $s := ($a union $b) intersect ($c)\n"
        XCTAssertEqual(kind(of: "xs:QName", in: text, .xquery), .function)
        XCTAssertEqual(kind(of: "ex:money", in: text, .xquery), .function)
        XCTAssertEqual(kind(of: "intersect", in: text, .xquery), .keyword)
    }

    func testXQueryAxesAndWindowWords() {
        let text = "let $a := $o/following-sibling::*\nfor sliding window $w in $s start when true() only end when false()\n"
        XCTAssertEqual(kind(of: "following-sibling", in: text, .xquery), .keyword)
        XCTAssertEqual(kind(of: "start", in: text, .xquery), .keyword)
        XCTAssertEqual(kind(of: "only", in: text, .xquery), .keyword)
    }

    // MARK: Prisma and PRQL

    func testPrismaBlockNamesNativeTypesAndSignedNumbers() {
        let text =
            "generator client {\n  provider = \"prisma-client-js\"\n}\nmodel Item {\n  sku String @db.VarChar(32)\n  b Int @default(-42)\n}\n"
        XCTAssertEqual(kind(of: "client", in: text, .prisma), .type)
        XCTAssertEqual(kind(of: "@db.VarChar", in: text, .prisma), .attribute)
        XCTAssertEqual(kind(of: "-42", in: text, .prisma), .number)
    }

    func testPRQLStandardFunctionsModulesAndTypes() {
        let text = "module inv {\n  let x = 1\n}\naggregate {total = sum revenue, lowered = text.lower name}\n"
        XCTAssertEqual(kind(of: "inv", in: text, .prql), .type)
        XCTAssertEqual(kind(of: "sum", in: text, .prql), .function)
        XCTAssertEqual(kind(of: "text", in: text, .prql), .type)
        XCTAssertEqual(kind(of: "in", in: "filter (status | in [\"paid\"])\n", .prql), .function)
    }

    // MARK: Apache and NGINX

    func testApacheSectionArgumentsAndPathsAreStrings() {
        let text = "<IfVersion >= 2.4>\n    RedirectMatch 301 ^/legacy/(.*)$ /archive/$1\n</IfVersion>\n"
        XCTAssertEqual(kind(of: ">= 2.4", in: text, .apacheconf), .string)
        XCTAssertEqual(kind(of: "/archive/", in: text, .apacheconf), .string)
    }

    func testNginxRegexOperatorStaysCodeAndURIsAreStrings() {
        let text =
            "server_name ~^(?<sub>.+)\\.example\\.net$;\nlocation = /healthz { return 200; }\nrewrite ^/old/(.*)$ /new/$1 permanent;\n"
        XCTAssertEqual(kind(of: "~", in: text, .nginx), nil)
        XCTAssertEqual(kind(of: "^(?<sub>.+)", in: text, .nginx), .string)
        XCTAssertEqual(kind(of: "/healthz", in: text, .nginx), .string)
        XCTAssertEqual(kind(of: "^/old/(.*)", in: text, .nginx), .string)
        XCTAssertEqual(kind(of: "/new/", in: text, .nginx), .string)
    }

    // MARK: Bicep

    func testBicepNestedInterpolationAndConversionCalls() {
        let text = "var nested = 'a ${'MID ${'c'}'} TAIL'\nvar n = int('42')\nparam p int\n"
        XCTAssertEqual(kind(of: "MID", in: text, .bicep), .string)
        XCTAssertEqual(kind(of: "TAIL", in: text, .bicep), .string)
        XCTAssertEqual(kind(of: "int", in: text, .bicep), .function)
        XCTAssertEqual(kind(of: "int", in: text, .bicep, occurrence: 1), .type)
    }

    // MARK: dotenv and HCL

    func testDotenvExpansionPunctuationAndQuotedDefaults() {
        let text = "API_URL=${BASE_URL}/v1\nDEFAULTED=${UNDEFINED:-\"quoted default\"}\n"
        XCTAssertEqual(kind(of: "${", in: text, .dotenv), .keyword)
        XCTAssertEqual(kind(of: "BASE_URL", in: text, .dotenv), .variable)
        XCTAssertEqual(kind(of: "}", in: text, .dotenv), .keyword)
        XCTAssertEqual(kind(of: "\"quoted default\"", in: text, .dotenv), .variable)
    }

    func testHCLHeredocOperatorAndStringsBeforeABrace() {
        let text = "heredoc = <<EOT\nBody\nEOT\nx = [yamldecode(\"a: 1\"), jsondecode(\"{}\")]\n"
        XCTAssertEqual(kind(of: "<<", in: text, .hcl), nil)
        XCTAssertEqual(kind(of: "EOT", in: text, .hcl), .string)
        XCTAssertEqual(kind(of: "\"a: 1\"", in: text, .hcl), .string)
    }

    // MARK: Data formats

    func testJSON5QuotedKeysAreNamesNotStrings() {
        let text = "{\n  \"quoted key\": \"value\",\n  'single key': 'other',\n}\n"
        XCTAssertEqual(kind(of: "\"quoted key\"", in: text, .json5), .function)
        XCTAssertEqual(kind(of: "'single key'", in: text, .hjson), .function)
        XCTAssertEqual(kind(of: "\"value\"", in: text, .json5), .string)
        XCTAssertEqual(kind(of: "'other'", in: text, .json5), .string)
    }

    func testJSONLinesNegativeNumbersKeepTheirSign() {
        XCTAssertEqual(kind(of: "-12.5", in: "{\"delta\": -12.5}\n", .jsonlines), .number)
    }

    func testKDLExponentWithDigitSeparators() {
        XCTAssertEqual(kind(of: "1.0e1_0", in: "floats 1.0e1_0 2\n", .kdl), .number)
    }

    func testMesonRadixNumbers() {
        let text = "integer_hex = 0xFF\ninteger_oct = 0o755\n"
        XCTAssertEqual(kind(of: "0xFF", in: text, .meson), .number)
        XCTAssertEqual(kind(of: "0o755", in: text, .meson), .number)
    }

    func testRONCapitalisedNamesByteStringsAndExponents() {
        let text = "(\n  mode: Production,\n  bytes: b\"ab\",\n  raw: br\"cd\",\n  big: 1E23,\n  hex: 0XFF,\n)\n"
        XCTAssertEqual(kind(of: "Production", in: text, .ron), .type)
        XCTAssertEqual(kind(of: "b\"ab\"", in: text, .ron), .string)
        XCTAssertEqual(kind(of: "r\"cd\"", in: text, .ron), .string)
        XCTAssertEqual(kind(of: "br", in: text, .ron), nil)
        XCTAssertEqual(kind(of: "1E23", in: text, .ron), .number)
        XCTAssertEqual(kind(of: "XFF", in: text, .ron), .type)
    }
}
