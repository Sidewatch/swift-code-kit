//
//  RuleTables+InterpolatedStrings.swift
//  CodeHighlighting
//
//  A string literal painted as the pieces between its interpolation holes, so the code in a hole stays code.
//
//  Created by David Sherlock on 10/6/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A string literal whose interpolation holes (`${…}`, `#{…}`, `$(…)`, `\(…)`, `{…}`, `$name`) keep code
/// colours, as VS Code paints them. Strings and comments paint last, in one left-to-right pass where the
/// earliest match wins its whole span, so the code in a hole keeps its colours only if no string match
/// covers it: the literal is painted in pieces that leave its holes unpainted. The HEAD runs from the opening
/// delimiter to the first hole (or the close); a TAIL from just after a hole to the next hole, the close or the
/// line's end; a CONTINUATION from a line break in the literal's text to the next hole, the close or the
/// next line break. A string inside a hole is matched by the head rule like any other, so holes nest.
///
/// A look back alone cannot tell whether a `}` closes a hole inside a literal or a brace in code: the
/// literal's opening delimiter may lie any distance back, and a bounded look back cannot reach it. A tail is
/// instead scoped (``RuleScope``) to the whole literals one forward scan finds, holes included, and looks back only
/// at the hole's last characters; a continuation is scoped to the text after a hole, which a second scan
/// finds piece by piece (so a line break inside a hole that spans lines opens none). Both scans step over
/// `skip` (comments, the other string forms) to keep in step with the quotes. A scan starts some way before
/// the painted range, wherever that falls: a literal that ends on its line puts it back in step at the next
/// line, one that crosses lines only where the quotes pair up again. Tails and continuations stop at a line
/// break so that a candidate the scope then rejects (after a `}` in plain code) costs one line, not the text
/// up to the next quote.
extension RuleTables {
    /// The head, tail and continuation rules of one form of literal from `open` to `close`; the parts are
    /// those of ``InterpolatedStringForm``, the rest as for
    /// ``interpolatedStringPieces(_:holeClose:afterHole:skip:)``.
    static func interpolatedStringPieces(
        open: String, close: String, literal: String, hole: String, holeOpen: String, holeClose: String, afterHole: String? = nil,
        multiline: Bool = false, skip: [String] = [], scope: String = ""
    ) -> [(String, TokenKind)] {
        let form = InterpolatedStringForm(
            open: open, close: close, literal: literal, hole: hole, holeOpen: holeOpen, multiline: multiline, scope: scope)
        return interpolatedStringPieces([form], holeClose: holeClose, afterHole: afterHole, skip: skip)
    }

    /// The rules of several forms of literal at once: a head per form, ONE tail rule for them all (a tail's
    /// search opens with a look back, which runs at every character, so each such rule is a pass over the
    /// text), and a continuation per `multiline` form.
    ///
    /// - `holeClose`: what every form's hole ends with, as a bounded look back sees it (`\}`, `\)`), and never
    ///   a `close`. An `open` right after one closes its literal and never opens one, or the longer head would
    ///   beat the tail that starts at the same place.
    /// - `afterHole`: the zero-width test that a hole ends just here, where a tail may start; by default
    ///   `holeClose` behind and no second `holeClose` ahead (in `#{f(x)}` the first bracket closes the
    ///   call, and in `#{ {{x}} }` only the last brace ends the hole). A hole that can end with a name
    ///   (`$name`) or a bracket of nested code (`$(length(x))`) needs its own. Each form's own test
    ///   (``InterpolatedStringForm/afterHole``) then picks its tail, in the order given.
    /// - `skip`: what the scans step over, tried first and never a place a piece may start: comments and
    ///   the other string forms (a `"""…"""` before the `"…"` it starts with).
    static func interpolatedStringPieces(
        _ forms: [InterpolatedStringForm], holeClose: String, afterHole: String? = nil, skip: [String] = []
    ) -> [(String, TokenKind)] {
        let holeClose = "(?:\(holeClose))"
        let whole = forms.map { "(?:\($0.open))(?:(?:\($0.hole))|\(text(of: $0)))*(?:\($0.close))" }
        let inLiteral = RuleScope.marker(steppingOver: skip, regions: whole.joined(separator: "|"), within: 4000)
        let tails = forms.map { "\($0.afterHole)(?:(?:\($0.literal))+(?:\($0.close))?|(?:\($0.close)))" }
        var rules = forms.map { form in
            (form.scope + "(?:\(form.open))(?<!\(holeClose)(?:\(form.open)))\(text(of: form))*(?:\(form.close))?", TokenKind.string)
        }
        rules.append((inLiteral + (afterHole ?? "(?<=\(holeClose))(?!\(holeClose))") + "(?:\(tails.joined(separator: "|")))", .string))
        for (i, form) in forms.enumerated() where form.multiline {
            let others = whole.enumerated().filter { $0.offset != i }.map(\.element)
            rules.append(continuation(of: form, holeClose: holeClose, skip: skip + others))
        }
        return rules
    }

