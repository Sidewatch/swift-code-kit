//
//  LeanRules.swift
//  CodeHighlighting
//
//  The regex rule table for Lean.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Lean 4: `--` and nestable `/- -/` comments, `"…"` strings (which may span lines), raw `r#"…"#`
/// strings, character literals (`'a'`, `'\x41'`) that the prime of `h'` and `xs'` is not,
/// the command and tactic words, numeric literals.
extension RuleTables {
    static let lean: [(String, TokenKind)] = [
        dashComment,
        ("/-(?:[^-/]|-(?!/)|/(?!-)|/-(?:[^-]|-(?!/))*-/)*-/", .comment),
        ("r(#+)\"[\\s\\S]*?\"\\1", .string),
        ("r\"[^\"]*\"", .string),
        doubleQuoted,
        // The prime of a name (`h'`, `xs'`) or of an index (`a[0]'h`) follows an operand; a character does not.
        ("(?<![\\w'\\]])'(?:\\\\(?:x[0-9a-fA-F]{2}|u[0-9a-fA-F]{4}|.)|[^'\\\\\\n])'", .string),
        ("\\b[smf]!(?=\")", .function),
        keywords([
            "def", "theorem", "lemma", "example", "instance", "structure", "inductive", "class", "abbrev", "axiom", "opaque", "namespace",
            "section", "end", "open", "import", "export", "variable", "universe", "where", "with", "match", "fun", "λ", "let", "have",
            "show", "from", "if", "then", "else", "do", "return", "for", "in", "unless", "try", "catch", "finally", "by", "at", "calc",
            "macro", "macro_rules", "syntax", "notation", "infixl", "infixr", "infix", "prefix", "postfix", "elab", "private",
            "protected", "partial", "unsafe", "noncomputable", "mutual", "deriving", "extends", "set_option", "attribute", "local",
            "scoped", "termination_by", "decreasing_by", "using", "generalizing", "intro", "exact", "apply", "rfl", "simp", "rw",
            "cases", "induction", "rcases", "omega", "decide", "trivial", "constructor", "exists",
        ]),
        types(["Type", "Prop", "Sort", "Nat", "Int", "String", "Bool", "Char", "Float", "List", "Array", "Option", "IO", "Unit"]),
        constants(["true", "false", "sorry", "none", "some"]),
        ("#[A-Za-z_]+", .keyword),
        ("\\b\\d[\\d_]*(?:\\.\\d+)?(?:[eE][+-]?\\d+)?\\b|\\b0[xX][0-9a-fA-F_]+\\b|\\b0[bB][01_]+\\b|\\b0[oO][0-7_]+\\b", .number),
    ]
}
