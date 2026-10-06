//
//  SASRules.swift
//  CodeHighlighting
//
//  The regex rule table for SAS.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// SAS: the C-like family's table, whose `"…"` strings resolve macro variable references (`&name`, `&&name`,
/// `&name.`), which stay code; a `'…'` string resolves none and paints whole.
extension RuleTables {
    static let sas: [(String, TokenKind)] =
        cLikeFamily.filter { $0.0 != doubleQuoted.0 }
        + interpolatedStringPieces(
            open: "\"", close: "\"", literal: "[^\"\\\\&\\n]|\\\\[\\s\\S]|&(?![&A-Za-z_])", hole: "&+[A-Za-z_]\\w*\\.?", holeOpen: "&",
            holeClose: "[\\w.]", afterHole: "(?<=[\\w.])(?!\\w)(?<![^&\\w]\\w{1,32}|[^&\\w]\\w{1,32}\\.)(?<=&[A-Za-z_]\\w{0,31}\\.?)", multiline: true,
            skip: [blockComment.0, lineComment.0, singleQuoted.0, "%?\\*(?<=(?:^|\\n)[ \\t]{0,40}%?\\*)[^;]*;"])
}
