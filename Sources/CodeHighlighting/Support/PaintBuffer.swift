//
//  PaintBuffer.swift
//  CodeHighlighting
//
//  A stand-in text storage that holds one paint's colours, written to the real storage once, in order.
//
//  Created by David Sherlock on 10/7/26.
//  Copyright © 2026 ArrayPress Limited. MIT licence.
//

import AppKit

/// The colours of one paint of `clip`, held per character and written to the real storage once, left to right.
///
/// A painter that writes a document's parts out of order (a single-file component's script and style first,
/// then the markup above them, then the expressions in that markup) inserts every run into the middle of the
/// storage's attribute array, which moves every run after it: the cost grows with the square of the runs on a
/// large file. Painting into this buffer instead, and copying its runs over in ascending order, makes each
/// insertion an append. Only `.foregroundColor` is held; the clip starts as `foreground`, the colour the
/// caller has just reset it to, and reads outside the clip see the real storage.
final class PaintBuffer: NSTextStorage {
    private let text: NSString
    private let clip: NSRange
    private let target: NSTextStorage
    /// Per character of the clip: the index of its colour in `palette`.
    private var marks: [UInt16]
    private var palette: [NSColor]
    private var paletteIndex: [ObjectIdentifier: UInt16]

    /// A buffer over `clip` of `target`, whose text is `text` and whose clip wears `foreground`.
    init(text: NSString, target: NSTextStorage, clip: NSRange, foreground: NSColor) {
        self.text = text
        self.clip = clip
        self.target = target
        marks = [UInt16](repeating: 0, count: clip.length)
        palette = [foreground]
        paletteIndex = [ObjectIdentifier(foreground): 0]
        super.init()
    }

    required init?(coder: NSCoder) { fatalError("PaintBuffer is never archived") }

    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        fatalError("PaintBuffer is never read from a pasteboard")
    }

    override var string: String { text as String }

    override var length: Int { text.length }

    override func replaceCharacters(in range: NSRange, with str: String) {
        preconditionFailure("PaintBuffer paints colours only")
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        guard NSLocationInRange(location, clip) else {
            let attributes = target.attributes(at: location, effectiveRange: range)
            if let range {
                // The real storage's run stops where the clip starts or after it ends.
                if location < clip.location {
                    range.pointee = NSIntersectionRange(range.pointee, NSRange(location: 0, length: clip.location))
                } else {
                    let after = NSMaxRange(clip)
                    range.pointee = NSIntersectionRange(range.pointee, NSRange(location: after, length: text.length - after))
                }
            }
            return attributes
        }
        let run = self.run(at: location - clip.location)
        range?.pointee = NSRange(location: clip.location + run.lowerBound, length: run.count)
        return [.foregroundColor: palette[Int(marks[location - clip.location])]]
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        paint(attrs?[.foregroundColor] as? NSColor ?? palette[0], range)
    }

    override func addAttribute(_ name: NSAttributedString.Key, value: Any, range: NSRange) {
        guard name == .foregroundColor, let colour = value as? NSColor else { return }
        paint(colour, range)
    }

    override func enumerateAttribute(
        _ attrName: NSAttributedString.Key, in enumerationRange: NSRange, options opts: NSAttributedString.EnumerationOptions = [],
        using block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        guard attrName == .foregroundColor, !opts.contains(.reverse),
            NSEqualRanges(NSIntersectionRange(enumerationRange, clip), enumerationRange)
        else {
            super.enumerateAttribute(attrName, in: enumerationRange, options: opts, using: block)
            return
        }
        var stop: ObjCBool = false
        var i = enumerationRange.location - clip.location
        let end = NSMaxRange(enumerationRange) - clip.location
        while i < end, !stop.boolValue {
            let mark = marks[i]
            var j = i + 1
            while j < end, marks[j] == mark { j += 1 }
            block(palette[Int(mark)], NSRange(location: clip.location + i, length: j - i), &stop)
            i = j
        }
    }

    /// Writes every run that differs from the clip's starting colour to `target`, ascending.
    func flush() {
        var i = 0
        while i < marks.count {
            let mark = marks[i]
            var j = i + 1
            while j < marks.count, marks[j] == mark { j += 1 }
            if mark != 0 {
                target.addAttribute(.foregroundColor, value: palette[Int(mark)], range: NSRange(location: clip.location + i, length: j - i))
            }
            i = j
        }
    }

    /// Paints `range` (clipped to the buffer's clip) `colour`.
    private func paint(_ colour: NSColor, _ range: NSRange) {
        let r = NSIntersectionRange(range, clip)
        guard r.length > 0 else { return }
        let mark: UInt16
        if let known = paletteIndex[ObjectIdentifier(colour)] {
            mark = known
        } else {
            mark = UInt16(palette.count)
            palette.append(colour)
            paletteIndex[ObjectIdentifier(colour)] = mark
        }
        let start = r.location - clip.location
        for i in start..<(start + r.length) { marks[i] = mark }
    }

    /// The run of equal marks around offset `i` of the clip.
    private func run(at i: Int) -> Range<Int> {
        let mark = marks[i]
        var lo = i
        while lo > 0, marks[lo - 1] == mark { lo -= 1 }
        var hi = i + 1
        while hi < marks.count, marks[hi] == mark { hi += 1 }
        return lo..<hi
    }
}
