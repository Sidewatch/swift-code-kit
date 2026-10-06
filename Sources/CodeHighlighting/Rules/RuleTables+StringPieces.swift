//
//  RuleTables+StringPieces.swift
//  CodeHighlighting
//
//  An interpolated string painted as the pieces between its holes, so the code in a hole reads as code.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

extension RuleTables {
    /// An interpolated string as two string rules that leave its holes unpainted, for the code rules to paint
    /// the code inside them: the head runs from the opening delimiter to the first hole (or the close), a tail
    /// from the end of each hole to the next hole (or the close).
    ///
    /// - `whole`: the whole string, holes included (it must find nested holes and strings itself). A tail only
    ///   starts inside one, so a closing bracket in plain code never opens a string.
    /// - `skip`: what else must be stepped over whole for the search for `whole` to stay in step: comments and
    ///   the other string forms, whose quotes are not this string's. Each must be painted by a comment or string
    ///   rule of its own, which then starts before (and so beats) any tail inside it.
    /// - `open` / `close`: the delimiters; `literal`: one character (or escape) of the text between holes, which
    ///   must stop at the close and at a hole's opening.
    /// - `holeClose`: the character that ends a hole (a closing brace or bracket). An opener right after one is that
    ///   string's close, never a new string.
    /// - `nested`: a bounded look back that, matching, says the `holeClose` just passed closes something nested
    ///   inside the hole (a call's bracket in `$(length(x) * 2)`), so no tail starts there. Without one, a tail
    ///   never starts at another `holeClose`: in `#{f(x)}` the first bracket closes the call.
    static func interpolatedStringPieces(
        whole: String, skip: [String] = [], open: String, close: String, literal: String, holeClose: String,
        nested: String? = nil
    ) -> [(String, TokenKind)] {
        let region = RuleScope.marker(opens: skip + [whole], closes: [""], within: 4000)
        let head = "(?:\(open))(?<!(?:\(holeClose))(?:\(open)))(?:\(literal))*(?:\(close))?"
        let notNested = nested.map { "(?<!\($0))" } ?? "(?!\(holeClose))"
        let tail = region + "(?<=\(holeClose))\(notNested)(?:(?:\(literal))+(?:\(close))?|(?:\(close)))"
        return [(head, .string), (tail, .string)]
    }
}
