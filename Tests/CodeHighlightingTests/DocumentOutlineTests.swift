//
//  DocumentOutlineTests.swift
//  CodeHighlightingTests
//
//  Outlines for every language: the source each language takes, the regex tier's tables, a data
//  file's key tree, and every corpus showcase with declarations producing one.
//
//  Created by David Sherlock on 10/4/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

/// Outlines for every language: the source each language takes, the regex tier's tables, a data
/// file's key tree, and every corpus showcase with declarations producing one (skipped when the
/// corpus is not cloned).
final class DocumentOutlineTests: XCTestCase {
    private var corpus: URL {
        if let path = ProcessInfo.processInfo.environment["SIDEWATCH_CORPUS"] { return URL(fileURLWithPath: path) }
        return URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../../../../TestFiles").standardized
    }

    /// The showcase for the language folder `name`, its language and text; skips when absent.
    private func showcase(_ name: String) throws -> (language: Language, text: String) {
        let dir = corpus.appendingPathComponent("languages/\(name)")
        guard
            let file = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                .first(where: { !$0.lastPathComponent.hasPrefix("README") })
        else { throw XCTSkip("corpus not cloned") }
        return (Language.detect(for: file), try String(contentsOf: file, encoding: .utf8))
    }

    /// The outline of a showcase as nested "name" / "  child" lines, two levels deep.
    private func outline(_ name: String) throws -> [String] {
        let (language, text) = try showcase(name)
        var lines: [String] = []
        func walk(_ nodes: [OutlineNode], _ indent: String) {
            for n in nodes {
                lines.append(indent + n.symbol.name)
                if indent.isEmpty { walk(n.children, "  ") }
            }
        }
        walk(OutlineTree.build(from: DocumentOutline.symbols(parsing: text, language: language)), "")
        return lines
    }

    /// `expected` appears in `lines` as a contiguous run.
    private func assertRun(_ expected: [String], in lines: [String], file: StaticString = #filePath, line: UInt = #line) {
        let found = lines.indices.contains { i in Array(lines[i...].prefix(expected.count)) == expected }
        XCTAssertTrue(found, "missing run \(expected) in \(lines.prefix(40))", file: file, line: line)
    }

    // MARK: - Sources

    func testEachLanguageTakesItsSource() {
        XCTAssertEqual(DocumentOutline.source(for: .markdown), .headings)
        XCTAssertEqual(DocumentOutline.source(for: .quarto), .headings)
        XCTAssertEqual(DocumentOutline.source(for: .postcss), .stylesheet)
        XCTAssertEqual(DocumentOutline.source(for: .swift), .syntaxTree)
        XCTAssertEqual(DocumentOutline.source(for: .yaml), .keyTree)
        XCTAssertEqual(DocumentOutline.source(for: .plist), .propertyList)
        XCTAssertEqual(DocumentOutline.source(for: .raku), .lines)
        XCTAssertEqual(DocumentOutline.source(for: .dockerfile), .lines, "stages by FROM, though a grammar exists")
        XCTAssertEqual(DocumentOutline.source(for: .csv), .none)
        XCTAssertTrue(DocumentOutline.pathComesFromOutline(.raku))
        XCTAssertFalse(DocumentOutline.pathComesFromOutline(.swift), "code with a query keeps the tree walk")
    }

    func testEveryTableCompilesWithOneGroupPerRule() {
        XCTAssertEqual(RegexOutline.everyTableCompiles.filter { !$0.value }.map(\.key), [])
        XCTAssertGreaterThan(RegexOutline.tables.count, 120)
    }

    func testTreeOutlinesAnswerEmptyWithoutASession() {
        XCTAssertEqual(
            DocumentOutline.symbols(in: "func a() {}", language: .swift, session: nil).count, 0, "no parse on the caller's thread")
        XCTAssertEqual(DocumentOutline.symbols(in: "{\"a\": 1}", language: .json, session: nil).count, 0)
    }

    // MARK: - The regex tier, family by family

