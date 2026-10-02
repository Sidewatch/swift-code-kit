//
//  TerraformRules.swift
//  CodeHighlighting
//
//  The regex rule table for Terraform / HCL.
//
//  Created by David Sherlock on 9/5/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The regex rule table for Terraform / HCL: `#`, `//` and `/* */` comments; `<<EOT` / `<<-EOT`
/// heredocs, a string up to the line that holds only their marker; quoted strings whose `${ … }`
/// interpolations may hold quoted strings of their own, two levels deep; a block's labels
/// (`resource "aws_instance" "web" {`) as names, not strings — unless a label holds `#`, `//` or `/*`,
/// which only a string keeps from opening a comment; the block words and type constraints.
/// Later rules repaint earlier ones; strings and comments paint last.
extension RuleTables {
    /// What follows a block label: more labels, then the block's `{`.
    private static let hclRestOfBlockHeader = #"[ \t]*(?:"[^"\n]*"[ \t]*)*\{"#
    /// A label with no comment opener in it, painted as a name.
    private static let hclNameLabel = #""(?:[^"\n#/]|/(?![/*]))*""#

    static let terraform: [(String, TokenKind)] = [
        hashComment,
        lineComment,
        blockComment,
        (#"<<-?([A-Za-z_][\w-]*)[ \t]*\n[\s\S]*?^[ \t]*\1[ \t]*$"#, .string),
        // A string that is not a name label, nor the gap between two labels (`" "` in `"a" "b" {`).
        (
            "(?!\(hclNameLabel)\(hclRestOfBlockHeader))\"" + dollarBraceStringBody(multiline: false)
                + "\"(?![^\"\\n]*\"\(hclRestOfBlockHeader))",
            .string
        ),
        (hclNameLabel + "(?=\(hclRestOfBlockHeader))", .type),
        keywords([
            "resource", "variable", "provider", "module", "data", "output", "locals", "terraform", "backend",
            "provisioner", "connection", "lifecycle", "moved", "import", "removed", "check", "for", "in", "if",
            "dynamic", "count", "depends_on", "true", "false", "null",
        ]),
        types(["string", "number", "bool", "list", "map", "set", "object", "tuple", "optional", "any"]),
        ("^\\s*[a-zA-Z_][\\w-]*(?=\\s*=)", .function),  // attribute keys
        decimal,
    ]
}
