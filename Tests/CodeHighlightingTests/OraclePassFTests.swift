//
//  OraclePassFTests.swift
//  CodeHighlightingTests
//
//  The shells, scripting, hardware and legacy languages on the regex tier paint what VS Code and Pygments agree
//  on: Nushell's commands and bare words, Just's recipe headers, interpolation holes that stay code, declared
//  names, keyword lists and number forms.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class OraclePassFTests: XCTestCase {
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

    // MARK: Nushell

    func testNushellCommandsBareWordsAndOperators() {
        let text = "ls | where size > 1kb | sort-by modified\nlet bare = hello-world\nopen orders.csv | math sum\n"
        XCTAssertEqual(role("ls", in: text, .nushell), "keyword", "a built-in command")
        XCTAssertEqual(role("hello-world", in: text, .nushell), "type", "an external command")
        XCTAssertEqual(role("size", in: text, .nushell), "string", "a bare-word argument")
        XCTAssertEqual(role("modified", in: text, .nushell), "string")
        XCTAssertEqual(role("orders.csv", in: text, .nushell), "string")
        XCTAssertEqual(role("|", in: text, .nushell), "keyword")
        XCTAssertEqual(role("=", in: text, .nushell), "keyword")
        XCTAssertEqual(role("sum", in: text, .nushell), "keyword", "a subcommand is part of the command's name")
        XCTAssertEqual(role("1kb", in: text, .nushell), "number")
    }

    func testNushellSignaturesFlagsAndUseLines() {
        let text = "def --env \"orders summary\" [file: path, --min (-m): float = 0.0] { cd $file }\nuse std/util *\n"
        XCTAssertEqual(role("orders summary", in: text, .nushell), "function", "a quoted command name is not a string")
        XCTAssertEqual(role("--env", in: text, .nushell), "keyword")
        XCTAssertEqual(role("path", in: text, .nushell), "type")
        XCTAssertEqual(role("float", in: text, .nushell), "type")
        XCTAssertEqual(role("--", in: text, .nushell, 2), "keyword", "a flag opens with a keyword")
        XCTAssertEqual(role("std/util", in: text, .nushell), "string")
        XCTAssertEqual(role("*", in: text, .nushell), "keyword")
    }

    // MARK: Just

    func testJustRecipeHeadersAndBodies() {
        let text = "_helper $VAR=\"value\": build\ntest *ARGS: build (pkg \"x\")\n    @echo {{ARGS}}\necho-done what:\n    x'raw'\n"
        XCTAssertEqual(role("_", in: text, .just), "keyword", "a private recipe's underscore")
        XCTAssertEqual(role("helper", in: text, .just), "function")
        XCTAssertEqual(role("*", in: text, .just), "keyword", "a variadic parameter's mark")
        XCTAssertEqual(role("build", in: text, .just, 2), "function", "a dependency")
        XCTAssertEqual(role("pkg", in: text, .just), "function")
        XCTAssertEqual(role("@", in: text, .just), "keyword")
        XCTAssertEqual(role("{{ARGS}}", in: text, .just), "string")
        XCTAssertEqual(role("echo-done", in: text, .just), "function", "a recipe name is never a shell word")
        XCTAssertEqual(role("x'raw'", in: text, .just), "string")
        let quoted = "body:\n    echo {{ \"}}\" }}\n# after\n"
        XCTAssertEqual(role("{{ \"}}\" }}", in: quoted, .just), "string", "a quote inside {{ }} holds its braces")
        XCTAssertEqual(role("# after", in: quoted, .just), "comment")
    }

    // MARK: ABAP

    func testABAPKeywordsMethodsPragmasAndTypes() {
        let text = "CLASS-DATA gv_x TYPE i READ-ONLY.\nINTERFACES lif_x.\nMETHOD lif_x~load.\nDATA x TYPE i ##NEEDED.\ntext = TEXT-001.\n"
        XCTAssertEqual(role("READ-ONLY", in: text, .abap), "keyword")
        XCTAssertEqual(role("INTERFACES", in: text, .abap), "keyword")
        XCTAssertEqual(role("load", in: text, .abap), "function", "the method a METHOD implements")
        XCTAssertEqual(role("lif_x", in: text, .abap, 2), "type")
        XCTAssertEqual(role("##NEEDED", in: text, .abap), "comment")
        XCTAssertEqual(role("NEEDED.", in: text, .abap), "mixed", "the statement's period is not part of the pragma")
        XCTAssertEqual(role("TEXT", in: text, .abap), "keyword", "a text symbol")
    }

    // MARK: Verilog / SystemVerilog

    func testVerilogKeywordsBeforeBracketsAndClassNames() {
        let text = "if (a) begin end\nclass stock_txn extends base_txn;\nbind top checker_inst u();\nstring s = \"\"\"multi\"\"\";\n"
        XCTAssertEqual(role("if", in: text, .systemverilog), "keyword", "a keyword before a bracket is no call")
        XCTAssertEqual(role("stock_txn", in: text, .systemverilog), "type")
        XCTAssertEqual(role("base_txn", in: text, .systemverilog), "type")
        XCTAssertEqual(role("bind", in: text, .systemverilog), "keyword")
        XCTAssertEqual(role("multi", in: text, .systemverilog), "string")
    }

    // MARK: VHDL

    func testVHDLDesignUnitNamesAreTypes() {
        let text = "architecture rtl of counter is\nbegin\nend architecture rtl;\n"
        XCTAssertEqual(role("rtl", in: text, .vhdl), "type")
        XCTAssertEqual(role("counter", in: text, .vhdl), "type")
        XCTAssertEqual(role("rtl", in: text, .vhdl, 2), "type")
    }

    // MARK: Assembly

    func testAssemblyNumbersDivisionAndSizedOperands() {
        let text = "    dw 0b1010_0101, 777o\n    dd 1.5\nx equ 4 / 2 // 3\n    mov rax, [qword 0x1000]\n"
        XCTAssertEqual(role("0b1010_0101", in: text, .assembly), "number")
        XCTAssertEqual(role("777o", in: text, .assembly), "number")
        XCTAssertEqual(role("1.5", in: text, .assembly), "number")
        XCTAssertNotEqual(role("// 3", in: text, .assembly), "comment", "NASM's // is signed division")
        XCTAssertEqual(role("qword", in: text, .assembly), "keyword")
    }

    // MARK: LLVM IR

    func testLLVMCharacterArraysAndNegativeNumbers() {
        let text = "@v = constant [2 x i8] c\"x\\00\"\n  %r = add i32 %a, -1\n  %o = atomicrmw umax ptr %p, i32 1 seq_cst\n"
        XCTAssertEqual(role("c", in: text, .llvm, 2), "keyword", "the c of c\"…\"")
        XCTAssertEqual(role("-1", in: text, .llvm), "number")
        XCTAssertEqual(role("umax", in: text, .llvm), "keyword")
    }

    // MARK: COBOL

    func testCOBOLDashedReservedWordsAreWhole() {
        let text = "       77  WS-INDEX PIC S9(4) COMP-5.\n           END-SEARCH\n       I-O-CONTROL.\n       01  N PIC N(4).\n"
        XCTAssertEqual(role("COMP-5", in: text, .cobol), "keyword")
        XCTAssertEqual(role("END-SEARCH", in: text, .cobol), "keyword")
        XCTAssertEqual(role("I-O-CONTROL", in: text, .cobol), "keyword")
        XCTAssertEqual(role("PIC N(4)", in: text, .cobol), "type")
    }

    // MARK: Fortran

    func testFortranDeclarationTypesAndBareDecimals() {
        let text = "  real(dp), parameter :: pi = 3.14\n  x = real(n)\n  print *, .5, 5.\n"
        XCTAssertEqual(role("real", in: text, .fortran), "type", "a declaration's type")
        XCTAssertEqual(role("real", in: text, .fortran, 2), "function", "the conversion")
        XCTAssertEqual(role(".5", in: text, .fortran), "number")
        XCTAssertEqual(role("5.", in: text, .fortran), "number")
    }

    // MARK: Ada

    func testAdaDeclaredNames() {
        let text = "procedure Swap is\nbegin\n   null;\nend Swap;\ntype Index is range 0 .. 9;\nfunction Ok return Boolean;\n"
        XCTAssertEqual(role("Swap", in: text, .ada), "function")
        XCTAssertEqual(role("Swap", in: text, .ada, 2), "function", "an end repeats the name")
        XCTAssertEqual(role("Index", in: text, .ada), "type")
        XCTAssertEqual(role("Boolean", in: text, .ada), "type")
    }

    // MARK: Pascal

    func testPascalRoutineNamesAndRoutineWords() {
        let text = "function TOrder.GetTotal: Currency;\nprocedure Read;\nclass operator In(A: Integer): Boolean;\nif X then Exit;\n"
        XCTAssertEqual(role("GetTotal", in: text, .pascal), "function")
        XCTAssertEqual(role("TOrder", in: text, .pascal), "type")
        XCTAssertEqual(role("Read", in: text, .pascal), "function", "a routine named like a directive")
        XCTAssertEqual(role("In", in: text, .pascal), "keyword", "an operator keeps its keyword name")
        XCTAssertEqual(role("Exit", in: text, .pascal), "keyword")
    }

    // MARK: Interpolation holes

    func testCoffeeScriptInterpolationHolesAreCode() {
        let text = "s = \"a #{n * 2} b\"\nt = \"x #{f(\"y\")} z\"\nr = `/\\d+/g`\n# done\n"
        XCTAssertEqual(role("a ", in: text, .coffeescript), "string")
        XCTAssertEqual(role("2", in: text, .coffeescript), "number", "the code in a hole")
        XCTAssertEqual(role(" b\"", in: text, .coffeescript), "string", "the text after a hole")
        XCTAssertEqual(role("\"y\"", in: text, .coffeescript), "string")
        XCTAssertEqual(role(" z\"", in: text, .coffeescript), "string")
        XCTAssertEqual(role("/\\d+/g", in: text, .coffeescript), "string", "a regex literal")
        XCTAssertEqual(role("# done", in: text, .coffeescript), "comment")
    }

    func testJuliaInterpolationNumbersAndPrefixedStrings() {
        let text = "s = \"n $(length(x) * 2) items\"\nr = raw\"C:\\\\x\"\nf = 2.5f0 + .5 + 4im\nT <: Real\n"
        XCTAssertEqual(role("*", in: text, .julia), "plain", "an operator in a hole after a nested call")
        XCTAssertEqual(role("2", in: text, .julia), "number")
        XCTAssertEqual(role(" items\"", in: text, .julia), "string")
        XCTAssertEqual(role("raw\"", in: text, .julia), "string", "a prefixed literal's prefix")
        XCTAssertEqual(role("2.5f0", in: text, .julia), "number")
        XCTAssertEqual(role(".5", in: text, .julia), "number")
        XCTAssertEqual(role("4im", in: text, .julia), "number")
        XCTAssertNotEqual(role(":", in: text, .julia, 2), "string", "<: is the subtype operator")
    }

    func testPowerShellSubexpressionsAndCaseInsensitiveWords() {
        let text = "$s = \"$($this.Sku) @ $($x.Name())\"\nfunction global:Helper { }\nWrite-Host 'x' -InformationAction Continue\n"
        XCTAssertEqual(role(" @ ", in: text, .powershell), "string")
        XCTAssertEqual(role("$this", in: text, .powershell), "type", "a subexpression is code")
        XCTAssertEqual(role("\"", in: text, .powershell, 2), "string", "the close after a method call's brackets")
        XCTAssertEqual(role("global", in: text, .powershell), "keyword")
        XCTAssertEqual(role("Continue", in: text, .powershell), "keyword")
    }

    func testShellExpansionsArithmeticAndEscapes() {
        let text = "echo \"${HOME:=/root} $((1 + 2)) $(date)\"\nx=hello\\ world\nlegacy=`uname -s`\n"
        XCTAssertEqual(role(":=", in: text, .sh), "plain", "a parameter expansion's operator")
        XCTAssertEqual(role("2", in: text, .sh), "number", "arithmetic")
        XCTAssertNotEqual(role("date", in: text, .sh), "string", "a command substitution is code")
        XCTAssertEqual(role("\\ ", in: text, .sh), "string")
        XCTAssertEqual(role("`", in: text, .sh), "string")
    }

    // MARK: Perl and Raku

    func testPerlHereDocumentsSubNamesAndTransliteration() {
        let text = "my $h = <<~EOT;\n    body\n    EOT\nsub describe { 1 }\nmy $r = ($l =~ tr/a-z//cdr);\nmy $d = <<>>;\n"
        XCTAssertEqual(role("<<~EOT", in: text, .perl), "string")
        XCTAssertEqual(role(";", in: text, .perl), "plain", "the rest of the marker's line is code")
        XCTAssertEqual(role("body", in: text, .perl), "string")
        XCTAssertEqual(role("describe", in: text, .perl), "function")
        XCTAssertNotEqual(role("cdr", in: text, .perl), "string", "a transliteration's flags")
        XCTAssertEqual(role("<<>>", in: text, .perl), "string")
    }

    func testRakuHyperOperatorsAndAbbreviatedPod() {
        let text = "my @s = (1, 2) <<+>> (3, 4);\n=defn Term\nDefinition text.\n\nsay 1;\n"
        XCTAssertNotEqual(role("<<+>>", in: text, .raku), "string", "a hyper operator, not a quote")
        XCTAssertEqual(role("Definition text.", in: text, .raku), "comment", "an abbreviated block runs to the blank line")
        XCTAssertNotEqual(role("say", in: text, .raku), "comment")
    }

    // MARK: Batch, Tcl, Vim script

    func testBatchRemAtSignAndPercents() {
        let text = "@rem a comment\nset /a t=7 %% 5\necho 100%%\n"
        XCTAssertNotEqual(role("@", in: text, .batch), "comment", "the echo-off @ is code")
        XCTAssertEqual(role("rem a comment", in: text, .batch), "comment")
        XCTAssertNotEqual(role("%%", in: text, .batch), "string", "modulo")
        XCTAssertEqual(role("%%", in: text, .batch, 2), "string", "an escaped percent")
    }

    func testTclNestedSubstitutionStringsAndNumbers() {
        let text = "puts \"a [string cat \"inner\" x] b\"\npackage provide inv 1.4.0\nincr n -5\n"
        XCTAssertEqual(role("inner", in: text, .tcl), "string")
        XCTAssertEqual(role(" b\"", in: text, .tcl), "string", "the string runs past the nested quotes")
        XCTAssertEqual(role("1.4.0", in: text, .tcl), "number")
        XCTAssertEqual(role("-5", in: text, .tcl), "number")
    }

    func testVimscriptCommandsPatternsAndSyntaxArguments() {
        let text = "g!/pat/normal! x\nsyntax region S start=/\"/ end=/\"/ oneline\nfold | foldopen\n"
        XCTAssertNotEqual(role("g!", in: text, .vimscript), "string", "the command letters")
        XCTAssertEqual(role("/pat/", in: text, .vimscript), "string")
        XCTAssertEqual(role("start", in: text, .vimscript), "keyword")
        XCTAssertEqual(role("/\"/", in: text, .vimscript), "string", "a region's pattern")
        XCTAssertEqual(role("oneline", in: text, .vimscript), "keyword")
        XCTAssertEqual(role("fold", in: text, .vimscript), "keyword")
    }

    // MARK: Small tables

    func testAppleScriptRDottedNamesRegoAndSmalltalk() {
        XCTAssertEqual(role("idle", in: "on idle\nend idle\n", .applescript), "function")
        XCTAssertEqual(role("terms", in: "using terms from application \"Finder\"\n", .applescript), "keyword")
        let r = "x <- ...length()\ny <- sys.function()\n"
        XCTAssertEqual(role("...length", in: r, .r), "function")
        XCTAssertEqual(role("sys.function", in: r, .r), "function")
        XCTAssertEqual(role("data", in: "import data.roles\n", .rego), "keyword")
        let st = "#(-7 2r1e4 1_000)\n"
        XCTAssertEqual(role("-7", in: st, .smalltalk), "number")
        XCTAssertEqual(role("2r1e4", in: st, .smalltalk), "number")
        XCTAssertEqual(role("1_000", in: st, .smalltalk), "number")
    }

    func testVisualBasicNumbersAndInterpolationMark() {
        XCTAssertNotEqual(role("$", in: "Return $\"{Sku} left\"\n", .vbnet), "string")
        let vbs = "x = 1.5E+3 : y = .5E-3\n"
        XCTAssertEqual(role("1.5E+3", in: vbs, .vbscript), "number")
        XCTAssertEqual(role(".5E-3", in: vbs, .vbscript), "number")
    }

    func testCMakeBracketArguments() {
        XCTAssertEqual(role("no ${x}", in: "set(A [=[no ${x}, no \\escapes]=])\n", .cmake), "string")
    }

    func testMakefileContinuationsEscapedHashesAndGroupedTargets() {
        let text = "a b &: c\nV = $(subst \\#,h,y)\nL = a \\\n  b\n"
        XCTAssertEqual(role("&", in: text, .makefile), "function", "a grouped target's &")
        XCTAssertEqual(role("\\#", in: text, .makefile), "string")
        XCTAssertEqual(role("\\", in: text, .makefile, 2), "string", "a continuation")
    }

    func testNimKeywordsBeforeBracketsAndRoutineNames() {
        let text = "template `!=`(a, b: untyped): untyped = not (a == b)\nproc swapIt[T](a: T) = discard\n"
        XCTAssertEqual(role("not", in: text, .nim), "keyword", "a keyword before a bracket is no call")
        XCTAssertEqual(role("`!=`", in: text, .nim), "function")
        XCTAssertEqual(role("swapIt", in: text, .nim), "function")
    }

    func testStataSubcommandWordsAndMergeTypes() {
        let text = "set more off\nfrlink m:1 sku, frame(d)\nestat vif\n"
        XCTAssertEqual(role("more", in: text, .stata), "keyword")
        XCTAssertEqual(role("m", in: text, .stata, 2), "keyword")
        XCTAssertEqual(role("vif", in: text, .stata), "keyword")
    }

    // MARK: Every pattern compiles

    func testEveryPatternOfThisGroupCompiles() {
        let languages: [Language] = [
            .nushell, .just, .makefile, .abap, .systemverilog, .verilog, .vhdl, .assembly, .llvm, .wat, .cobol, .fortran,
            .pascal, .ada, .julia, .coffeescript, .raku, .perl, .powershell, .sh, .zsh, .fish, .batch, .awk, .tcl, .vimscript,
            .stata, .r, .nim, .smalltalk, .applescript, .vbnet, .vbscript, .rego, .starlark, .sas, .cmake, .http,
        ]
        for language in languages {
            for (pattern, _) in RuleTables.table(for: language) {
                let (scopes, body) = RuleScope.split(pattern)
                XCTAssertFalse(body.hasPrefix("(?#in:"), "\(language): a scope marker that does not decode")
                XCTAssertNotNil(
                    try? NSRegularExpression(pattern: body, options: .anchorsMatchLines), "\(language): \(body.prefix(80))")
                XCTAssertTrue(scopes.allSatisfy { !$0.region.pattern.isEmpty })
            }
        }
    }
}