    func testBraceLanguagesNestByTheirBlocks() throws {
        assertRun(["Status", "  label", "Perm", "Item", "  init", "  value", "  restock"], in: try outline("zig"))
        assertRun(["compose", "  vararg"], in: try outline("r"))
        let raku = try outline("raku")
        XCTAssertTrue(raku.contains("OrderLine"), "\(raku.prefix(20))")
        XCTAssertTrue(try outline("perl").contains("describe"))
    }

    func testIndentationLanguagesNestByIndent() throws {
        assertRun(["Acme.Warehouse", "  StockError", "  Describable"], in: try outline("elixir"))
        assertRun(["Acme.MixProject", "  project", "  deps"], in: try outline("elixir"))
        assertRun(["Category", "  label"], in: try outline("crystal"))
        XCTAssertTrue(try outline("julia").starts(with: ["Warehouse", "Item"]))
        XCTAssertTrue(try outline("haskell").starts(with: ["Sample", "Name", "Table"]))
    }

    func testLevelledLanguagesNestByLevel() throws {
        assertRun(["Introduction", "  Scope"], in: try outline("latex"))
        assertRun(["general", "  name", "  version", "  debug"], in: try outline("ini"))
        assertRun(["src/inventory.py", "  @@ -12,10 +12,13 @@ REORDER_POINT = 25"], in: try outline("diff"))
        assertRun(["Order", "  initWithNumber:", "  init"], in: try outline("objectivec"))
        assertRun(["logic_blocks", "  clog2", "  show"], in: try outline("verilog"))
        XCTAssertTrue(try outline("dockerfile").starts(with: ["build", "runtime", "minimal"]))
    }

    func testFlatLanguagesListTheirDeclarations() throws {
        XCTAssertTrue(try outline("sh").starts(with: ["classify", "prompt_dir", "stock_report"]))
        let make = try outline("makefile")
        XCTAssertFalse(make.contains(".PHONY"), "special targets are not recipes")
        XCTAssertFalse(make.isEmpty)
        XCTAssertEqual(
            RegexOutline.symbols(in: "f(0) -> 1;\nf(N) -> N * f(N - 1).\n", language: .erlang).map(\.name), ["f"], "clauses list once")
    }

    func testRulesMatchWhatTheyClaim() {
        func names(_ text: String, _ language: Language) -> [String] { RegexOutline.symbols(in: text, language: language).map(\.name) }
        XCTAssertEqual(names("summary <- function(x) {\n  x\n}\n", .r), ["summary"])
        XCTAssertEqual(
            names("unit class Shop::Order;\nmethod total() { }\nrole Priced { }\ngrammar G {\n    token TOP { . }\n}\n", .raku),
            ["Shop::Order", "total", "Priced", "G", "TOP"])
        XCTAssertEqual(names("CREATE OR REPLACE VIEW `shop`.`open_orders` AS SELECT 1;\n", .mysql), ["shop.open_orders"])
        XCTAssertEqual(names("resource \"aws_instance\" \"web\" {\n}\n", .terraform), ["aws_instance web"])
        XCTAssertEqual(
            names("  return parse(x);\nstatic int parse(const char *s) {\n}\n", .glsl), ["parse"], "a return is not a definition")
        XCTAssertEqual(names("expr\n  : expr '+' term\n  ;\n", .yacc), ["expr"], "a rule whose colon starts the next line")
    }

    func testBraceScopesSkipStringsAndComments() {
        let text = "sub a {\n  my $s = \"}\"; # }\n  1;\n}\nsub b { 2 }\n"
        let symbols = RegexOutline.symbols(in: text, language: .perl)
        XCTAssertEqual(symbols.map(\.name), ["a", "b"])
        XCTAssertEqual(symbols.first?.scopeRange.map { NSMaxRange($0) }, (text as NSString).range(of: "}\nsub b").location + 1)
    }

    // MARK: - Data files

