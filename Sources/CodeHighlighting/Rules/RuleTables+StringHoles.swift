//
//  RuleTables+StringHoles.swift
//  CodeHighlighting
//
//  The builder for a string literal whose interpolation holes stay code.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The builder for a string literal whose interpolation holes (`#{…}`, `${…}`, `$name`) stay code, the way
/// VS Code paints them: strings paint last and whole, so a hole can only stay code if no string match covers
/// it. The literal is painted in pieces: the HEAD runs from the opening delimiter to the first hole or the
/// closing delimiter, and each TAIL from just after a hole to the next hole or the closing delimiter.
///
/// A quoted literal's tail is recognised by looking AHEAD: from inside a literal the rest of the line holds
/// an odd number of unescaped quotes (its own closing one, then whole literals), from code an even number, so
/// a hole after a closed literal (`"a" #{x} "b"`) never starts a tail. A tail holds no `}`, so one never
/// starts inside a hole's nested braces (`#{ {{x}} }`). A look back would have to reach the opening quote,
/// which the strings-and-comments pass cannot see once it has accepted the head (it searches again only from
/// the end of the last piece), and every look back that opens a pattern runs at every character.
extension RuleTables {
    /// The pieces of a `quote`-delimited literal (its tails found within a line) whose body characters match `body` (one
    /// character or escape) and whose holes match `hole`. `holeEnd` is the class of a hole's last character
    /// (`\}`): a quote right after one closes its literal and never opens one, or the longer head would beat
    /// the one-character tail that starts at the same place. `afterHole` is a cheap zero-width test that a
    /// hole could end just before (`(?<=\})`), checked before the look ahead. Every part must be regex-safe.
    static func quotedStringPieces(quote: String, body: String, hole: String, holeEnd: String, afterHole: String)
        -> [(String, TokenKind)]
    {
        let hole = "(?:\(hole))", body = "(?:\(body))"
        let char = "(?:(?!\(hole))\(body))"
        let end = "(?:\(quote)|(?=\(hole)))"
        let other = "(?:[^\(quote)\\\\\\n]|\\\\.)*+"
        let oddQuotesToLineEnd = "(?=(?:\(other)\(quote)\(other)\(quote))*+\(other)\(quote)\(other)$)"
        return [
            ("\(quote)(?<!\(holeEnd)\(quote))\(char)*\(end)", .string),
            ("\(afterHole)\(oddQuotesToLineEnd)(?:(?:(?!\\})\(char))+\(end)|\(quote))", .string),
        ]
    }
}
