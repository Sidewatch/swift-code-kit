//
//  BladeRules.swift
//  CodeHighlighting
//
//  The regex rule table for Blade (Laravel).
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Blade: `{{-- --}}` comments (the language's own), the `{{ }}` / `{!! !!}` echoes, `@directives`,
/// and the PHP inside an echo, a directive's arguments (to its line's end) or an `@php … @endphp`
/// block: `//` and `#` comments, strings, `$variables`, keywords and numbers — with the HTML around
/// them, whose attribute values are strings unless an echo sits inside one or the attribute is a
/// `:bound` or `@event` one.
extension RuleTables {
    static let blade: [(String, TokenKind)] =
        [
            htmlComment,
            (insideBladeCode + "(?://|#(?!\\[))[^\\n]*?(?=\\}\\}|!!\\}|$)", .comment),
            (insideBladeCode + "/\\*[\\s\\S]*?\\*/", .comment),
        ] + tagStrings(insideBladeCode) + [
            // A `:bound` or `@event` attribute's value is PHP or JavaScript, not a string.
            ("(?<==)(?<![:@][\\w.:-]{1,60}=)\"[^\"{<\\n]*\"", .string),
            ("(?<==)(?<![:@][\\w.:-]{1,60}=)'[^'{<\\n]*'", .string),
            ("</?[A-Za-z][\\w:.-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .attribute),
            ("(?<![\\w@])@[A-Za-z]\\w*", .keyword),
            ("\\{\\{|\\}\\}|\\{!!|!!\\}", .keyword),
            ("\\$[A-Za-z_]\\w*", .variable),
            (insideBladeCode + "\\b([A-Za-z_]\\w*)(?=\\s*\\()", .function),
            tagWords(
                [
                    "abstract", "and", "array", "as", "break", "case", "catch", "class", "clone", "const", "continue", "declare",
                    "default", "do", "echo", "else", "elseif", "enum", "extends", "final", "finally", "fn", "for", "foreach", "function",
                    "global", "if", "implements", "include", "instanceof", "interface", "isset", "list", "match", "namespace", "new",
                    "or", "print", "private", "protected", "public", "readonly", "require", "return", "static", "switch", "throw",
                    "trait", "try", "unset", "use", "var", "while", "xor", "yield",
                ], .keyword, insideBladeCode),
            tagWords(["true", "false", "null", "TRUE", "FALSE", "NULL"], .number, insideBladeCode),
            (insideBladeCode + decimal.0, .number),
        ]

    /// Inside an echo (`{{ … }}`, `{!! … !!}`), a directive's arguments up to its line's end, or an
    /// `@php … @endphp` block.
    static let insideBladeCode =
        inside(opens: ["\\{\\{", "\\{!!"], closes: ["\\}\\}", "!!\\}"])
        + inside(opens: ["@[A-Za-z]\\w{0,40}[ \\t]{0,4}\\("], closes: ["\\n"], within: 400)
        + inside(opens: ["@php\\b(?![ \\t]{0,4}\\()"], closes: ["@endphp"], within: 20000)
}
