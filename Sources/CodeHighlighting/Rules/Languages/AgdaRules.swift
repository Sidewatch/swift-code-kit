//
//  AgdaRules.swift
//  CodeHighlighting
//
//  The regex rule table for Agda.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Agda: `--` comments and nesting `{- -}` block comments, `"…"` strings, `'x'` character literals
/// (a prime ending a name, `⊥'`, opens nothing), the keywords of the Agda reference — dashed ones like
/// `no-eta-equality` whole — and the reserved symbols `→ -> λ \ ∀ : = |` where they stand alone, the
/// irrelevance dot (`.A`, `.(x : A)`), and numbers with `_` separators. Names hold dashes and primes, so a
/// keyword is a whole space-separated token. The name a signature declares (`name :` opening a line,
/// mixfix `_+_` and unicode names included) is a function.
extension RuleTables {
    static let agda: [(String, TokenKind)] = [
        dashComment,
        nestedBlock("{-", "-}"),
        doubleQuoted,
        ("(?<=[\\s(])'(?:[^'\\\\\\n]|\\\\[^'\\n]{1,6})'(?=[\\s)])", .string),
        (
            "(?<![\\w'-])(abstract|coinductive|constructor|data|do|eta-equality|field|forall|hiding|import|in|inductive|infix|infixl|infixr|instance|interleaved|let|macro|module|mutual|no-eta-equality|opaque|open|overlap|pattern|postulate|primitive|private|public|quote|quoteTerm|record|renaming|rewrite|syntax|tactic|to|unfolding|unquote|unquoteDecl|unquoteDef|using|variable|where|with)(?![\\w'-])",
            .keyword
        ),
        ("(?<=[\\s({]|^)(?:→|->|λ|\\\\|∀|:|=|\\||\\.\\.\\.?)(?=[\\s)}]|$)", .keyword),
        ("(?<![\\w'-])(?:Set|Prop)[₀-₉\\d]*(?![\\w'-])", .type),
        ("(?<![\\w'-])(?:0x[0-9a-fA-F_]+|\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?)(?![\\w'-])", .number),
        ("\\.(?<=\\s\\.)(?=[({\\w])", .keyword),
        ("^[ \\t]*[^\\s(){}:;\"]+(?=[ \\t]*:(?=\\s))", .function),
    ]
}
