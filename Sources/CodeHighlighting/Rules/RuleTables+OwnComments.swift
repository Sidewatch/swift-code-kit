//
//  RuleTables+OwnComments.swift
//  CodeHighlighting
//
//  RuleTables: every language's own comment syntax, added to whichever table paints it.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import CodeLanguage

extension RuleTables {
    /// `table` with `lang`'s own line and block comments added. A family table knows its family's
    /// comments only — F# and Gleam inherited no `//`, SPARQL no `#`, Pascal no `{ }` — while the
    /// language table records each language's own. Added, never substituted: a family's forms can be
    /// legitimate too (HTML comments in a template language). A language whose comment opens with `'`
    /// (VB.NET) has no `'…'` strings, so those rules go; one whose comment is `"` (Vim script) also
    /// has `"…"` strings, so its comment is a WHOLE line from its first glyph, which starts earlier than
    /// any string on that line and so wins.
    static func withOwnComments(_ table: [(String, TokenKind)], for lang: Language) -> [(String, TokenKind)] {
        let own = ownCommentRules(for: lang)
        guard !own.isEmpty else { return table }
        var rules = table
        if lang.lineCommentToken == "'" {
            rules.removeAll { $0.0 == singleQuoted.0 || $0.0 == singleQuotedPlain.0 }
        }
        return rules + own
    }

    /// The comment rules `lang`'s own syntax gives, from the language table.
    static func ownCommentRules(for lang: Language) -> [(String, TokenKind)] {
        var rules: [(String, TokenKind)] = extraLineComments[lang] ?? []
        if let exact = exactLineComment[lang] {
            rules.append(exact)
        } else if let token = lang.lineCommentToken, let first = token.first {
            let escaped = NSRegularExpression.escapedPattern(for: token)
            if token == "\"" {
                rules.append(("^[ \\t]*\".*$", .comment))
            } else if first.isLetter {
                rules.append(("(?i)\\b\(escaped)\\b.*$", .comment))  // `REM`, a word: never inside another word
            } else {
                rules.append(("\(escaped).*$", .comment))
            }
        }
        if let block = lang.blockComment, !block.open.isEmpty, !block.close.isEmpty {
            rules.append(nestingLanguages.contains(lang) ? nestedBlock(block.open, block.close) : flatBlock(block.open, block.close))
        }
        if lang == .d { rules.append(nestedBlock("/+", "+/")) }  // D's nesting comment, beside its `/* */`
        return rules
    }

    /// Languages whose line comment needs more than "the token to the end of the line": in Org only
    /// `# text` (or a bare `#`) is a comment — `#+TITLE:` and the other `#+` lines are keywords.
    static let exactLineComment: [Language: (String, TokenKind)] = [
        .org: ("^[ \\t]*#(?:[ \\t].*)?$", .comment)
    ]

    /// A second comment form some languages have beside the one the language table records.
    static let extraLineComments: [Language: [(String, TokenKind)]] = [
        .thrift: [("#.*$", .comment)],
        .properties: [("^[ \\t]*!.*$", .comment)],
        .vbnet: [("(?i)^[ \\t]*REM\\b.*$", .comment)],
        .sas: [("^[ \\t]*\\*[^;]*;", .comment)],  // a statement comment ends at its semicolon
        .stata: [("^[ \\t]*\\*.*$", .comment)],
    ]

    /// Languages whose block comments nest: a flat `open…close` ends at the INNER close and leaves the
    /// rest of the outer comment painted as code.
    static let nestingLanguages: Set<Language> = [
        .fsharp, .ocaml, .reason, .sml, .coq, .wolfram, .haskell, .elm, .idris, .agda, .dhall, .purescript, .lean,
        .commonlisp, .scheme, .racket, .nim, .swift, .rust, .kotlin, .scala, .dart, .odin,
    ]

    /// `open … close` across lines, ending at the first close.
    static func flatBlock(_ open: String, _ close: String) -> (String, TokenKind) {
        let o = NSRegularExpression.escapedPattern(for: open), c = NSRegularExpression.escapedPattern(for: close)
        return ("\(o)[\\s\\S]*?\(c)", .comment)
    }

    /// `open … close` across lines with one level of nesting inside (`(* a (* b *) c *)`): a regex cannot
    /// count, and two levels is what real files use.
    static func nestedBlock(_ open: String, _ close: String) -> (String, TokenKind) {
        let o = NSRegularExpression.escapedPattern(for: open), c = NSRegularExpression.escapedPattern(for: close)
        let plain = "(?:(?!\(o)|\(c))[\\s\\S])"
        return ("\(o)(?:\(plain)|\(o)\(plain)*\(c))*\(c)", .comment)
    }
}
