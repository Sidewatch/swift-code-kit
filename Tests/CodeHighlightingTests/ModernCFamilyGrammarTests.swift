//
//  ModernCFamilyGrammarTests.swift
//  CodeHighlightingTests
//
//  The vendored C, C++ and Java grammars parse C23, C++23/26 and Java 25.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import XCTest
import CodeLanguage
@testable import CodeHighlighting

/// Upstream tree-sitter-c v0.24.2, tree-sitter-cpp (main, Sep 2026) and tree-sitter-java (main) produced ERROR
/// nodes on each of these. The local patches (`Grammars/tree-sitter-{c,cpp,java}/sidewatch-*.patch`) fix them;
/// this pins it, so re-vendoring an unpatched upstream fails here.
final class ModernCFamilyGrammarTests: XCTestCase {
    static let c: [(String, String)] = [
        ("typeof", "typeof(1 + 2) x = 3; typeof_unqual(x) y = x;"),
        ("auto inference", "auto z = 3.0;"),
        ("_BitInt", "_BitInt(24) a = 5wb; unsigned _BitInt(8) b = 3uwb;"),
        ("enum underlying type", "enum Colour : unsigned char { RED, GREEN };"),
        ("#embed", "static const unsigned char logo[] = {\n#embed \"logo.png\"\n};"),
        ("__has_include", "#if __has_include(<stdio.h>)\n#include <stdio.h>\n#endif"),
        ("_Thread_local", "_Thread_local int c2;"),
        ("_Complex", "_Complex double z; double _Complex w;"),
        ("_Pragma", "_Pragma(\"once\")"),
        ("case range", "void f(int x) { switch (x) { case 1 ... 3: break; } }"),
        ("attribute after *", "int *[[gnu::unused]] p;"),
        ("__declspec with arguments", "__declspec(align(16)) struct S { int x; };"),
        ("delimited escapes", "const char *s = \"\\x{41}\\N{LATIN SMALL LETTER A}\";"),
        ("computed goto", "void f(void) { void *t = &&done; goto *t; done: return; }"),
    ]
    static let cpp: [(String, String)] = [
        ("if consteval", "constexpr int f() { if consteval { return 1; } else { return 2; } }"),
        ("if !consteval", "constexpr int f() { if !consteval { return 1; } return 2; }"),
        ("pack indexing", "template <typename... Ts> using First = Ts...[0];"),
        ("contracts", "int f(int x) pre(x > 0) post(r: r > 0);"),
        ("structured binding attribute", "auto [a [[maybe_unused]], b] = pair;"),
        ("explicit instantiation", "template class Ring<int, 4>;\nextern template class Ring<long, 4>;"),
        ("friend attribute", "struct S { [[maybe_unused]] friend void f(); };"),
        ("#embed", "const unsigned char d[] = {\n#embed \"data.bin\"\n};"),
        ("delimited escapes", "auto s = \"\\x{41}\\o{101}\\u{1F4E6}\";"),
        ("delete with a reason", "struct S { S(const S &) = delete(\"not copyable\"); };"),
        ("pointer-to-member field", "struct S { int Widget::* field; int (Widget::*method)() const; };"),
        ("pointer-to-member typedef", "typedef int Widget::* MemberPtr;"),
        ("->* operator", "int f(Widget *p, int Widget::* m) { return p->*m + 1; }"),
    ]
    static let java: [(String, String)] = [
        ("import module", "import module java.base;\nclass A {}"),
        ("flexible constructor body", "class A extends B { A(int x) { if (x < 0) throw new IllegalArgumentException(); super(x); } }"),
        ("qualified record pattern", "class A { void f(Object o) { if (o instanceof Shapes.Point(var x, var y)) {} } }"),
        ("final type pattern", "class A { int f(Object o) { return switch (o) { case final String s -> 1; default -> 0; }; } }"),
    ]

    private func failing(_ cases: [(String, String)], _ language: Language) -> [String] {
        cases.filter { TreeSitterHighlighter.parseErrorCount(in: $0.1, language: language) != 0 }.map(\.0)
    }

    func testC23ParsesWithoutErrors() { XCTAssertEqual(failing(Self.c, .c), []) }
    func testCpp23And26ParseWithoutErrors() { XCTAssertEqual(failing(Self.cpp, .cpp), []) }
    func testJava25ParsesWithoutErrors() { XCTAssertEqual(failing(Self.java, .java), []) }

    /// Upstream had `= delete` only inside a class: at namespace scope it read the plain form with a MISSING
    /// operand and the reason form as a `delete` expression initialising a variable.
    func testDeleteOutsideAClassIsADefinition() throws {
        for code in ["void f(int) = delete;", "void g(double) = delete(\"use f\");"] {
            let tree = try XCTUnwrap(TreeSitterHighlighter.syntaxTree(of: code, language: .cpp))
            XCTAssertTrue(tree.hasPrefix("(translation_unit (function_definition"), tree)
            XCTAssertTrue(tree.contains("(delete_method_clause"), tree)
            XCTAssertFalse(tree.contains("MISSING"), tree)
        }
    }

    /// Upstream read `= default` on a friend as an initialiser naming a variable called `default`.
    func testFriendDefaultIsADefinition() throws {
        let code = "struct A { friend auto operator<=>(A const &, A const &) = default; };"
        let tree = try XCTUnwrap(TreeSitterHighlighter.syntaxTree(of: code, language: .cpp))
        XCTAssertTrue(tree.contains("(friend_declaration (function_definition"), tree)
        XCTAssertTrue(tree.contains("(default_method_clause)"), tree)
    }

    /// Plain pack expansions must still parse after `...[` became pack indexing.
    func testPackExpansionsStillParse() {
        let code = "template <typename... Args> void g(Args... args) { f(args...); container<A, B, C...> t; }"
        XCTAssertEqual(TreeSitterHighlighter.parseErrorCount(in: code, language: .cpp), 0)
    }
}
