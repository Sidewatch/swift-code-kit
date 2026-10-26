//
//  FileKind.swift
//  CodeLanguage
//
//  The non-code kinds a file can be, each shown by its own preview: images, sound, video, fonts,
//  archives, databases, PDFs and 3D models.
//
//  Created by David Sherlock on 10/26/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import Foundation

/// A non-code kind of file, told by its extension: the preview that shows it and the glyph a file
/// list gives it. ``extensions`` is each kind's one list, read by both.
public enum FileKind: String, CaseIterable, Sendable {
    case image
    case audio
    case video
    case font
    case archive
    case database
    case pdf
    case model
}
