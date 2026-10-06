//
//  RakuRules.swift
//  CodeHighlighting
//
//  The regex rule table for Raku.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Raku: `#` and embedded `` #`( … ) `` comments, Pod blocks (`=begin x … =end x`, `=for` paragraphs,
/// directive lines, everything after `=END`), the quoting forms (`'…'`, `"…"`, `q[…]`, `qq{…}`,
/// `Q:q[…]`, `q:to/END/` heredocs, `<word lists>`, `｢…｣`, `«…»`, the curly quotes), sigilled
/// variables with their twigils, keywords, types and numbers (`:16<FF>` too). A `::` in a package name
/// (`Cro::HTTP`) is not a symbol.
extension RuleTables {
    static let raku: [(String, TokenKind)] = [
        hashComment,
        (
            "#`(?:\\((?:[^()]|\\([^()]*\\))*\\)|\\[(?:[^\\[\\]]|\\[[^\\[\\]]*\\])*\\]|\\{\\{[\\s\\S]*?\\}\\}|\\{[^{}]*\\}|<[^<>]*>)",
            .comment
        ),
        ("^=begin[ \\t]+([\\w-]+)[\\s\\S]*?^=end[ \\t]+\\1\\b.*$", .comment),
        ("^=for\\b.*(?:\\n(?![ \\t]*$).*)*", .comment),
        ("^=END\\b[\\s\\S]*", .comment),
        // An abbreviated block (`=defn Term`, `=item`, `=head1`) runs to the next blank line; a directive is one line.
        ("^=(?!begin\\b|end\\b|for\\b|config\\b|END\\b)[A-Za-z]\\w*\\b.*(?:\\n(?![ \\t]*$).*)*", .comment),
        ("^=[A-Za-z]\\w*\\b.*$", .comment),
        ("\"(?:[^\"\\\\]|\\\\[\\s\\S])*\"", .string),
        ("'(?:[^'\\\\]|\\\\[\\s\\S])*'", .string),
        // `«words»` (and `<<words>>`) quotes only when a word follows the `«` on its line: `»+«`, `-« (1, 2)` and
        // `<<+>>` are hyper operators.
        ("｢[^｣]*｣|“[^”]*”|‘[^’]*’|„[^“”]*[“”]|«(?![\\s+\\-*/~%^=<>!?&|.,»«])[^»«\\n]*»|<<(?=[\\w\"'$])[^<>\\n]*>>", .string),
        // `q:to/END/` and `qq:to [END]`: the body runs from the next line to the terminator on a line of its own.
        ("(?<![$@%&\\w-])(?:q|qq|Q)(?::!?\\w+)*:to\\s*/(\\w+)/.*\\n[\\s\\S]*?^[ \\t]*\\1[ \\t]*$", .string),
        ("(?<![$@%&\\w-])(?:q|qq|Q)(?::!?\\w+)*:to\\s*\\[(\\w+)\\].*\\n[\\s\\S]*?^[ \\t]*\\1[ \\t]*$", .string),
        (
            "(?<![$@%&\\w-])(?:q|qq|Q)(?:ww|w|x)?(?::!?\\w+)*\\s*(?:\\[(?:[^\\[\\]]|\\[[^\\[\\]]*\\])*\\]|\\{(?:[^{}]|\\{[^{}]*\\})*\\}|\\((?:[^()]|\\([^()]*\\))*\\)|<[^<>]*>|/[^/\\n]*/|'[^'\\n]*'|\"[^\"\\n]*\"|\\|[^|\\n]*\\|)",
            .string
        ),
        ("(?<![\\w\\])}>$@%&])<(?![<=\\s])[\\w \\t-]+>", .string),
        call,
        byFirstLetter(
            .keyword,
            [
                "my", "our", "has", "state", "constant", "sub", "method", "submethod", "multi", "proto", "only", "class", "role",
                "grammar", "module", "package", "unit", "use", "need", "require", "import", "no", "is", "does", "but", "of", "returns",
                "where", "if", "elsif", "else", "unless", "with", "orwith", "without", "for", "loop", "while", "until", "repeat",
                "given", "when", "default", "proceed", "succeed", "last", "next", "redo", "return", "take", "gather", "do", "try",
                "CATCH", "CONTROL", "LEAVE", "ENTER", "BEGIN", "END", "INIT", "KEEP", "UNDO", "FIRST", "NEXT", "LAST", "PRE", "POST",
                "QUIT", "CLOSE", "start", "supply", "react", "whenever", "await", "emit", "done", "let", "temp", "and", "or", "not", "xor",
                "andthen", "orelse", "self", "token", "rule", "regex", "die", "fail", "warn", "so", "say", "put", "print", "note", "enum",
                "subset", "augment", "anon", "handles", "trusts", "also", "macro", "lazy", "eager", "hyper", "race", "quietly",
                "make", "made", "required", "rw", "export", "readonly", "copy", "raw",
            ]),
        byFirstLetter(
            .type,
            [
                "Int", "Str", "Num", "Rat", "FatRat", "Complex", "Bool", "Array", "Hash", "List", "Map", "Set", "Bag", "Mix", "Any", "Mu",
                "Nil", "Cool", "Pair", "Range", "Seq", "Junction", "Failure", "Exception", "Promise", "Supply", "Channel", "IO", "Code",
                "Block", "Routine", "Sub", "Method", "Regex", "Match", "Grammar", "Version", "Instant", "Duration", "DateTime", "Date",
                "Whatever", "Empty", "Positional", "Associative", "Callable", "Numeric", "Real", "Stringy", "Buf", "Blob", "UInt",
            ]),
        ("[$@%&][*?!.^=~:]?[A-Za-z_][\\w'-]*\\w|[$@%&][*?!.^=~:]?[A-Za-z_]", .variable),
        constants(["True", "False", "Inf", "NaN"]),
        (":\\d+<[0-9A-Za-z_.]+>", .number),
        decimal,
    ]

    /// `\b(?:…)\b` of `kind` with the words grouped by their first letter (`m(?:y|ethod|ulti)`): the
    /// same matches as one flat alternation, but each word start tries one group, not every word —
    /// the flat list of over a hundred words cost more than every other rule together.
    private static func byFirstLetter(_ kind: TokenKind, _ words: [String]) -> (String, TokenKind) {
        let groups = Dictionary(grouping: words, by: { $0.first! })
        let alternatives = groups.keys.sorted().map { letter in
            let tails = groups[letter]!.map { String($0.dropFirst()) }.sorted { $0.count > $1.count }
            return String(letter) + "(?:" + tails.joined(separator: "|") + ")"
        }
        return ("\\b(?:" + alternatives.joined(separator: "|") + ")\\b", kind)
    }
}
