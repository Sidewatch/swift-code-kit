//
//  PerlRules.swift
//  CodeHighlighting
//
//  The regex rule table for Perl.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// Perl: `#` comments (`$#array` is no comment), POD blocks from `=pod`/`=head1` to `=cut`, the
/// `__END__`/`__DATA__` tail, `"…"`, `'…'` and `` `…` `` strings, here-documents (`<<"END"`, `<<'END'`,
/// `<<~END`) to their terminator line, the quote-like operators `q qq qw qx m qr` with any delimiter
/// (brackets nest one level), `s/…/…/` `tr/…/…/` `y/…/…/` with either form, `/…/` where a regex
/// starts, the keywords and named operators, sigiled variables, and numbers.
extension RuleTables {
    static let perl: [(String, TokenKind)] = [
        ("^=[a-zA-Z]\\w*[\\s\\S]*?(?:^=cut\\b.*$|\\z)", .comment),
        ("^__(?:END|DATA)__$[\\s\\S]*", .comment),
        ("<<~?(?:\"([A-Za-z_]\\w*)\"|'([A-Za-z_]\\w*)'|([A-Za-z_]\\w*))[^\\n]*\\n[\\s\\S]*?^[ \\t]*(?:\\1|\\2|\\3)$", .string),
        doubleQuoted,
        singleQuoted,
        backQuoted,
        ("(?<![\\w$@%&:>-])(?:qq|qw|qx|qr|q|m)" + perlDelimited + "[a-z]*", .string),
        ("(?<![\\w$@%&:>-])(?:s|tr|y)" + perlSubstitution + "[a-z]*", .string),
        (
            "(?<=(?:=~|!~|[(,;{!]|&&|\\|\\||\\b(?:split|if|unless|and|or|not|return|grep|when))[ \\t]{0,8})/(?![/*=\\s])(?:[^/\\\\\\n]|\\\\.)*/[a-z]*",
            .string
        ),
        callee,
        keywords([
            "my", "our", "local", "state", "sub", "package", "use", "no", "require", "return", "if", "elsif", "else",
            "unless", "while", "until", "for", "foreach", "do", "last", "next", "redo", "goto", "and", "or", "not", "xor",
            "eq", "ne", "lt", "gt", "le", "ge", "cmp", "x", "isa", "BEGIN", "END", "INIT", "CHECK", "UNITCHECK", "given",
            "when", "default", "try", "catch", "finally", "defer", "class", "method", "field", "ADJUST", "format",
            "__PACKAGE__", "__FILE__", "__LINE__", "__SUB__",
        ]),
        ("[$@%]\\{?\\^?[A-Za-z_][\\w:]*\\}?|\\$#\\{?[A-Za-z_]\\w*|\\$[0-9!@/\\\\;&`'+_.,$]", .variable),
        decimal,
    ]

    /// A quote-like body: a bracket pair with one level of nesting, or the same punctuation at both ends.
    static let perlDelimited =
        "(?:\\s*\\((?:[^()\\\\]|\\\\.|\\([^()]*\\))*\\)|\\s*\\{(?:[^{}\\\\]|\\\\.|\\{[^{}]*\\})*\\}|\\s*\\[(?:[^\\[\\]\\\\]|\\\\.)*\\]"
        + "|\\s*<(?:[^<>\\\\]|\\\\.)*>|([^\\w\\s=,;)}>\\]])(?:(?!\\1)[^\\\\\\n]|\\\\.)*\\1)"

    /// A substitution or transliteration: `s/a/b/`, or a bracketed pattern followed by a bracketed or
    /// delimited replacement (`s{a}{b}`, `s{a}[b]`).
    static let perlSubstitution =
        "(?:([^\\w\\s=,;)}>\\]({\\[<])(?:(?!\\1)[^\\\\\\n]|\\\\.)*\\1(?:(?!\\1)[^\\\\\\n]|\\\\.)*\\1"
        + "|(?:\\s*\\{(?:[^{}\\\\]|\\\\.|\\{[^{}]*\\})*\\}|\\s*\\((?:[^()\\\\]|\\\\.)*\\)|\\s*\\[(?:[^\\[\\]\\\\]|\\\\.)*\\]|\\s*<(?:[^<>\\\\]|\\\\.)*>)"
        + "\\s*(?:\\{(?:[^{}\\\\]|\\\\.|\\{[^{}]*\\})*\\}|\\((?:[^()\\\\]|\\\\.)*\\)|\\[(?:[^\\[\\]\\\\]|\\\\.)*\\]|<(?:[^<>\\\\]|\\\\.)*>|([^\\w\\s])(?:(?!\\2)[^\\\\\\n]|\\\\.)*\\2))"
}
