//
//  TemplateTagMemo.swift
//  CodeHighlighting
//
//  A text's template tags, found once per version of it.
//
//  Created by David Sherlock on 10/29/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// The template tags a session's text holds (``TreeSitterHighlighter/templateTagRanges(in:within:)``), found once per
/// version of the text for each set of ranges asked about. Every highlight pass over an HTML document asks for the
/// whole document's tags, and finding them read the whole document each time: 5.5 s a pass on a 16 MB file read
/// through its text storage.
struct TemplateTagMemo {
    /// The version of the text the remembered tags were found in.
    private var generation: Int?
    private var found: [[NSRange]: TreeSitterHighlighter.TemplateTags] = [:]
    /// How many times the tag regex has searched, for tests.
    private(set) var searches = 0

    /// The tags in `ranges` of `units`, version `generation` of the text: searched for on the first ask, remembered
    /// until the version changes.
    mutating func tags(within ranges: [NSRange], units: [UInt16], generation: Int) -> TreeSitterHighlighter.TemplateTags {
        if generation != self.generation {
            self.generation = generation
            found = [:]
        }
        if let hit = found[ranges] { return hit }
        let (tags, searched) = TreeSitterHighlighter.templateTagRanges(inUnits: units, within: ranges)
        if searched { searches += 1 }
        found[ranges] = tags
        return tags
    }
}
