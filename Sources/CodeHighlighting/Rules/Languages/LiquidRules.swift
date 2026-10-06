//
//  LiquidRules.swift
//  CodeHighlighting
//
//  The regex rule table for Liquid.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Liquid (Shopify and Jekyll): the `{% comment %}` blocks, the text of `{% doc %}` blocks and of
/// `{% # … %}` inline comments, and `#` lines inside a `{% liquid %}` tag, the `{% %}` / `{{ }}`
/// delimiters, the tag words, `| filter:` names, strings (which have no escapes), numbers and the
/// literal constants, with the HTML around them.
extension RuleTables {
    static let liquid: [(String, TokenKind)] =
        [
            ("\\{%-?\\s*comment\\s*-?%\\}[\\s\\S]*?\\{%-?\\s*endcomment\\s*-?%\\}", .comment),
            // A `{% doc %}` block's text and a `{% # … %}` tag's text are comments; the tags around them
            // stay tags.
            ("\\n(?<=\\{%-?[ \\t]{0,4}doc[ \\t]{0,4}-?%\\}\\n)[\\s\\S]*?(?=[ \\t]*\\{%-?\\s*enddoc\\b)", .comment),
            ("#(?<=\\{%-?[ \\t]{0,8}#)[\\s\\S]*?(?=-?%\\})", .comment),
            (insideTemplateTag + "^[ \\t]*#[^\\n]*", .comment),
            htmlComment,
            // Liquid strings have no escapes: a backslash is a character, the next quote ends it.
            (insideTemplateTag + "\"[^\"]*\"", .string),
            (insideTemplateTag + "'[^']*'", .string),
        ] + templateAttributeStrings + [
            ("</?[A-Za-z][\\w:-]*|/>|>", .keyword),
            ("\\b[A-Za-z-]+=", .attribute),
            ("\\{%-?|-?%\\}|\\{\\{-?|-?\\}\\}", .keyword),
            ("\\|\\s*[a-z_]\\w*", .function),
            ("\\b[a-zA-Z_]\\w*(\\.[a-zA-Z_][\\w-]*)+\\b", .property),
            templateTagKeywords([
                "assign", "capture", "endcapture", "case", "when", "else", "endcase", "if", "elsif", "endif", "unless", "endunless",
                "for", "endfor", "in", "break", "continue", "cycle", "tablerow", "endtablerow", "increment", "decrement", "include",
                "render", "section", "sections", "layout", "form", "endform", "paginate", "endpaginate", "raw", "endraw", "liquid", "echo",
                "with", "as", "and", "or", "contains", "limit", "offset", "reversed", "cols", "by", "javascript", "endjavascript",
                "stylesheet", "endstylesheet", "schema", "endschema", "style", "endstyle", "content_for", "block", "endblock",
            ]),
            templateTagConstants(["true", "false", "nil", "null", "blank", "empty"]),
            // A number's digits up to any letter after them (`1.5e3` is 1.5 and the name `e3`).
            (insideTemplateTag + "-?\\b\\d+(?:\\.\\d+)?", .number),
        ]
}
