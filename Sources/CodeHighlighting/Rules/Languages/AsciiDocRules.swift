//
//  AsciiDocRules.swift
//  CodeHighlighting
//
//  The regex rule table for AsciiDoc.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// AsciiDoc: `//` line and `////` block comments; `:name: value` attribute entries (the value a
/// string); block delimiters, `=` headings, `.Title` block titles, `[style,…]` attribute lines (the
/// style a function), list markers and table cells; admonition labels; macros — `name:target[text]`
/// and `name::target[text]` (`kbd:[…]`, `image::…[…]`, `include::…[]`, `ifdef::…[]`, URLs with link
/// text), whose name is a function and whose text is a string (a `\]` in it escaped, a `\` before
/// the name making it text); `<<xref,text>>` text, an anchor's `[[id,reftext]]`, `+++` and `$$`
/// passthroughs and `{set:…}` / `{counter:…}` values as strings; inline bold, italic and monospace;
/// callout numbers; URLs as strings. A heading or list marker is followed by a space on its own line:
/// a `\s` there would reach across the line break and paint the paragraph under a `====` delimiter as
/// a heading.
extension RuleTables {
    static let asciidoc: [(String, TokenKind)] = [
        ("^//(?!//).*$", .comment),
        ("^////[ \\t]*\\n[\\s\\S]*?^////[ \\t]*$", .comment),
        ("^:!?[\\w-]+!?:", .property),
        (adocAttributeEntry + "[ \\t](?<=:[ \\t])\\S[^\\n]*", .string),
        ("^(?:-{2}|-{4,}|={4,}|\\*{4,}|\\+{4,}|_{4,}|\\.{4,}|\\|===)[ \\t]*$", .keyword),
        ("^=+[ \\t].*$", .keyword),
        ("^\\.[A-Za-z].*$", .type),
        ("^\\[[^\\]\\n]*\\][ \\t]*$", .attribute),
        ("^\\[[\\w-]+", .function),
        ("^[ \\t]*[*.-]+[ \\t]", .keyword),
        ("^[ \\t]*\\d+\\.[ \\t]", .keyword),
        ("^\\|", .keyword),
        ("^(?:NOTE|TIP|IMPORTANT|WARNING|CAUTION):", .function),
        ("\\d(?<=<\\d)\\d*(?=>)", .number),
        // A macro's name (`kbd:`, `image::`, `ifdef::`), not a URL's scheme, and an attribute counter's.
        (
            "\\b(?!(?:https?|ftp|irc|file):)[a-z][\\w-]*:{1,2}(?=[^\\s\\[\\]]*\\[(?:[^\\]\\\\\\n]|\\\\.)*\\])|\\{(?:set|counter2?)(?=:)",
            .function
        ),
        // A backslash escapes a macro: `\footnote:[x]` is text.
        ("\\\\[a-z][\\w-]*:{1,2}", .identifier),
        // Monospace: constrained `` `text` `` (not the backticks of a "`curved quote`") and unconstrained
        // ``` ``text`` ```.
        ("``[^\\n]*?``|`(?<![\\w\"'`]`)(?=[^\\s`])[^`\\n]*?[^\\s`]`(?![\\w\"'`])|`(?<![\\w\"'`]`)[^\\s`]`(?![\\w\"'`])", .string),
        // A URL is a string: the language table's `//` comment would otherwise run from its slashes.
        ("\\b(?:https?|ftp|irc|file)://[^\\s\\[\\]<>]*", .string),
        ("\\*[^*\\n]+\\*", .type),
        ("_[^_\\n]+_", .variable),
        // The text in a macro's brackets, an anchor's reftext, an xref's text, a passthrough's content and a
        // counter's value: one pass, whose leading look back is a single character.
        (
            inside(opens: ["(?m)(?:^|[^\\\\\\w])[a-z][\\w-]*:{1,2}[^\\s\\[\\]]*\\[(?:[^\\]\\\\\\n]|\\\\.)*\\]"], closes: [""], within: 0)
                + inside(opens: ["\\[\\[[\\w-]+,[^\\]\\n]*\\]\\]"], closes: [""], within: 0)
                + inside(opens: ["(?m)(?:^|[^\\\\])<<[^>\\n]*>>"], closes: [""], within: 0)
                + inside(opens: ["\\+\\+\\+[^\\n]*?\\+\\+\\+"], closes: [""], within: 0)
                + inside(opens: ["\\$\\$[^\\n]*?\\$\\$"], closes: [""], within: 0)
                + inside(opens: ["\\{(?:set|counter2?):[\\w-]+:[^}\\n]*\\}"], closes: [""], within: 0)
                + "(?<=[\\[,<+$:])(?:(?<=\\[)(?<!\\[\\[)(?:[^\\[\\]\\\\\\n]|\\\\.)++(?=\\])|(?<=,)[^,\\[\\]\\n]++(?=\\]\\])|(?<=<<)[^<>\\n]++(?=>>)|(?<=\\+\\+\\+)[^+\\n](?:[^+\\n]|\\+(?!\\+\\+))*+(?=\\+\\+\\+)|(?<=\\$\\$)[^$\\n](?:[^$\\n]|\\$(?!\\$))*+(?=\\$\\$)|(?<=:)[^:{}\\n]++(?=\\}))",
            .string
        ),
    ]

    /// An attribute entry line (`:name: value`), from its start through the space after its name.
    private static let adocAttributeEntry = inside(opens: ["(?m)^:!?[\\w-]+!?:[ \\t]"], closes: [""], within: 0)
}
