//
//  OraclePassR1Tests.swift
//  CodeHighlightingTests
//
//  Interpolated strings on the regex tier: one helper paints a literal in pieces around its holes, so the code
//  in a hole keeps its colours in every language that interpolates; and MDX's reference links.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class OraclePassR1Tests: XCTestCase {
    /// One colour per role, so a painted colour reads back as exactly one role.
    private struct Colours: TokenColorProviding {
        static let roles: [(TokenKind, String)] = [
            (.comment, "comment"), (.string, "string"), (.keyword, "keyword"), (.type, "type"), (.number, "number"),
            (.function, "function"), (.variable, "variable"), (.identifier, "identifier"), (.property, "property"),
            (.attribute, "attribute"),
        ]
        let foreground = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.9, alpha: 1)
        func color(for kind: TokenKind) -> NSColor {
            let index = Self.roles.firstIndex { $0.0 == kind } ?? 0
            return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
        }
        func role(of colour: NSColor?) -> String {
            guard let c = colour, c != foreground else { return "plain" }
            return Self.roles.first { color(for: $0.0) == c }?.1 ?? "other"
        }
    }

    /// The role every character of the `occurrence`-th `marker` in `text` is painted, "mixed" when they differ.
    private func role(_ marker: String, in text: String, _ language: Language, _ occurrence: Int = 1) -> String {
        let colours = Colours()
        let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colours.foreground])
        SyntaxHighlighter(language: language, colors: colours).highlight(storage, in: NSRange(location: 0, length: storage.length))
        let ns = text as NSString
        var r = NSRange(location: 0, length: 0)
        for _ in 0..<occurrence {
            let from = NSMaxRange(r)
            r = ns.range(of: marker, range: NSRange(location: from, length: ns.length - from))
            if r.location == NSNotFound { return "missing \(marker)" }
        }
        let roles = Set(
            (r.location..<NSMaxRange(r)).map {
                colours.role(of: storage.attribute(.foregroundColor, at: $0, effectiveRange: nil) as? NSColor)
            })
        return roles.count == 1 ? roles.first! : "mixed"
    }

    // MARK: The pieces

    func testAnotherFormsLiteralIsNoPlaceForATail() {
        // The scan for `"…"` strings steps over the `'…'` one; a tail after its hole's `}` must not run on.
        let text = "$single: 'one #{\"two\"}';\n$next: 1;\n"
        XCTAssertEqual(role("';", in: text, .scss), "mixed")
        XCTAssertEqual(role("'", in: text, .scss, 2), "string")
        XCTAssertEqual(role(";", in: text, .scss), "plain")
    }

    func testTextAfterAHoleContinuesOnTheNextLines() {
        let text = "const s = `a ${x} b\n  c d\n  e`;\nconst n = 1;\n"
        XCTAssertEqual(role(" b", in: text, .marko), "string")
        XCTAssertEqual(role("c d", in: text, .marko), "string")
        XCTAssertEqual(role("e`", in: text, .marko), "string")
        XCTAssertNotEqual(role("n = ", in: text, .marko), "string")
    }

    func testALineBreakInsideAHoleContinuesNoText() {
        let text = "const s = `a ${\n  count\n} b`;\n"
        XCTAssertNotEqual(role("count", in: text, .marko), "string")
        XCTAssertEqual(role(" b`", in: text, .marko), "string")
    }

    func testAHoleBesideAClosedLiteralContinuesNothing() {
        let text = "x=\"$a\"${b}\nfoo bar\necho \"z\"\n"
        XCTAssertNotEqual(role("foo bar", in: text, .zsh), "string")
    }

    func testAStringInsideAHoleIsPaintedInPiecesToo() {
        let text = "var s = 'nested ${'inner ${1 + 2}' + x}';\n"
        XCTAssertEqual(role("'inner ", in: text, .haxe), "string")
        XCTAssertEqual(role("2", in: text, .haxe), "number")
        XCTAssertEqual(role("'", in: text, .haxe, 3), "string", "the inner literal's close, a tail inside the outer hole")
        XCTAssertNotEqual(role("x", in: text, .haxe), "string")
        XCTAssertEqual(role("';", in: text, .haxe), "mixed")
    }

    func testEveryPatternCompilesAndEveryScopeDecodes() {
        // A pattern that does not compile is skipped, and a scope marker that does not decode leaves its rule
        // unscoped: both silently.
        for language in Language.allCases {
            for (pattern, _) in RuleTables.table(for: language) {
                let (_, body) = RuleScope.split(pattern)
                XCTAssertFalse(body.hasPrefix("(?#in:"), "\(language): a scope marker that does not decode")
                XCTAssertNotNil(try? NSRegularExpression(pattern: body, options: .anchorsMatchLines), "\(language): \(body.prefix(80))")
            }
        }
    }

    // MARK: Languages

    func testRazorTellsCSharpTailsFromScriptTails() {
        let text = "@{ var s = $\"#{o.Number} ({o.Status})\"; }\n<script>\nconst t = `${a} \"b\" c`;\n</script>\n"
        XCTAssertEqual(role(" (", in: text, .razor), "string")
        XCTAssertNotEqual(role("Status", in: text, .razor), "string")
        XCTAssertEqual(role(" \"b\" c`", in: text, .razor), "string")
    }

    func testNixStringsIndentedStringsAndPathsKeepTheirHoles() {
        let text = "{\n  a = \"v ${x} w\";\n  b = ''\n    t ${y} u\n  '';\n  c = ./src/${n}/f.nix;\n  d = \"${p.${s}.q}/bin\";\n}\n"
        XCTAssertNotEqual(role("x", in: text, .nix), "string")
        XCTAssertEqual(role(" w\"", in: text, .nix), "string")
        XCTAssertNotEqual(role("y", in: text, .nix), "string")
        XCTAssertEqual(role(" u", in: text, .nix), "string")
        XCTAssertNotEqual(role("n}", in: text, .nix), "string")
        XCTAssertEqual(role("/f.nix", in: text, .nix), "string")
        XCTAssertNotEqual(role(".q", in: text, .nix), "string", "a hole nested in a hole ends no hole")
        XCTAssertEqual(role("/bin\"", in: text, .nix), "string")
    }

    func testCUEInterpolationsInEveryStringForm() {
        let text = "a: \"t \\(x + 1) u\"\nb: #\"r \\#(y) s\"#\nc: \"\"\"\n\tline \\(z)\n\t\"\"\"\nd: 1\n"
        XCTAssertEqual(role("1", in: text, .cue), "number")
        XCTAssertEqual(role(" u\"", in: text, .cue), "string")
        XCTAssertNotEqual(role("y", in: text, .cue), "string")
        XCTAssertEqual(role(" s\"#", in: text, .cue), "string")
        XCTAssertNotEqual(role("z", in: text, .cue), "string")
        XCTAssertEqual(role("\t\"\"\"", in: text, .cue), "string")
    }

    func testDotenvExpansionBracesKeepTheKeywordColour() {
        let text = "A=\"v ${B} w\"\n"
        XCTAssertEqual(role("${", in: text, .dotenv), "keyword")
        XCTAssertEqual(role("B", in: text, .dotenv), "string")
        XCTAssertEqual(role("}", in: text, .dotenv), "keyword")
        XCTAssertEqual(role(" w\"", in: text, .dotenv), "string")
    }

    func testPRQLFormatStringHoles() {
        let text = "derive {a = f\"x {rate} y\", b = s\"lower({name})\"}\n"
        XCTAssertNotEqual(role("rate", in: text, .prql), "string")
        XCTAssertEqual(role(" y\"", in: text, .prql), "string")
        XCTAssertNotEqual(role("name", in: text, .prql), "string")
    }

    func testCaddyfilePlaceholderInAQuotedArgument() {
        XCTAssertEqual(role("{host}", in: "respond \"hi from {host}\"\n", .caddyfile), "variable")
    }

    func testXQueryStringConstructorAndAttributeValueTemplates() {
        let text = "let $t := ``[a `{ $x }` b]``\nreturn <r n=\"{ $c }\" m='k-{ $d }'/>\n"
        XCTAssertNotEqual(role("$x", in: text, .xquery), "string")
        XCTAssertEqual(role(" b]``", in: text, .xquery), "string")
        XCTAssertNotEqual(role("$c", in: text, .xquery), "string")
        XCTAssertNotEqual(role("$d", in: text, .xquery), "string")
        XCTAssertEqual(role("'k-", in: text, .xquery), "string")
    }

    func testIdrisInterpolation() {
        XCTAssertNotEqual(role("name", in: "f name = \"Hi, \\{name}!\"\n", .idris, 2), "string")
    }

    func testElixirStringsHeredocsAndSigils() {
        let text = "a = \"x #{y} z\"\nb = \"\"\"\nh #{w} i\n\"\"\"\nc = ~r\"re#{v}\"i\n"
        XCTAssertNotEqual(role("y", in: text, .elixir), "string")
        XCTAssertEqual(role(" z\"", in: text, .elixir), "string")
        XCTAssertNotEqual(role("#", in: text, .elixir), "string", "the `#` of `#{` opens the hole, code like it")
        XCTAssertNotEqual(role("w", in: text, .elixir), "string")
        XCTAssertEqual(role(" i", in: text, .elixir), "string")
        XCTAssertNotEqual(role("v", in: text, .elixir), "string")
        XCTAssertEqual(role("\"i", in: text, .elixir), "string", "a sigil's modifiers")
    }

    func testSASMacroVariableInADoubleQuotedString() {
        let text = "title \"Report &title. for &&region\";\nfootnote 'no &ref';\n"
        XCTAssertNotEqual(role("&title.", in: text, .sas), "string")
        XCTAssertEqual(role(" for ", in: text, .sas), "string")
        XCTAssertEqual(role("'no &ref'", in: text, .sas), "string")
    }

    func testMakefileReferencesInsideAQuote() {
        let text = "all:\n\t@echo \"t=$@ d=$(<D) $$HOME x\"\n"
        XCTAssertNotEqual(role("$@", in: text, .makefile), "string")
        XCTAssertNotEqual(role("<D", in: text, .makefile), "string")
        XCTAssertEqual(role(" x\"", in: text, .makefile), "string")
    }

    func testNimFormatStringHoles() {
        let text = "let g = fmt\"q={m} t={m * 2:>8.2f}\"\n"
        XCTAssertNotEqual(role(":>8.2f", in: text, .nim), "string")
        XCTAssertEqual(role("\"", in: text, .nim, 2), "string")
    }

    func testStataMacrosInStringsAndCompoundStrings() {
        let text = "display \"a `x' b ${g} c\"\ndisplay `\"q \"in\" `y' r\"'\nif \"`f'\" != \"\" & regexm(\"`f'\", \"^s\") display \"s\"\n"
        XCTAssertNotEqual(role("x'", in: text, .stata), "string")
        XCTAssertNotEqual(role("g}", in: text, .stata), "string")
        XCTAssertEqual(role(" c\"", in: text, .stata), "string")
        XCTAssertNotEqual(role("y'", in: text, .stata), "string")
        XCTAssertEqual(role(" r\"'", in: text, .stata), "string")
        XCTAssertNotEqual(role("!=", in: text, .stata), "string", "a plain string after a macro ends at its quote")
    }

    func testShellCommandSubstitutionInAStringIsCode() {
        let text = "echo \"today $(date +%F) ok $((1 + 2))\"\n"
        XCTAssertNotEqual(role("date", in: text, .zsh), "string")
        XCTAssertEqual(role(" ok ", in: text, .zsh), "string")
        XCTAssertEqual(role("2", in: text, .zsh), "number")
    }

    func testPowerShellHereStringSubexpressions() {
        let text = "$h = @\"\nItems: $($Skus -join ', ') and \"quotes\"\n\"@\n$n = 1\n"
        XCTAssertNotEqual(role("-join", in: text, .powershell), "string")
        XCTAssertEqual(role(" and \"quotes\"", in: text, .powershell), "string")
        XCTAssertEqual(role("\"@", in: text, .powershell), "string")
        XCTAssertNotEqual(role("$n", in: text, .powershell), "string")
    }

    func testCoffeeScriptHeredocAndBlockRegexHoles() {
        let text = "s = \"\"\"\n  h #{x} and \"q\"\n\"\"\"\np = ///\n  ^ #{y} [a-z]+\n///g\n"
        XCTAssertNotEqual(role("x", in: text, .coffeescript), "string")
        XCTAssertEqual(role(" and \"q\"", in: text, .coffeescript), "string")
        XCTAssertNotEqual(role("y", in: text, .coffeescript), "string")
        XCTAssertEqual(role(" [a-z]+", in: text, .coffeescript), "string")
    }

    func testCrystalPercentLiteralAndRegexHoles() {
        let text = "a = %(p \"q\" #{n})\nb = %Q(w #{m})\nc = /#{k}-\\d+/\n"
        XCTAssertNotEqual(role("n}", in: text, .crystal), "string")
        XCTAssertNotEqual(role("m}", in: text, .crystal), "string")
        XCTAssertNotEqual(role("k}", in: text, .crystal), "string")
        XCTAssertEqual(role("-\\d+/", in: text, .crystal), "string")
    }

    func testHaxeNameHoleEndsAtTheNameEnd() {
        let text = "var s = 'Hello $name, ok';\n"
        XCTAssertNotEqual(role("name", in: text, .haxe), "string")
        XCTAssertEqual(role(", ok'", in: text, .haxe), "string")
    }

    func testJuliaCallInsideAHoleEndsNoHole() {
        let text = "s = \"f $(g(x) + 1) y\"\n"
        XCTAssertNotEqual(role("g", in: text, .julia), "string")
        XCTAssertEqual(role("1", in: text, .julia), "number")
        XCTAssertEqual(role(" y\"", in: text, .julia), "string")
    }

    // MARK: MDX links

    func testMDXShortcutReferencesAndAngleDestinations() {
        let text =
            "See [full][ref], [shortcut] and ![pic].\n\n- [x] done\n\n{[1, 2].join(\"-\")}\n\n[ref]: <https://example.com/a b> 'Title'\n"
        XCTAssertEqual(role("[", in: text, .mdx, 3), "string", "a shortcut reference's bracket")
        XCTAssertEqual(role("![", in: text, .mdx), "string")
        XCTAssertEqual(role("[x]", in: text, .mdx), "keyword", "a task box")
        XCTAssertNotEqual(role("[", in: text, .mdx, 6), "string", "a JavaScript array")
        XCTAssertEqual(role("<https://example.com/a b>", in: text, .mdx), "string")
        XCTAssertEqual(role("'Title'", in: text, .mdx), "string")
    }
}
