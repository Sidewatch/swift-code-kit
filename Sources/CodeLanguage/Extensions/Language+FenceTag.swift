//
//  Language+FenceTag.swift
//  CodeLanguage
//
//  The language a Markdown code fence names.
//
//  Created by David Sherlock on 10/21/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

public extension Language {
    /// The language a Markdown fence's tag names (```` ```python ````), or nil when it names none: the
    /// tag's first word, any case, as a language name (`python`, `rust`, `typescript`) and then as a file
    /// extension (`py`, `rs`, `ts`). A tag that only reaches plain text is nil, so the block stays plain.
    init?(fenceTag: String) {
        let word = fenceTag.trimmingCharacters(in: .whitespaces).prefix { !$0.isWhitespace && $0 != "{" }.lowercased()
        guard !word.isEmpty else { return nil }
        if let named = Language(rawValue: word), named != .plainText {
            self = named
            return
        }
        let detected = Language.detect(filename: "block." + word)
        guard detected != .plainText else { return nil }
        self = detected
    }
}