    func testDataFilesOutlineTheirKeysToThreeLevels() throws {
        let json = "{\"a\": {\"b\": {\"c\": {\"d\": 1}}}, \"e\": [ {\"f\": 1} ]}"
        let symbols = TreeSitterHighlighter.keyTreeSymbols(in: json, language: .json)
        XCTAssertEqual(symbols.map(\.name), ["a", "b", "c", "e", "f"], "d is the fourth level; an array adds none")
        let roots = OutlineTree.build(from: symbols)
        XCTAssertEqual(roots.map(\.symbol.name), ["a", "e"])
        XCTAssertEqual(roots.first?.children.first?.children.map(\.symbol.name), ["c"])
        XCTAssertEqual(TreeSitterHighlighter.keyTreeSymbols(in: json, language: .json, limit: 2).count, 2)
        assertRun(["inventory", "  meta"], in: try outline("xml"))
        XCTAssertFalse(try outline("yaml").isEmpty)
        XCTAssertFalse(try outline("toml").isEmpty)
        let toml = TreeSitterHighlighter.keyTreeSymbols(in: "[server]\nport = 80\n[[db]]\nname = \"x\"\n", language: .toml)
        XCTAssertEqual(toml.map(\.name), ["server", "port", "db", "name"])
        XCTAssertEqual(OutlineTree.build(from: toml).map(\.symbol.name), ["server", "db"])
    }

    func testPropertyListKeysNestByDictionary() {
        let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <plist version="1.0"><dict>
              <key>Name</key><string>x</string>
              <key>Build</key><dict><key>Debug</key><true/></dict>
            </dict></plist>
            """
        let roots = OutlineTree.build(from: PlistStructure.outlineSymbols(in: plist))
        XCTAssertEqual(roots.map(\.symbol.name), ["Name", "Build"])
        XCTAssertEqual(roots.last?.children.map(\.symbol.name), ["Debug"])
    }

    // MARK: - Every showcase

    /// Languages whose showcase has nothing an outline should list: data without names, prose
    /// without headings, diagrams, query languages, and templates that embed other languages.
    static let allowedEmpty: Set<String> = [
        "astro", "crontab", "csv", "cue", "cypher", "dhall", "dot", "edgeql", "ejs", "erb", "freemarker", "gettext",
        "gitattributes", "gitcommit", "gitignore", "gomod", "haml", "handlebars", "hosts", "html", "jsonlines",
        "jsonnet", "jsp", "kdl", "lex", "log", "manifest", "marko", "mermaid", "meson", "mustache", "nix",
        "piprequirements", "plaintext", "plantuml", "prql", "pug", "razor", "restructuredtext", "ron", "slim",
        "smalltalk", "smarty", "sparql", "svelte", "tsv", "turtle", "velocity", "vue", "sqlite",
    ]

    /// Every language folder in the corpus produces an outline unless it is allowed to be empty —
    /// and an allowed-empty one that starts producing one must leave the list.
    func testEveryShowcaseWithDeclarationsHasAnOutline() throws {
        let root = corpus.appendingPathComponent("languages")
        guard let dirs = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey]) else {
            throw XCTSkip("corpus not cloned")
        }
        var missing: [String] = [], stale: [String] = []
        for dir in dirs where dir.hasDirectoryPath && dir.lastPathComponent != "picker-only" {
            guard
                let file = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                    .first(where: { !$0.lastPathComponent.hasPrefix("README") }),
                let text = try? String(contentsOf: file, encoding: .utf8)
            else { continue }
            let language = Language.detect(for: file)
            if language == .markdown || language == .css { continue }  // covered by their own tests
            let count = DocumentOutline.symbols(parsing: text, language: language).count
            let name = dir.lastPathComponent
            if count == 0, !Self.allowedEmpty.contains(name) { missing.append(name) }
            if count > 0, Self.allowedEmpty.contains(name) { stale.append(name) }
        }
        XCTAssertEqual(missing.sorted(), [], "showcases with declarations but no outline")
        XCTAssertEqual(stale.sorted(), [], "outlined now: take them off the allowed-empty list")
    }
}
