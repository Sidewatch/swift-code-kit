//
//  CarbonRules.swift
//  CodeHighlighting
//
//  The regex rule table for Carbon.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Carbon: `"…"` strings, `'''…'''` block strings and their `#"…"#` / `#'''…'''#` raw forms, the
/// language's reserved words, sized number types (`i32`, `u8`, `f64`) as types; hex floats (`0x1.8p3`). Calls paint before
/// keywords, so `if (` and `match (` stay keywords.
extension RuleTables {
    static let carbon: [(String, TokenKind)] = [
        ("(#+)'''[\\s\\S]*?'''\\1", .string),
        ("(#+)\"[^\\n]*?\"\\1", .string),
        tripleSingleQuoted,
        doubleQuoted,
        ("'(?:\\\\[^'\\n]+|[^'\\\\\\n])'", .string),
        call,
        keywords([
            "abstract", "adapt", "addr", "alias", "and", "api", "as", "auto", "base", "break", "case", "choice", "class",
            "constraint", "continue", "default", "destructor", "else", "export", "extend", "extends", "final", "fn", "for", "forall",
            "friend", "if", "impl", "impls", "import", "in", "interface", "is", "let", "library", "like", "match", "namespace",
            "not", "observe", "or", "override", "package", "partial", "private", "protected", "require", "return",
            "returned", "Self", "self", "template", "then", "type", "var", "virtual", "where", "while",
        ]),
        types(["bool", "String", "[iuf]\\d+"]),
        constants(["true", "false"]),
        decimal,
        ("\\b0x[0-9A-Fa-f_]+\\.[0-9A-Fa-f_]+(?:p[+-]?\\d+)?", .number),  // a hex float, `0x1.8p3`
    ]
}
