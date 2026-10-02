//
//  SmartyRules.swift
//  CodeHighlighting
//
//  The regex rule table for Smarty.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Smarty: `{* *}` comments (the language's own), tags that open with a `{` and no space after it,
/// their names and `{/closers}`, `$variables`, `|modifiers`, and the strings, numbers and constants
/// inside a tag, with the HTML around them. A `{ ` followed by a space is a literal brace (Smarty's
/// auto-literal rule), so CSS and script blocks stay out of it.
extension RuleTables {
    static let smarty: [(String, TokenKind)] = [
        htmlComment,
        (insideSmartyTag + "\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
        (insideSmartyTag + "'(?:[^'\\\\\\n]|\\\\.)*'", .string),
        ("(?<==)\"[^\"{\\n]*\"", .string),
        ("(?<==)'[^'{\\n]*'", .string),
        ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
        ("\\b[A-Za-z-]+=", .attribute),
        ("\\{/?(?=[^\\s*])", .keyword),
        (insideSmartyTag + "\\}", .keyword),
        ("(?<=\\{/?)[a-z_]\\w*", .keyword),
        ("\\$[A-Za-z_]\\w*", .variable),
        ("\\|@?[a-z_]\\w*", .function),
        (
            insideSmartyTag
                + "\\b(?:as|and|or|not|mod|is|div|by|even|odd|eq|ne|neq|gt|lt|gte|ge|lte|le|from|item|key|name|to|step|in|loop|nocache)\\b",
            .keyword
        ),
        (insideSmartyTag + "\\b(?:true|false|null|TRUE|FALSE|NULL)\\b", .number),
        (insideSmartyTag + "-?\\b(?:0[xX][0-9a-fA-F]+|\\d+(?:\\.\\d+)?)\\b", .number),
    ]

    /// Inside a Smarty tag, its closing `}` included: a `{` with no space or `*` after it, up to the
    /// next brace on its line.
    static let insideSmartyTag = inside(opens: ["\\{(?=[^{}\\s*])"], closes: ["\\}", "\\{", "\\n"], within: 200)
}
