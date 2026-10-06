//
//  RuleScope.swift
//  CodeHighlighting
//
//  Where a rule-table rule may match: inside a region such as a template tag or a script block.
//
//  Created by David Sherlock on 10/2/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation
import FoundationExtensions

/// Where a rule may match: inside the regions one regex finds — a template tag from its open to its
/// close, a `<cfscript>` block. A rule table stays `[(String, TokenKind)]`: a scoped rule's pattern opens
/// with one `(?#in:…)` marker per scope (a regex comment, so the pattern still compiles on its own),
/// and ``SyntaxHighlighter`` keeps only the matches that START inside one of the rule's regions. The
/// regions are found once per paint with a forward scan, where a look back on every candidate would
/// rescan the same text again and again.
///
/// A region pattern with a group named `region` (``marker(steppingOver:regions:within:)``) makes only that
/// group's range a region: the scan's other matches, and the rest of a match, are text it steps over to stay
/// in step, never regions.
struct RuleScope {
    /// Finds the regions, each from an open delimiter to its close (included), or a bounded length.
    let region: NSRegularExpression
    /// How far before a painted range a region can start and still reach into it.
    let reach: Int
    /// Whether only the `region` group of a match is a region (see the type's documentation).
    let regionGroupOnly: Bool

    /// The marker that scopes a rule to the text between one of `opens` and the next of `closes`
    /// (regex forms, close included), at most `within` characters after the open.
    static func marker(opens: [String], closes: [String], within: Int) -> String {
        let close = closes.joined(separator: "|")
        let pattern = "(?:" + opens.joined(separator: "|") + ")(?:(?!" + close + ")[\\s\\S]){0,\(within)}(?:" + close + ")?"
        return prefix + Data((pattern + "\u{1}\(within + 64)").utf8).base64EncodedString() + ")"
    }

    /// The marker that scopes a rule to the regions one forward scan finds: at each place it tries `skip`
    /// first, each match of which is passed over whole and is never a region (so a quote inside a comment or
    /// another string form cannot put the scan out of step), then `regions` (a regex, at most `within`
    /// characters long), of which the part marked ``region(_:)`` is the region, or all of it when no part is.
    static func marker(steppingOver skip: [String], regions: String, within: Int) -> String {
        let marked = regions.contains("(?<\(regionGroup)>") ? regions : region(regions)
        return marker(opens: skip + [marked], closes: [""], within: within)
    }

    /// `pattern` marked as the region part of a match (``marker(steppingOver:regions:within:)``).
    static func region(_ pattern: String) -> String { "(?<\(regionGroup)>\(pattern))" }

    /// `pattern`'s leading scope markers, decoded, and the pattern without them. A marker that does
    /// not decode is left in place, where it is an ordinary regex comment.
    static func split(_ pattern: String) -> (scopes: [RuleScope], body: String) {
        var scopes: [RuleScope] = []
        var rest = Substring(pattern)
        while rest.hasPrefix(prefix), let end = rest.firstIndex(of: ")") {
            let payload = rest[rest.index(rest.startIndex, offsetBy: prefix.count)..<end]
            guard let data = Data(base64Encoded: String(payload)), let decoded = data.utf8String,
                let separator = decoded.lastIndex(of: "\u{1}"), let reach = Int(decoded[decoded.index(after: separator)...]),
                let regex = try? NSRegularExpression(pattern: String(decoded[..<separator]), options: [])
            else { break }
            scopes.append(RuleScope(region: regex, reach: reach, regionGroupOnly: regex.pattern.contains("(?<\(regionGroup)>")))
            rest = rest[rest.index(after: end)...]
        }
        return (scopes, String(rest))
    }

    /// The regions that can reach into `range` of `text`, ascending and non-overlapping.
    func regions(in text: String, around range: NSRange) -> [NSRange] {
        let start = max(0, range.location - reach)
        let search = NSRange(location: start, length: NSMaxRange(range) - start)
        return region.matches(in: text, options: [], range: search).compactMap { match in
            let r = regionGroupOnly ? match.range(withName: Self.regionGroup) : match.range
            return r.location == NSNotFound || NSMaxRange(r) <= range.location ? nil : r
        }
    }

    /// Several region lists as one: ascending, overlaps merged.
    static func union(_ lists: [[NSRange]]) -> [NSRange] {
        var merged: [NSRange] = []
        for r in lists.joined().sorted(by: { $0.location < $1.location }) {
            if let last = merged.last, r.location <= NSMaxRange(last) {
                merged[merged.count - 1] = NSUnionRange(last, r)
            } else {
                merged.append(r)
            }
        }
        return merged
    }

    /// Whether `location` lies inside one of `regions` (ascending, non-overlapping).
    static func contains(_ location: Int, in regions: [NSRange]) -> Bool {
        var lo = 0
        var hi = regions.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if NSMaxRange(regions[mid]) <= location { lo = mid + 1 } else { hi = mid }
        }
        return lo < regions.count && regions[lo].location <= location
    }

    /// The first place at or after `location` that lies inside one of `regions` (ascending,
    /// non-overlapping): `location` itself when a region holds it, else the next region's start; nil
    /// when no region reaches past it.
    static func firstStart(atOrAfter location: Int, in regions: [NSRange]) -> Int? {
        var lo = 0
        var hi = regions.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if NSMaxRange(regions[mid]) <= location { lo = mid + 1 } else { hi = mid }
        }
        return lo < regions.count ? max(location, regions[lo].location) : nil
    }

    private static let prefix = "(?#in:"

    /// The group name that marks the region part of a region pattern.
    private static let regionGroup = "region"
}
