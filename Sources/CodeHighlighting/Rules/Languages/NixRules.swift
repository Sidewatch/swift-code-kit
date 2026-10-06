//
//  NixRules.swift
//  CodeHighlighting
//
//  The regex rule table for Nix.
//
//  Created by David Sherlock on 9/25/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Nix: `#` and block comments, `"…"` and `''…''` strings, the expression words, attribute
/// names before `=`, function arguments before `:`, paths and `<search-paths>`, the standard
/// library names. An indented string's `'''`, `''$` and `''\n` are escapes, not its end; a `"…"`
/// string's `${ … }` may hold quoted strings of its own.
extension RuleTables {
    static let nix: [(String, TokenKind)] =
        [
            hashComment,
            blockComment,
        ]
        // A `"…"` string, an indented `''…''` string and a path each keep their `${ … }` holes code. A `}` with
        // another `}` ahead in the same run of text closes a `${ … }` nested in the hole (`${pkgs.${system}.x}`).
        + interpolatedStringPieces(
            open: "\"", close: "\"", literal: "[^\"\\\\$\\n]|\\\\[\\s\\S]|\\$(?!\\{)", hole: nixHole, holeOpen: "\\$\\{",
            holeClose: "\\}", afterHole: "(?<=\\})(?![^\"\\n{}]*\\})", multiline: true, skip: [hashComment.0, blockComment.0, nixIndented])
        + interpolatedStringPieces(
            open: "''", close: "''(?![$'\\\\])", literal: "[^'$\\n]|'(?!')|''(?:'|\\$|\\\\[\\s\\S])|\\$(?!\\{)", hole: nixHole,
            holeOpen: "\\$\\{", holeClose: "\\}", afterHole: "(?<=\\})(?![^'\\n{}]*\\})", multiline: true,
            skip: [hashComment.0, blockComment.0, nixQuoted])
        // A path segment starts with a name character, so the `//` update operator is no path. A path's
        // text after a hole starts with `/` or `.`, which keeps its tail's search cheap.
        + interpolatedStringPieces(
            open: "(?:\\.\\.?|~)?/(?=[\\w.+-]|\\$\\{)", close: "(?![\\w./+-]|\\$\\{)", literal: "[\\w./+-]",
            hole: "\\$\\{[^{}\\n]*\\}", holeOpen: "\\$\\{", holeClose: "\\}", afterHole: "(?=[/.])(?<=\\})")
        + [
            keywords(["let", "in", "with", "rec", "inherit", "if", "then", "else", "assert", "or", "import", "throw", "abort"]),
            ("\\b(true|false|null)\\b", .number),
            ("<[\\w./-]+>", .string),
            ("\\b(builtins|lib|pkgs|stdenv|self|super|config|options|system|inputs|outputs|nixpkgs|flake-utils)\\b", .type),
            (
                "\\b(mkDerivation|mkShell|fetchurl|fetchFromGitHub|fetchgit|map|filter|toString|concatStringsSep|attrValues|attrNames|mapAttrs|genAttrs|optional|optionals|optionalString|callPackage|writeText|writeShellScriptBin|eachDefaultSystem|eachSystem|listToAttrs|hasAttr|getAttr|readFile|fromJSON|toJSON|elem|length|head|tail|foldl|foldr|substring|stringLength|replaceStrings|splitString|removeSuffix|removePrefix)\\b",
                .function
            ),
            ("\\b[a-zA-Z_][\\w'-]*(?=\\s*=[^=])", .property),
            ("\\b[a-zA-Z_][\\w'-]*(?=\\s*:(?!:))", .variable),
            ("\\$\\{|\\}", .keyword),
            ("\\b\\d+(\\.\\d+)?\\b", .number),
        ]

    /// A `${ … }` hole: braces and strings inside it, strings holding holes three levels deep
    /// (`"a${"b${"c"}"}d"`, `${self.packages.${system}.default}`).
    private static let nixHole: String = {
        let flat = "\"(?:[^\"\\\\$]|\\\\[\\s\\S]|\\$(?!\\{))*\""
        func string(_ hole: String) -> String { "\"(?:[^\"\\\\$]|\\\\[\\s\\S]|\\$(?!\\{)|\(hole))*\"" }
        let inner = "\\$\\{(?:[^{}\"]|\(flat))*\\}"
        let braces = "\\{(?:[^{}\"]|\(string(inner))|\\{[^{}\"]*\\})*\\}"
        let middle = "\\$\\{(?:[^{}\"]|\(string(inner))|\(braces))*\\}"
        return "\\$\\{(?:[^{}\"]|\(string(middle))|\\{(?:[^{}\"]|\(string(middle))|\(braces))*\\})*\\}"
    }()

    /// A whole indented string, `''…''`, for the scan for `"…"` strings to step over.
    private static let nixIndented = "''(?:[^']|'(?!')|''(?:'|\\$|\\\\[\\s\\S]))*''"

    /// A whole `"…"` string, for the scan for indented strings to step over.
    private static let nixQuoted = "\"(?:[^\"\\\\]|\\\\[\\s\\S])*\""
}
