//
//  RuleTables+TemplateTags.swift
//  CodeHighlighting
//
//  The rules template languages build from: code that counts only inside its tags.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The rules template languages build from. A template is a document (HTML, YAML, prose) with tags
/// of code in it — `{{ … }}`, `{% … %}`, `<% … %>`: a quote, a keyword or a number is code only
/// inside a tag, and in the text between tags an apostrophe or the word `in` is the document's own.
/// A regex cannot track tags, so such a rule carries a scope (``RuleScope``): its pattern opens with a
/// marker naming the tag, and ``SyntaxHighlighter`` keeps only the matches that start inside one —
/// the tags found once per paint by a forward scan.
extension RuleTables {

    /// The scope marker for a tag opened by one of `opens` and closed by the next of `closes` (regex
    /// forms; the close belongs to the tag), at most `within` characters long; the tag may span lines.
    /// Put it in FRONT of a pattern; several markers in a row allow any of their tags.
    static func inside(opens: [String], closes: [String], within: Int = 600) -> String {
        RuleScope.marker(opens: opens, closes: closes, within: within)
    }

    /// Inside a `{{ … }}` or `{% … %}` tag (Jinja, Twig, Nunjucks, Liquid, Handlebars). A quoted string
    /// in the tag is passed over whole, so a `}}` inside one (`{{ "a }} b" }}`) does not close it.
    static let insideTemplateTag = inside(
        opens: ["\\{[{%](?:[^}%\"']|\"[^\"\\n]{0,200}\"|'[^'\\n]{0,200}'|[}%](?!\\})){0,600}"], closes: ["\\}\\}", "%\\}"])

    /// Inside a `<% … %>` tag (ERB, JSP).
    static let insideScriptletTag = inside(opens: ["<%"], closes: ["%>"])

    /// Inside a `<script>` element of the page a template writes.
    static let insideScript = inside(opens: ["<script\\b[^>]*>"], closes: ["</script>"], within: 20000)

    /// Inside a `<style>` element of the page a template writes.
    static let insideStyle = inside(opens: ["<style\\b[^>]*>"], closes: ["</style>"], within: 20000)

    /// A page's `<script>` JavaScript, for a template table: keywords, arrows, `"…"` and `'…'` strings on
    /// their line (a template tag inside one is part of it), and the name an arrow function is assigned
    /// to (`window.focus = (el) => …`).
    static let pageScriptRules: [(String, TokenKind)] =
        [
            (insideScript + "\"(?:[^\"\\\\\\n]|\\\\.)*\"", .string),
            (insideScript + "'(?:[^'\\\\\\n]|\\\\.)*'", .string),
            scopedTrie(
                [
                    "const", "let", "var", "function", "return", "if", "else", "for", "while", "new", "typeof", "await", "async",
                    "of", "in",
                ], .keyword, insideScript),
            (insideScript + "=>", .keyword),
            (insideScript + "\\b[A-Za-z_$][\\w$]*(?=[ \\t]*=[ \\t]*(?:async[ \\t]*)?\\([^()\\n]*\\)[ \\t]*=>)", .function),
        ]

    /// A page's `<style>` CSS, for a template table: its names (``pageStyleNames``) and numbers
    /// (``pageStyleNumbers``).
    static let pageStyleRules: [(String, TokenKind)] = pageStyleNames + pageStyleNumbers

    /// A page's `<style>` names: class selectors, property names and keyword values, and colours. Each
    /// pattern opens on a character that is rare in a page (`.`, `{`, `;`, `:`, `#`), whose paint it takes.
    static let pageStyleNames: [(String, TokenKind)] = [
        (insideStyle + "\\.(?<![\\w-]\\.)[A-Za-z_][\\w-]*", .type),
        (insideStyle + "[{;][ \\t]*[a-z-]+(?=[ \\t]*:)|^[ \\t]*[a-z-]+(?=[ \\t]*:)", .keyword),
        (insideStyle + ":[ \\t]*[a-z][a-z-]*(?=[ \\t]*[;}])", .keyword),
        (insideStyle + "#[0-9A-Fa-f]{3,8}\\b", .number),
    ]

