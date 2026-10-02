//
//  JinjaRules.swift
//  CodeHighlighting
//
//  The regex rule table for Jinja.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Jinja: `{# #}` comments, the `{% %}` and `{{ }}` delimiters, the tag words, `| filters`,
/// dotted lookups, plus the markup family's tags for the HTML around them. A quote is a string only
/// inside a tag: the text between tags is the document's own (YAML, HTML, prose), where an
/// apostrophe or a quoted attribute value is not template syntax.
extension RuleTables {
    static let jinja: [(String, TokenKind)] =
        [("\\{#[\\s\\S]*?#\\}", .comment), htmlComment] + templateTagStrings + [
            ("\\{%[-+]?|[-+]?%\\}|\\{\\{[-+]?|[-+]?\\}\\}", .keyword),
            templateTagKeywords([
                "if", "elif", "else", "endif", "for", "endfor", "in", "set", "endset", "block", "endblock", "extends", "include", "import",
                "from", "as", "macro", "endmacro", "call", "endcall", "filter", "endfilter", "with", "endwith", "raw", "endraw",
                "autoescape",
                "endautoescape", "is", "not", "and", "or", "true", "false", "none", "True", "False", "None", "loop", "recursive", "scoped",
                "ignore", "missing", "context", "without", "do", "trans", "endtrans", "pluralize", "break", "continue",
            ]),
            ("\\|\\s*[a-z_]\\w*", .function),
            ("\\b[a-zA-Z_]\\w*(\\.[a-zA-Z_]\\w*)+\\b", .property),
            ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .attribute),
            ("\\b\\d[\\d_]*(\\.\\d*)?([eE][+-]?\\d+)?\\b", .number),
        ]
}
