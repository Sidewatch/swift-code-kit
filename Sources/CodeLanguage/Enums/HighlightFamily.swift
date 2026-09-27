//
//  HighlightFamily.swift
//  CodeLanguage
//
//  The broad syntactic family a language belongs to.
//
//  Created by David Sherlock on 7/9/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The broad syntactic family a language belongs to.
///
/// This is a *coarse* grouping used to drive fallback highlighting: a syntax
/// highlighter that has no dedicated grammar for a given ``Language`` can pick a
/// reasonable rule set from its family (e.g. every `cLike` language shares `//`
/// and `/* */` comments, braces, and C-style keywords). It is deliberately not a
/// precise classification — many languages only approximately fit their family.
public enum HighlightFamily: String, CaseIterable, Sendable {

    /// Curly-brace languages with `//` and `/* */` comments (C, Java, JS, Rust, Go…).
    case cLike

    /// `#`-commented, `def`/`end`-style languages (Ruby, Crystal, Elixir…).
    case rubyLike

    /// S-expression languages with `;` comments (Clojure, Scheme, Lisp…).
    case lispLike

    /// Functional languages with `--` or `(* *)` comments (Haskell, OCaml, Elm…).
    case mlLike

    /// Shell and shell-adjacent `#`-commented scripts (Bash, Zsh, Fish, Make…).
    case shellLike

    /// Tag-based markup (HTML, XML, Vue, Svelte, Markdown…).
    case markup

    /// Key/value and section-based configuration (INI, TOML, .env, Apache…).
    case config

    /// SQL and query languages.
    case sql

    /// TeX-family documents with `%` comments (LaTeX, BibTeX…).
    case tex

    /// JSON-like structured data.
    case data

    /// Recognized, but with no distinctive highlighting rules of its own.
    case plain
}
