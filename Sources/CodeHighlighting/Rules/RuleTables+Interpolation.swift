//
//  RuleTables+Interpolation.swift
//  CodeHighlighting
//
//  RuleTables: a `"…"` string whose `${ … }` interpolations may hold quoted strings of their own.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

extension RuleTables {
    /// The body of a `"…"` string (no quotes) whose `${ … }` interpolations may hold quoted strings that
    /// interpolate again, two levels deep — `"a ${f("b ${x}")} c"` is one string, not three. A regex
    /// cannot count, and two levels is what real files use. When `multiline` is false no part of it
    /// crosses a line end.
    static func dollarBraceStringBody(multiline: Bool) -> String {
        let nl = multiline ? "" : "\\n"
        let escape = multiline ? "\\\\[\\s\\S]" : "\\\\."
        let object = "\\{[^{}\(nl)]*\\}"
        let leaf = "(?:[^{}\"\(nl)]|\"[^\"\(nl)]*\"|\(object))*"
        let inner = "(?:[^\"\\\\$\(nl)]|\(escape)|\\$(?!\\{)|\\$\\{\(leaf)\\})*"
        let interpolation = "(?:[^{}\"\(nl)]|\"\(inner)\"|\(object))*"
        return "(?:[^\"\\\\$\(nl)]|\(escape)|\\$(?!\\{)|\\$\\{\(interpolation)\\})*"
    }
}
