//
//  PrismaRules.swift
//  CodeHighlighting
//
//  The regex rule table for Prisma.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Prisma: `//` comments, `"…"` strings with escapes, the block words and the name
/// each block declares (`generator client`, `model Order`), `@attributes` and `@@block` attributes with a native
/// type's `.VarChar` tail in the attribute colour, capitalised names as types, and numbers with their sign.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    static let prisma: [(String, TokenKind)] = [
        lineComment,
        doubleQuoted,
        ("\\b(?:model|enum|datasource|generator|type|view)[ \\t]+[A-Za-z_]\\w*", .type),
        keywords(["model", "enum", "datasource", "generator", "type", "view"]),
        ("\\b[A-Z]\\w*\\b", .type),  // field types / models
        ("@@?\\w+(?:\\.\\w+)*", .attribute),  // @id, @@map, @default, @db.VarChar…
        decimal,
        ("-(?<=[(\\[,:=][ \\t]{0,8}-)(?=\\d)", .number),  // the sign of a negative number
    ]
}
