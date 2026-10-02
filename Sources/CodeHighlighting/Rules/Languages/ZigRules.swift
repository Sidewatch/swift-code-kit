//
//  ZigRules.swift
//  CodeHighlighting
//
//  The regex rule table for Zig.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Zig: `//`, `///` and `//!` comments (Zig has no block comment), `"…"` strings that end at the line,
/// `\\` multiline string lines, `'x'` character literals, the Zig keywords (a keyword before `(` stays a
/// keyword), `@builtin` calls, the primitive types — any `i7`/`u24` width among them — and numbers.
extension RuleTables {
    static let zig: [(String, TokenKind)] = [
        lineComment,
        ("\\\\\\\\.*$", .string),
        ("\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        ("'(?:[^'\\\\\\n]|\\\\(?:x[0-9a-fA-F]{2}|u\\{[0-9a-fA-F]+\\}|.))'", .string),
        callee,
        keywords([
            "addrspace", "align", "allowzero", "and", "anyframe", "anytype", "asm", "async", "await", "break", "callconv",
            "catch", "comptime", "const", "continue", "defer", "else", "enum", "errdefer", "error", "export", "extern",
            "fn", "for", "if", "inline", "linksection", "noalias", "noinline", "nosuspend", "opaque", "or", "orelse",
            "packed", "pub", "resume", "return", "struct", "suspend", "switch", "test", "threadlocal", "try", "union",
            "unreachable", "usingnamespace", "var", "volatile", "while",
        ]),
        ("@[A-Za-z_]\\w*", .function),
        constants(["true", "false", "null", "undefined"]),
        (
            "\\b(?:[iu]\\d+|isize|usize|c_char|c_short|c_ushort|c_int|c_uint|c_long|c_ulong|c_longlong|c_ulonglong|c_longdouble|f16|f32|f64|f80|f128|bool|void|noreturn|type|anyerror|comptime_int|comptime_float|anyopaque)\\b",
            .type
        ),
        decimal,
    ]
}
