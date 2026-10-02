//
//  HaxeRules.swift
//  CodeHighlighting
//
//  The regex rule table for Haxe.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Haxe: `//` and `/* */` comments, `"…"` and `'…'` strings, `~/…/flags` regular expressions, the
/// Haxe 4 keywords with the property-access words (`get`, `set`, `never`, `from`, `to`), a keyword
/// before `(` staying a keyword, `#if` conditional compilation, `@:meta` tags, and numbers.
extension RuleTables {
    static let haxe: [(String, TokenKind)] = [
        lineComment,
        blockComment,
        doubleQuoted,
        singleQuoted,
        ("~/(?:[^/\\\\\\n]|\\\\.)+/[gimsu]*", .string),
        callee,
        keywords([
            "abstract", "break", "case", "cast", "catch", "class", "continue", "default", "do", "dynamic", "else",
            "enum", "extends", "extern", "final", "for", "function", "if", "implements", "import", "in", "inline",
            "interface", "macro", "new", "operator", "overload", "override", "package", "private", "public", "return",
            "static", "switch", "this", "throw", "try", "typedef", "untyped", "using", "var", "while", "get", "set",
            "never", "from", "to", "super",
        ]),
        ("#(?:if|elseif|else|end|error|line)\\b", .keyword),
        ("@:?[A-Za-z_]\\w*", .attribute),
        constants(["true", "false", "null"]),
        types(["Int", "Float", "String", "Bool", "Dynamic", "Void", "Array", "Map", "Null", "Any"]),
        decimal,
    ]
}
