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
    static let scss: [(String, TokenKind)] = [
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
        // Strings end on their line (a backslash continues them) and may carry `#{…}` interpolation,
        // whose own quotes (`"#{f("a")}"`) must not close the string early.
        interpolatedString(quote: "\""),
        interpolatedString(quote: "'"),
        // An unquoted `url(…)` is a string from its `(`, so the `//` in `url(http://…)` opens no comment. The match
        // opens on the `(` and looks back for `url` from there: a lookbehind that opens a pattern runs at every character.
        ("\\((?<=\\burl\\()[^)\"'\\s$#@]+", .string),
        // A number with any unit, a leading dot (`.5s`) or sign (`-1px`): `100%`, `2dppx`, `1fr`.
        ("(?:(?<![\\w-])-)?(?:\\b\\d+(?:\\.\\d+)?|(?<![\\w-])\\.\\d+)(?:%|[a-zA-Z]+\\b)?", .number),
        ("[.#%][a-zA-Z_-][\\w-]*", .function),  // selectors (+ SCSS %placeholders)
        ("#[0-9a-fA-F]{3,8}\\b", .number),  // hex colours, after `#fff`-shaped selectors
        ("[a-z-]+(?=\\s*:)", .type),  // property names
        ("@[a-zA-Z_-][\\w-]*", .property),  // Less @variables
        ("@(?:" + cssAtKeywords.joined(separator: "|") + ")\\b", .keyword),
        ("\\$[a-zA-Z_-][\\w-]*", .property),  // SCSS/Sass $variables
        ("(?i)!\\s*(?:important|default|global|optional)\\b", .keyword),
        // The control words of `@each $x in …`, `@for $i from 1 through 3`, `@if not …`. The word comes first and
        // the lookbehind after it, so the lookbehind runs only where the word is, not at every character.
        ("\\b(?:in|from|through|to)\\b(?<=@(?:each|for)\\b[^\\n{]{0,200}(?:in|from|through|to))", .keyword),
        ("\\b(?:not|and|or)\\b(?<=@(?:if|else if|while|return)\\b[^\\n{]{0,200}(?:not|and|or))", .keyword),
    ]

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

    /// A `quote`-delimited Sass string: single-line, escapes, and `#{…}` holes that may hold quoted strings.
    private static func interpolatedString(quote: String) -> (String, TokenKind) {
        let plain = "[^\(quote)\\\\\\n#]|\\\\[\\s\\S]|#(?!\\{)"
        let inner = "\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'"
        let hole = "#\\{(?:[^{}\"'\\n]|\(inner))*\\}"
        return ("\(quote)(?:\(plain)|\(hole))*\(quote)", .string)
    }
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
            ("\\b(?:in|is a|is defined|is not|isnt|is|not|and|or|unless|if)\\b(?![\\w-]*\\s*[:(])", .keyword),
        ]
}
