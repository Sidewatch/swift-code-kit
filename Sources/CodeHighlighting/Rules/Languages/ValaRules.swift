//
//  ValaRules.swift
//  CodeHighlighting
//
//  The regex rule table for Vala.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Vala: C's comments and character literals, `"""…"""` verbatim strings across lines, `@"…"` string
/// templates, the Vala keywords (`signal`, `owned`, `errordomain`, `requires`), and the GLib-sized
/// numeric types (`int32`, `uint8`, `unichar`).
extension RuleTables {
    static let vala: [(String, TokenKind)] =
        [("\"\"\"[\\s\\S]*?\"\"\"", .string)]
        + cDialect(
            keywords: [
                "abstract", "as", "async", "base", "break", "case", "catch", "class", "const", "construct", "continue", "default",
                "delegate", "delete", "do", "dynamic", "else", "ensures", "enum", "errordomain", "extern", "finally", "for",
                "foreach", "get", "global", "if", "in", "inline", "interface", "internal", "is", "lock", "namespace", "new",
                "out", "override", "owned", "params", "partial", "private", "protected", "public", "ref", "requires", "return",
                "set", "signal", "sizeof", "static", "struct", "switch", "this", "throw", "throws", "try", "typeof", "unlock",
                "unowned", "using", "var", "virtual", "void", "volatile", "weak", "while", "with", "yield",
            ],
            types: [
                "bool", "char", "uchar", "int", "uint", "short", "ushort", "long", "ulong", "size_t", "ssize_t", "int8", "uint8",
                "int16", "uint16", "int32", "uint32", "int64", "uint64", "unichar", "float", "double", "string", "time_t",
            ],
            constants: ["true", "false", "null"], stringPrefix: "@?"
        )
}
