//
//  WATRules.swift
//  CodeHighlighting
//
//  The regex rule table for the WebAssembly text format.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// WebAssembly text format (WAT): `;;` and nesting `(; ;)` comments, `"…"` strings with `\` escapes,
/// the module-field and block keywords (`module`, `func`, `param`, `result`, `block`, `then`), the
/// value and reference types, instructions (`i32.add`, `local.get`, `br_if`), and numbers with `_`
/// separators, hex floats (`0x1.8p3`), `inf` and `nan:0x…`. `$identifiers` stay plain, like every
/// table's identifiers. A large module is mostly these tokens and each paint costs more the more the
/// pass has painted, so a word is never matched inside an instruction or identifier (`local` in
/// `local.get`, `data` in `$data`) and the instructions are one rule.
extension RuleTables {
    /// The words as one alternation that no `$`, `.` or word character touches.
    private static func watWords(_ words: [String], _ kind: TokenKind) -> (String, TokenKind) {
        ("(?<![$.\\w])(?:" + words.joined(separator: "|") + ")(?![\\w.])", kind)
    }

    static let wat: [(String, TokenKind)] = [
        (";;.*$", .comment),
        nestedBlock("(;", ";)"),
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        watWords(
            [
                "module", "func", "param", "result", "local", "global", "memory", "table", "elem", "data", "type", "import",
                "export", "start", "block", "loop", "if", "then", "else", "end", "mut", "offset", "item", "declare", "rec",
                "sub", "final", "field", "struct", "array", "tag", "try", "try_table", "catch", "catch_ref", "catch_all",
                "catch_all_ref", "delegate", "throw", "throw_ref", "rethrow", "shared", "definition", "instance", "binary",
                "quote",
            ], .keyword),
        watWords(
            [
                "i32", "i64", "f32", "f64", "v128", "i8", "i16", "funcref", "externref", "anyref", "eqref", "i31ref", "structref",
                "arrayref", "nullref", "nullfuncref", "nullexternref", "exnref", "ref", "null", "func", "extern", "any", "eq",
                "i31", "none", "nofunc", "noextern", "exn",
            ], .type),
        // Instructions: the dotted ones (`i32.add`, `local.get`, `memory.copy`) and the control words.
        (
            "(?<![$.\\w])(?:[a-z][a-z0-9_]*(?:\\.[a-z0-9_]+)+(?:/[a-z0-9_]+)?|"
                + "unreachable|nop|br|br_if|br_table|br_on_null|br_on_non_null|br_on_cast|br_on_cast_fail|return|call|"
                + "call_indirect|call_ref|return_call|return_call_indirect|return_call_ref|drop|select)(?![\\w.])",
            .function
        ),
        (
            "(?<![\\w$.])[+-]?(?:0x[0-9a-fA-F][0-9a-fA-F_]*(?:\\.[0-9a-fA-F_]*)?(?:[pP][+-]?\\d[\\d_]*)?|\\d[\\d_]*(?:\\.[\\d_]*)?(?:[eE][+-]?\\d[\\d_]*)?|inf|nan(?::0x[0-9a-fA-F_]+)?)(?![\\w.])",
            .number
        ),
    ]
}
