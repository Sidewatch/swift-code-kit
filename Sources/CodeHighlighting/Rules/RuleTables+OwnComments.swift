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
        var rules: [(String, TokenKind)] = []
        if let token = lang.lineCommentToken, let first = token.first {
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
            let open = NSRegularExpression.escapedPattern(for: block.open)
            let close = NSRegularExpression.escapedPattern(for: block.close)
            rules.append(("\(open)[\\s\\S]*?\(close)", .comment))
        }
        return rules
    }
}
