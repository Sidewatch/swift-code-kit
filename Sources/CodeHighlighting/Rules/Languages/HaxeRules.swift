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

/// Haxe: `//` and `/* */` comments, `"…"` strings and `'…'` strings whose `$name` and `${…}` holes stay code
/// (`$$` is a dollar), `~/…/flags` regular expressions, the Haxe 4 keywords with the property-access words
/// (`get`, `set`, `never`, `from`, `to`), a keyword before `(` staying a keyword, the name a `function`
/// declares (`function get(`) as a function, `#if` conditional compilation, `@:meta` tags, and numbers
/// (`.5` included).
extension RuleTables {
    static let haxe: [(String, TokenKind)] =
        [
            lineComment,
            blockComment,
            doubleQuoted,
        ]
        + quotedStringPieces(
            quote: "'", body: "\\$\\$|\\\\[\\s\\S]|[^'\\\\]",
            hole: "\\$\\{(?:[^{}'\\n]|'[^'\\n]*'|\\{[^{}\\n]*\\})*\\}|\\$[A-Za-z_]\\w*", holeEnd: "[}\\w]",
            afterHole: "(?:(?<=\\})|(?<=\\w)(?!\\w))")
        + [
            ("~/(?:[^/\\\\\\n]|\\\\.)+/[gimsu]*", .string),
            callee,
            keywords([
                "abstract", "break", "case", "cast", "catch", "class", "continue", "default", "do", "dynamic", "else",
                "enum", "extends", "extern", "final", "for", "function", "if", "implements", "import", "in", "inline",
                "interface", "macro", "new", "operator", "overload", "override", "package", "private", "public", "return",
                "static", "switch", "this", "throw", "try", "typedef", "untyped", "using", "var", "while", "get", "set",
                "never", "from", "to", "super",
            ]),
            declaration(after: ["function"], .function),
            keywords(["function"]),
            ("#(?:if|elseif|else|end|error|line)\\b", .keyword),
            ("@:?[A-Za-z_]\\w*", .attribute),
            constants(["true", "false", "null"]),
            types(["Int", "Float", "String", "Bool", "Dynamic", "Void", "Array", "Map", "Null", "Any"]),
            decimal,
            ("\\B\\.\\d+(?:[eE][+-]?\\d+)?\\b", .number),
        ]
}