    /// A line of a form's text: one `literal`, or a line break when the form is `multiline`.
    private static func text(of form: InterpolatedStringForm) -> String {
        form.multiline ? "(?:\(form.literal)|\\n)" : "(?:\(form.literal))"
    }

    /// The rule for each line after the first of the text after a hole: from the line break to the next hole,
    /// the close or the next line break. Its scope is that text alone, which a scan finds a literal at a
    /// time: the text after the open (passed over), then each hole with the text after it (the region), the
    /// next one starting where the last stopped (`\G`). A match that ends at a close, or a skip match, takes
    /// the first character of a hole right after it, so a hole in plain code next to a literal (`"a"${b}`)
    /// never continues it, and a line break inside a hole is in no region.
    private static func continuation(of form: InterpolatedStringForm, holeClose: String, skip: [String]) -> (String, TokenKind) {
        let (open, close, hole, holeOpen) = ("(?:\(form.open))", "(?:\(form.close))", "(?:\(form.hole))", "(?=\(form.holeOpen))")
        let end = "(?:\(close)(?:\(holeOpen)[\\s\\S])?|\(holeOpen))"
        let pieces =
            "\(open)(?<!\(holeClose)\(open))\(text(of: form))*\(end)|\(holeOpen)\\G\(hole)" + RuleScope.region("\(text(of: form))*") + end
        let inText = RuleScope.marker(steppingOver: skip.map { "(?:\($0))(?:\(holeOpen)[\\s\\S])?" }, regions: pieces, within: 4000)
        return (inText + "\\n(?:\(form.literal))*\(close)?", .string)
    }

    /// A JavaScript template literal, `` `a ${b} c` ``, which may span lines; a hole holds braces three deep,
    /// strings and template literals of its own (Marko, MDX, Razor's scripts).
    static func templateLiteralForm(scope: String = "") -> InterpolatedStringForm {
        let quoted = "\"(?:[^\"\\\\\\n]|\\\\.)*\"|'(?:[^'\\\\\\n]|\\\\.)*'"
        let inner = "`(?:[^`\\\\$]|\\\\[\\s\\S]|\\$(?!\\{)|\\$\\{[^{}`]*\\})*`"
        let code = "[^{}`\"']|\(quoted)|\(inner)"
        return InterpolatedStringForm(
            open: "`", close: "`", literal: "[^`\\\\$\\n]|\\\\[\\s\\S]|\\$(?!\\{)",
            hole: "\\$\\{(?:\(code)|\\{(?:\(code)|\\{(?:\(code))*\\})*\\})*\\}", holeOpen: "\\$\\{", multiline: true, scope: scope)
    }

    /// The rules of ``templateLiteralForm(scope:)`` alone; `skip` as for
    /// ``interpolatedStringPieces(_:holeClose:afterHole:skip:)``.
    static func templateLiteralPieces(skip: [String], scope: String = "") -> [(String, TokenKind)] {
        interpolatedStringPieces([templateLiteralForm(scope: scope)], holeClose: "\\}", skip: skip)
    }

    /// A Ruby-style `"…"` string whose `#{ … }` holes may hold strings with holes of their own, two levels
    /// deep (`"a #{"b #{c}"}"`); it ends on its line unless `multiline` (ERB, Haml, Slim).
    static func rubyStringPieces(multiline: Bool, skip: [String], scope: String = "") -> [(String, TokenKind)] {
        let nl = multiline ? "" : "\\n"
        let text = "[^\"\\\\#\\n]|\\\\" + (multiline ? "[\\s\\S]" : ".") + "|#(?!\\{)"
        let leaf = "#\\{(?:[^{}\"\(nl)]|\"(?:[^\"\\\\\(nl)]|\\\\.)*\"|\\{[^{}\(nl)]*\\})*\\}"
        let inner = "\"(?:\(text)|\(leaf))*\""
        let hole = "#\\{(?:[^{}\"\(nl)]|\(inner)|\\{[^{}\(nl)]*\\})*\\}"
        return interpolatedStringPieces(
            open: "\"", close: "\"", literal: text, hole: hole, holeOpen: "#\\{", holeClose: "\\}", multiline: multiline, skip: skip,
            scope: scope)
    }
}