    /// A page's `<style>` numbers with their units (`.25rem`, `4px`): the whole as a keyword, then its
    /// digits as a number.
    static let pageStyleNumbers: [(String, TokenKind)] = [
        (insideStyle + "\\.?\\d[\\d.]*(?:px|rem|em|ex|ch|vh|vw|vmin|vmax|pt|pc|cm|mm|in|s|ms|deg|fr|%)(?![\\w%])", .keyword),
        (insideStyle + "\\b\\d+(?:\\.\\d+)?|\\B\\.\\d+", .number),
    ]

    /// A `"…"` or `'…'` literal that opens inside a `{{ }}` / `{% %}` tag. The literal itself may hold
    /// escapes, a `}}`, and line breaks.
    static let templateTagStrings: [(String, TokenKind)] = tagStrings(insideTemplateTag)

    /// A `"…"` and a `'…'` literal with backslash escapes that open inside `scope`'s tags.
    static func tagStrings(_ scope: String) -> [(String, TokenKind)] {
        [
            (scope + "\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
            (scope + "'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
        ]
    }

    /// The words as keywords where they stand inside a `{{ }}` / `{% %}` tag; between tags they are
    /// prose.
    static func templateTagKeywords(_ words: [String]) -> (String, TokenKind) {
        tagWords(words, .keyword, insideTemplateTag)
    }

    /// The literal constants (`true`, `nil`, …) inside a `{{ }}` / `{% %}` tag, painted as numbers like
    /// every table's constants.
    static func templateTagConstants(_ words: [String]) -> (String, TokenKind) {
        tagWords(words, .number, insideTemplateTag)
    }

    /// `words` of `kind` inside `scope`, as one prefix tree (``wordTrie(_:_:caseInsensitive:)``): a
    /// long list costs a fraction of ``tagWords(_:_:_:)``'s alternation.
    static func scopedTrie(_ words: [String], _ kind: TokenKind, _ scope: String) -> (String, TokenKind) {
        (scope + wordTrie(words, kind).0, kind)
    }

    /// `\b(a|b|c)\b` of `kind` inside `scope`'s tags.
    static func tagWords(_ words: [String], _ kind: TokenKind, _ scope: String) -> (String, TokenKind) {
        (scope + "\\b(?:" + words.joined(separator: "|") + ")\\b", kind)
    }

    /// An HTML attribute value with no template tag inside: `class="low"`. In one that holds a tag
    /// (`class="row-{{ i }} {{ cls }}"`) the quotes and the text between the tags are the string and
    /// each tag keeps its own colours.
    static let templateAttributeStrings: [(String, TokenKind)] =
        [
            ("(?<==)\"[^\"{<\\n]*\"", .string),
            ("(?<==)'[^'{<\\n]*'", .string),
        ] + valueAroundTags(quote: "\"") + valueAroundTags(quote: "'")

    /// The string pieces of an attribute value quoted by `quote` that holds a tag: the opening quote
    /// and the text before the first tag, the text between tags, and the text after the last with the
    /// closing quote. A quote right after a tag closes the value and never opens one.
    private static func valueAroundTags(quote q: String) -> [(String, TokenKind)] {
        let value = inside(opens: ["(?<==)\(q)[^\(q)<>\\n]*\\{[{%][^\(q)\\n]*\(q)"], closes: [""], within: 0)
        return [
            (value + "\(q)(?<!\\}\(q))[^\(q){<\\n]*(?=\\{[{%])", .string),
            (value + "(?<=\\})(?:[^\(q){}<>\\n]+(?=\\{[{%])|[^\(q){}<>\\n]*\(q))", .string),
        ]
    }
}
