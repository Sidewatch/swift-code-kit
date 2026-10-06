//
//  InterpolatedStringForm.swift
//  CodeHighlighting
//
//  One kind of string literal whose interpolation holes stay code, as regex parts.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// One kind of string literal whose interpolation holes stay code (`"a ${b} c"`), as the regex parts
/// ``RuleTables/interpolatedStringPieces(_:holeClose:afterHole:skip:)`` paints it from.
struct InterpolatedStringForm {
    /// The opening delimiter, of bounded length: the head looks back over it.
    let open: String
    /// The closing delimiter.
    let close: String
    /// One character (or escape) of the text between holes on a line: never a line break, which only a
    /// `multiline` form holds. It must stop at `close` and at a hole's opening (`\$(?!\{)`, not `\$`); a
    /// character class (`[^"\\$\n]`) keeps the searches fast.
    let literal: String
    /// One whole hole, its own nested brackets and strings included: a whole literal is
    /// `open (hole | literal)* close`.
    let hole: String
    /// What a hole starts with (`\$\{`): a cheap test where `hole` would cost too much.
    let holeOpen: String
    /// The zero-width test that a hole of THIS form just ended, beyond the shared one (`holeClose` behind):
    /// what tells apart the forms painted together, whose tails one rule finds (a `${…}` hole against a
    /// `{…}` one). Empty for a form painted alone or last.
    var afterHole = ""
    /// Whether a literal may span lines.
    var multiline = false
    /// Scope markers (``RuleTables/inside(opens:closes:within:)``) limiting where a literal may open.
    var scope = ""
}
