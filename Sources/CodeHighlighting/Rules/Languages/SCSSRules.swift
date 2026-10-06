//
//  SCSSRules.swift
//  CodeHighlighting
//
//  The regex rule table for SCSS / Sass / Less / PostCSS, and Stylus on top of it.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for SCSS / Sass / Less / PostCSS.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let scss: [(String, TokenKind)] =
        [
            // CSS supersets whose variables (`$var` in SCSS/Sass, `@var` in Less)
            // the CSS tree-sitter grammar turns into ERROR nodes that swallow
            // neighbouring declarations (indented Sass barely parses at all), so
            // these route here instead of reusing that grammar — see the note by
            // the grammar table in `TreeSitterHighlighter`. Later rules overwrite
            // earlier ones: property names paint before the variable rules so
            // `$primary:` / `@primary:` keep the variable colour, and the known
            // at-keywords repaint over the generic Less `@var` rule.
            lineComment,
            blockComment,
        ]
        // Strings end on their line (a backslash continues them); a `#{…}` hole stays code, and its own quotes
        // (`"#{f("a")}"`) do not close the string.
        + interpolatedString(quote: "\"") + interpolatedString(quote: "'")
        + [
            // An unquoted `url(…)` argument is one CSS url token, a string, so the `//` in `url(http://…)` opens no
            // comment; the brackets stay code. The match opens with a one-character look back for `(`, cheap at every
            // character, and only then looks back for `url(`.
            ("(?<=\\()(?<=\\burl\\()[^)\"'\\s$#@]+", .string),
            // A function call, and a mixin or function declared by name (`@mixin name`, `@function name`), which
            // the at-keyword rules below repaint back to keywords.
            ("-?\\b[a-zA-Z_][\\w-]*(?=\\()", .function),
            ("@(?:mixin|function|define-mixin|(?:-webkit-)?keyframes)[ \\t]+[a-zA-Z_-][\\w-]*", .function),
            // A number: a sign (`-1px`, `+5`; a `-` after a name is part of the name), a leading dot (`.5s`), an
            // exponent (`1e3`). Its unit (`px`, `%`, `fr`) wears the type colour, as the CSS grammar paints it.
            (cssNumber + "(?:%|(?!n\\b)[a-zA-Z]+\\b)", .type),
            (cssNumber + "(?:n\\b)?", .number),  // `2n` of `:nth-child(2n+1)` is one number
            ("\\b[uU]\\+[0-9a-fA-F?]{1,6}(?:-[0-9a-fA-F]{1,6})?", .number),  // unicode ranges: U+0025-00FF, U+4??
            ("[.#%][a-zA-Z_-][\\w-]*", .function),  // selectors (+ SCSS %placeholders)
            ("#[0-9a-fA-F]{3,8}\\b", .number),  // hex colours, after `#fff`-shaped selectors
            ("[a-z-]+(?=\\s*:)", .type),  // property names
            ("@[a-zA-Z_-][\\w-]*", .property),  // Less @variables
            ("@(?:" + cssAtKeywords.joined(separator: "|") + ")\\b", .keyword),
            ("\\$[a-zA-Z_-][\\w-]*", .property),  // SCSS/Sass $variables
            ("(?i)!\\s*(?:important|default|global|optional)\\b", .keyword),
            // The control words of `@each $x in …`, `@for $i from 1 through 3`, `@if not …`, and a media query's
            // `screen and (…)` / `not all`. The word comes first and the lookbehind after it, so the lookbehind
            // runs only where the word is, not at every character.
            ("\\b(?:in|from|through|to)\\b(?<=@(?:each|for)\\b[^\\n{]{0,200}(?:in|from|through|to))", .keyword),
            ("\\b(?:not|and|or)\\b(?<=@(?:if|else if|while|return)\\b[^\\n{]{0,200}(?:not|and|or))", .keyword),
            (
                "\\b(?:not|and|or|only|screen|print|all)\\b(?<=@(?:media|supports|import|custom-media|container)\\b[^\\n{;]{0,200}(?:not|and|or|only|screen|print|all))",
                .keyword
            ),
        ]

    /// A CSS number without its unit: an optional sign, digits with a fraction or a leading dot, an exponent.
    static let cssNumber =
        "(?:(?<![\\w-])-|\\+)?(?:\\b\\d+(?:\\.\\d+)?|(?<![\\w-])\\.\\d+)(?:[eE][+-]?\\d+(?![a-zA-Z]))?"

    /// The at-rules of CSS, its preprocessors (Sass, Less, PostCSS plugins) and Tailwind. Any other
    /// `@word` is a Less variable.
    static let cssAtKeywords = [
        "media", "import", "charset", "namespace", "supports", "keyframes", "-webkit-keyframes", "font-face", "page",
        "layer", "container", "property", "scope", "starting-style", "counter-style", "font-feature-values",
        "font-palette-values", "styleset", "stylistic", "swash", "ornaments", "annotation", "character-variant",
        "position-try", "view-transition", "document", "viewport", "include", "mixin", "function", "return", "extend",
        "use", "forward", "if", "else", "each", "for", "while", "content", "at-root", "debug", "warn", "error", "plugin",
        "custom-media", "custom-selector", "define-mixin", "nest", "apply", "tailwind", "theme", "utility", "variant",
        "custom-variant", "source", "config", "reference", "require", "css",
    ]

    /// A `quote`-delimited Sass string: single-line, escapes, and `#{…}` holes that stay code and may hold
    /// quoted strings.
    private static func interpolatedString(quote: String) -> [(String, TokenKind)] {
        let other = quote == "\"" ? "'" : "\""
        return interpolatedStringPieces(
            open: quote, close: quote, literal: "[^\(quote)\\\\\\n#]|\\\\[\\s\\S]|#(?!\\{)",
            hole: "#\\{(?:[^{}\"'\\n]|\"[^\"\\n]*\"|'[^'\\n]*')*\\}", holeOpen: "#\\{", holeClose: "\\}",
            skip: [blockComment.0, "url\\([^)\"'\\s]*\\)", "//[^\\n]*", "\(other)(?:[^\(other)\\\\\\n]|\\\\[\\s\\S])*\(other)"])
    }
}

