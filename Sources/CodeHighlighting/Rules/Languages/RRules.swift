//
//  RRules.swift
//  CodeHighlighting
//
//  The regex rule table for R.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// R: `#` comments (roxygen `#'` included); `"…"` and `'…'` strings with backslash escapes and raw strings
/// `r"(…)"`, `R"---[…]---"`, `r"{…}"` in every bracket and dash count; `` `backtick names` `` are names,
/// not strings; `pkg::name` and `pkg:::name` are namespace access — there are no `:symbols`; `%op%`
/// operators; the reserved words, `TRUE` / `FALSE` / `NULL` / `NA` / `Inf` / `NaN`, and `1L` / `2i` numbers.
extension RuleTables {
    static let r: [(String, TokenKind)] = [
        hashComment,
        ("[rR]([\"'])(-*)\\((?:(?!\\)\\2\\1)[\\s\\S])*\\)\\2\\1", .string),
        ("[rR]([\"'])(-*)\\[(?:(?!\\]\\2\\1)[\\s\\S])*\\]\\2\\1", .string),
        ("[rR]([\"'])(-*)\\{(?:(?!\\}\\2\\1)[\\s\\S])*\\}\\2\\1", .string),
        doubleQuoted,
        singleQuoted,
        // A name may open with dots (`.(x)`, `...length()`) and hold them (`sys.function()`): one call.
        ("(?<![\\w.])[A-Za-z.][\\w.]*(?=\\s*\\()", .function),
        ("(?<![\\w.])(?:if|else|repeat|while|function|for|in|next|break|switch|return)(?![\\w.])", .keyword),
        ("\\b(TRUE|FALSE|NULL|NA|NA_integer_|NA_real_|NA_complex_|NA_character_|Inf|NaN|T|F)\\b", .number),
        ("\\b[A-Za-z.][\\w.]*(?=:::?)", .type),
        ("`[^`\\n]*`", .variable),
        ("%[^%\\n]*%", .keyword),
        ("\\b0[xX][0-9a-fA-F]+[Li]?\\b|(?<![\\w.])(?:\\d+(?:\\.\\d*)?|\\.\\d+)(?:[eE][+-]?\\d+)?[Li]?\\b", .number),
    ]
}
