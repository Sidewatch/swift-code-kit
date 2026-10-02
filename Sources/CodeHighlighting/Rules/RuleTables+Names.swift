//
//  RuleTables+Names.swift
//  CodeHighlighting
//
//  RuleTables: plain names in programming languages, painted as identifiers.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import CodeLanguage
import Foundation

extension RuleTables {
    /// `table` with a name rule FIRST for a programming language, so every later rule — keywords, types,
    /// calls, and the strings and comments painted after all of them — outranks it, and only the names no
    /// rule claims keep the identifier colour. Languages where a bare word is a command, a directive, a
    /// key or prose (shells, config, data, markup, stylesheets, SQL, schemas, assembly) are left as they
    /// are.
    static func withNames(_ table: [(String, TokenKind)], for lang: Language) -> [(String, TokenKind)] {
        guard let pattern = namePattern(for: lang) else { return table }
        return [(pattern, .identifier)] + table
    }

    /// The name pattern for `lang`, or nil when its plain words are not code names.
    static func namePattern(for lang: Language) -> String? {
        if lispNames.contains(lang) { return "\\b[A-Za-z_][\\w*+!?<>=/-]*" }
        if primedNames.contains(lang) { return "\\b[A-Za-z_][A-Za-z0-9_']*" }
        if codeNames.contains(lang) { return "\\b[A-Za-z_][A-Za-z0-9_]*\\b" }
        return nil
    }

    /// Lisps: a name runs through `-`, `?`, `!`, `*` (`set-car!`, `string->list`).
    static let lispNames: Set<Language> = [.clojure, .commonlisp, .elisp, .fennel, .racket, .scheme]

    /// ML-style languages: a name may carry primes (`foldl'`, `x''`).
    static let primedNames: Set<Language> = [
        .agda, .coq, .elm, .fsharp, .haskell, .idris, .lean, .ocaml, .purescript, .reason, .rescript, .sml,
    ]

    /// The other programming languages on the regex tier.
    static let codeNames: Set<Language> = [
        .actionscript, .ada, .applescript, .awk, .cairo, .carbon, .coffeescript, .crystal, .cuda, .d, .dart,
        .elixir, .erlang, .fortran, .gleam, .glsl, .go, .gradle, .groovy, .hack, .haxe, .hlsl, .java, .javascript,
        .julia, .kotlin, .lua, .matlab, .metal, .move, .nim, .objectivec, .objectivecpp, .odin, .opencl, .pascal,
        .perl, .php, .powershell, .prolog, .python, .qsharp, .r, .raku, .ruby, .rust, .scala, .smalltalk,
        .solidity, .starlark, .swift, .systemverilog, .tcl, .typescript, .v, .vala, .vbscript, .verilog, .vhdl,
        .vyper, .wolfram, .zig, .c, .cpp, .csharp, .tsx, .jsx,
    ]
}
