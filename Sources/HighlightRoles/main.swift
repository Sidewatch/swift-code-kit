//
//  main.swift
//  HighlightRoles
//
//  `swift run highlight-roles <languages-dir> <out-dir> [folder,…]`: every showcase's colours as roles.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit
import CodeHighlighting
import CodeLanguage

// Paints each `<languages-dir>/<folder>/<file>` with the editor's three tiers (tree-sitter, the
// single-file-component splitter, the regex tables — `HighlightedHTML`'s order) and writes its
// colour runs as roles to `<out-dir>/<folder>__<file>.json`: `{"language", "length", "runs":
// [[offset, length, role]]}` in UTF-16 units, the format `scripts/highlight-oracle/compare-highlighting.py`
// in the app reads. Every role gets its own colour here, so a run's role is exact rather than read
// back from a theme where two roles can share one. The grammar query bundles sit beside the built
// executable, which is where `Bundle.main` looks.

/// One distinct colour per role; the foreground is the only grey.
struct RoleColors: TokenColorProviding {
    static let roles: [(TokenKind, String)] = [
        (.comment, "comment"), (.string, "string"), (.keyword, "keyword"), (.type, "type"), (.number, "number"),
        (.function, "function"), (.attribute, "attribute"), (.variable, "variable"), (.property, "property"),
        (.added, "added"), (.removed, "removed"),
    ]
    func color(for kind: TokenKind) -> NSColor {
        let index = Self.roles.firstIndex { $0.0 == kind } ?? 0
        return NSColor(srgbRed: CGFloat(index + 1) / 16, green: 0.5, blue: 0.25, alpha: 1)
    }
    var foreground: NSColor { NSColor(srgbRed: 0.9, green: 0.9, blue: 0.9, alpha: 1) }

    /// The role a painted colour stands for.
    func role(of colour: NSColor?) -> String {
        guard let c = colour?.usingColorSpace(.sRGB) else { return "plain" }
        let fg = foreground
        if c.alphaComponent < 1 { return c.withAlphaComponent(1) == fg ? "muted" : "other" }
        if c == fg { return "plain" }
        return Self.roles.first { color(for: $0.0) == c }?.1 ?? "other"
    }
}

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: highlight-roles <languages-dir> <out-dir> [folder,…]")
    exit(2)
}
let root = URL(fileURLWithPath: args[1], isDirectory: true)
let out = URL(fileURLWithPath: args[2], isDirectory: true)
let only = args.count > 3 ? Set(args[3].split(separator: ",").map(String.init)) : nil
let fm = FileManager.default
try? fm.createDirectory(at: out, withIntermediateDirectories: true)

MainActor.assumeIsolated {
    let colors = RoleColors()
    HighlightTheme.colors = colors
    var written = 0
    for folder in ((try? fm.contentsOfDirectory(atPath: root.path)) ?? []).sorted() where folder != "picker-only" {
        if let only, !only.contains(folder) { continue }
        let dir = root.appendingPathComponent(folder)
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { continue }
        for name in ((try? fm.contentsOfDirectory(atPath: dir.path)) ?? []).sorted() where name != ".DS_Store" {
            let url = dir.appendingPathComponent(name)
            guard let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            let language = Language.detect(for: url)
            let storage = NSTextStorage(string: text, attributes: [.foregroundColor: colors.foreground])
            let full = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            if let tree = TreeSitterHighlighter(language: language) {
                tree.highlight(storage, in: full)
            } else if let component = EmbeddedMarkupHighlighter(language: language, colors: colors) {
                component.highlight(storage, in: full)
            } else {
                SyntaxHighlighter(language: language, colors: colors).highlight(storage, in: full)
            }
            storage.endEditing()
            var runs: [[Any]] = []
            storage.enumerateAttribute(.foregroundColor, in: full) { value, range, _ in
                let role = colors.role(of: value as? NSColor)
                if let last = runs.last, last[2] as? String == role, let start = last[0] as? Int, let length = last[1] as? Int,
                    start + length == range.location
                {
                    runs[runs.count - 1][1] = length + range.length
                } else {
                    runs.append([range.location, range.length, role])
                }
            }
            let json: [String: Any] = ["language": language.rawValue, "length": storage.length, "runs": runs]
            if let data = try? JSONSerialization.data(withJSONObject: json) {
                try? data.write(to: out.appendingPathComponent("\(folder)__\(name).json"))
                written += 1
            }
        }
    }
    print("wrote \(written) role files to \(out.path)")
}