/// The regex rule table for indented Sass: the SCSS table, plus the `=name` mixin and `+name` include
/// shorthands, and an unquoted `url(…)` painted whole as the one CSS url token it is.
extension RuleTables {
    static let sass: [(String, TokenKind)] =
        scss + [
            ("^[ \\t]*[=+][ \\t]*[a-zA-Z_][\\w-]*", .function),
            ("\\burl\\([^)\"'\\s$#@]*\\)", .string),
        ]
}

/// The regex rule table for PostCSS: the SCSS table, where every `@word` is an at-rule (a plugin's
/// `@define-mixin`, `@svg-load`, …) — PostCSS has no `@variables`.
extension RuleTables {
    static let postcss: [(String, TokenKind)] = scss + [("@[a-zA-Z_-][\\w-]*", .keyword)]
}

/// The regex rule table for Stylus: the PostCSS table plus Stylus's own control words, which need no `@`
/// (`if`, `unless`, `for … in`, `is defined`, `return`).
extension RuleTables {
    static let stylus: [(String, TokenKind)] =
        postcss + [
            ("^[ \\t]*(?:if|else if|else|unless|for|return)\\b", .keyword),
            ("\\bin\\b(?<=^[ \\t]{0,40}for\\b[^\\n]{0,100}\\bin)", .keyword),  // `for i in (3..1)`
            ("\\b(?:in|is a|is defined|is not|isnt|is|not|and|or|unless|if)\\b(?![\\w-]*\\s*[:(])", .keyword),
        ]
}
