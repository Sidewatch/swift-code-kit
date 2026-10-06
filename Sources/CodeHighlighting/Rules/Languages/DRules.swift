//
//  DRules.swift
//  CodeHighlighting
//
//  The regex rule table for D.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// D: every string form — `"…"` with a `c`/`w`/`d` suffix, `r"…"` and `` `…` `` WYSIWYG, `x"…"` hex,
/// `q"(…)"` / `q"[…]"` / `q"{…}"` / `q"<…>"` delimited, `q"EOS … EOS"` heredoc, the `q{` of a token string (whose contents are D tokens, painted as code) —
/// `'c'` characters, the language's keywords and basic types. A call is any other name before `(`, so
/// `if (`, `foreach (` and `assert(` stay keywords.
extension RuleTables {
    static let d: [(String, TokenKind)] = [
        ("q\"(\\w+)\\n[\\s\\S]*?\\n\\1\"", .string),
        ("q\"\\((?:[^()]|\\([^()]*\\))*\\)\"|q\"\\[[^\\]]*\\]\"|q\"\\{[^}]*\\}\"|q\"<[^>]*>\"", .string),
        ("q\\{", .string),
        ("\\b[rx]\"[^\"]*\"[cwd]?", .string),
        ("`[^`]*`[cwd]?", .string),
        ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"[cwd]?", .string),
        ("'(?:\\\\[^'\\n]+|[^'\\\\\\n])'", .string),
        // A call paints its name only, and never a keyword's: two rules painting the same characters, and a
        // paint over the `(`, are what slow a large file down.
        ("(?!" + wordTrie(dKeywords, .keyword).0 + ")\\b[A-Za-z_]\\w*(?=[ \\t]*\\()", .function),
        wordTrie(dKeywords, .keyword),
        wordTrie(
            [
                "void", "bool", "byte", "ubyte", "short", "ushort", "int", "uint", "long", "ulong", "cent", "ucent", "char",
                "wchar", "dchar", "float", "double", "real", "ifloat", "idouble", "ireal", "cfloat", "cdouble", "creal",
                "string", "wstring", "dstring", "size_t", "ptrdiff_t",
            ],
            .type
        ),
        constants(["true", "false", "null"]),
        ("\\b0[xX][0-9a-fA-F_]*(?:\\.[0-9a-fA-F_]*)?[pP][+-]?\\d+\\b", .number),
        decimal,
    ]

    /// The keywords of D.
    static let dKeywords = [
        "abstract", "alias", "align", "asm", "assert", "auto", "body", "break", "case", "cast", "catch", "class", "const",
        "continue", "debug", "default", "delegate", "delete", "deprecated", "do", "else", "enum", "export", "extern",
        "final", "finally", "for", "foreach", "foreach_reverse", "function", "goto", "if", "immutable", "import", "in",
        "inout", "interface", "invariant", "is", "lazy", "macro", "mixin", "module", "new", "nothrow", "out",
        "override", "package", "pragma", "private", "protected", "public", "pure", "ref", "return", "scope", "shared",
        "static", "struct", "super", "switch", "synchronized", "template", "this", "throw", "try", "typeid", "typeof",
        "union", "unittest", "version", "while", "with", "__FILE__", "__FILE_FULL_PATH__", "__MODULE__", "__LINE__",
        "__FUNCTION__", "__PRETTY_FUNCTION__", "__gshared", "__traits", "__vector", "__parameters",
    ]
}
