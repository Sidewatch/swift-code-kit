//
//  LuauRulesTests.swift
//  CodeHighlightingTests
//
//  Luau as luau.org's grammar and lexer define it: comments and long brackets of any level, the three string
//  forms, the contextual keywords, types, generic calls and numbers; and its outline.
//
//  Created by David Sherlock on 10/27/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CodeLanguage
import XCTest

@testable import CodeHighlighting

@MainActor
final class LuauRulesTests: XCTestCase {
    func testLongCommentsOfAnyLevelEndWhereTheirLevelCloses() {
        let painted = PaintedKinds("--[==[ level two with ]] inside ]==]\nlocal x = 1 --[[ ends ]] + 2\n--!strict\n", .luau)
        XCTAssertEqual(Set(painted.kinds(along: "--[==[ level two with ]] inside ]==]")), [.comment])
        XCTAssertEqual(painted.kind("local"), .keyword)
        XCTAssertEqual(painted.kind("+ 2", 2), .number, "code after a long comment that ends mid-line is code")
        XCTAssertEqual(painted.kind("--!strict"), .comment, "a directive is a comment")
    }

    func testStringsQuotedLongAndBacktickWithHoles() {
        let painted = PaintedKinds(
            "local a = 'it\\'s'\nlocal b = [==[with ]] inside]==]\nlocal c = `{name} has {count + 1} points`\n"
                + "local d = `outer {`inner {n}`} done`\nlocal g = `a {`}`} b`\nlocal e = \"open\nlocal f = \"x\"\n", .luau)
        XCTAssertEqual(Set(painted.kinds(along: "'it\\'s'")), [.string])
        XCTAssertEqual(Set(painted.kinds(along: "[==[with ]] inside]==]")), [.string])
        XCTAssertEqual(painted.kind(" has "), .string)
        XCTAssertNil(painted.kind("count"), "a hole holds code")
        XCTAssertEqual(painted.kind("1}"), .number)
        XCTAssertEqual(painted.kind("inner"), .string, "a backtick string inside a hole")
        XCTAssertNil(painted.kind("{n}", 1))
        XCTAssertEqual(painted.kind(" done"), .string, "the outer string resumes after the hole")
        XCTAssertNil(painted.kind("`}`}", 3), "the brace after a backtick string in a hole closes the hole")
        XCTAssertEqual(painted.kind("local f"), .keyword, "a raw line break ends a quoted string")
    }

    func testContextualKeywordsOnlyWhereTheyDeclare() {
        let painted = PaintedKinds(
            "export type Shape = { read name: string, write count: number }\nlocal kind = type(x)\nlocal read = 1\ncontinue\n", .luau)
        XCTAssertEqual(painted.kind("export"), .keyword)
        XCTAssertEqual(painted.kind("type Shape"), .keyword)
        XCTAssertEqual(painted.kind("Shape"), .type)
        XCTAssertEqual(painted.kind("read name"), .keyword)
        XCTAssertEqual(painted.kind("write count"), .keyword)
        XCTAssertEqual(painted.kind("type(x)"), .function, "the `type` function is called, not a declaration")
        XCTAssertNil(painted.kind("read = 1"), "a variable named read")
        XCTAssertEqual(painted.kind("continue"), .keyword)
    }

    func testTheNameATypeDeclaresIsATypeWhateverItsCase() {
        let painted = PaintedKinds("type point = { x: number }\n", .luau)
        XCTAssertEqual(painted.kind("point"), .type)
        XCTAssertEqual(painted.kind("type"), .keyword)
    }

    func testBuiltInTypesInTypePositionsOnly() {
        let painted = PaintedKinds(
            "local n: number = 0\nlocal function f(): string end\nlocal s = string.format(\"%d\", n :: any)\n", .luau)
        XCTAssertEqual(painted.kind("number"), .type)
        XCTAssertEqual(painted.kind("string end"), .type, "after a return arrow's colon")
        XCTAssertNil(painted.kind("string.format"), "the string library is not a type")
        XCTAssertEqual(painted.kind("any"), .type, "after a cast")
    }

    func testGenericCallsAreCallsAndComparisonsAreNot() {
        let painted = PaintedKinds("local w = wrap<T>(value)\nlocal p = pair<K, V...>(a)\nif a < b and c > (d) then end\n", .luau)
        XCTAssertEqual(painted.kind("wrap"), .function)
        XCTAssertEqual(painted.kind("pair"), .function)
        XCTAssertNil(painted.kind("a < b"), "a comparison before a bracket is not a call")
    }

    func testNumbersAsTheLexerReadsThem() {
        let painted = PaintedKinds("local n = { 0b1010, 0xFF, 1_000_000, .5, 1e-3, 3.14 }\nlocal x1 = nil\n", .luau)
        for literal in ["0b1010", "0xFF", "1_000_000", ".5", "1e-3", "3.14"] {
            XCTAssertEqual(Set(painted.kinds(along: literal)), [.number], literal)
        }
        XCTAssertNil(painted.kind("x1", 1), "a digit inside a name")
        XCTAssertEqual(painted.kind("nil"), .number, "a constant wears the number colour")
    }

    func testAttributes() {
        let painted = PaintedKinds("@native\nlocal function f() end\n@[deprecated] local function g() end\n", .luau)
        XCTAssertEqual(painted.kind("@native"), .attribute)
        XCTAssertEqual(painted.kind("@[deprecated", 2), .attribute)
    }

    func testTheOutlineNamesFunctionsWholeAndTypes() {
        let text = """
            export type Shape = { sides: number }
            local Point = {}
            function Point.new(x: number): Point
            \tlocal function helper() end
            \treturn helper
            end
            function Point:length(): number
            end
            @native local function double(n: number): number
            end
            type function Keys(t)
            end
            """
        let symbols = RegexOutline.symbols(in: text, language: .luau)
        XCTAssertEqual(symbols.map(\.name), ["Shape", "Point.new", "helper", "Point:length", "double", "Keys"])
        XCTAssertEqual(symbols.map(\.kind), [.type, .function, .function, .function, .function, .type])
        let helper = (text as NSString).range(of: "helper").location
        XCTAssertTrue(symbols[1].scopeRange.map { NSLocationInRange(helper, $0) } ?? false, "a local function nests in its function")
    }
}
