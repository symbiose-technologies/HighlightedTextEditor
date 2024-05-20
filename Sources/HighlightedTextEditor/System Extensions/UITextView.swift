//
//  UITextView.swift
//
//
//  Created by Kyle Nazario on 11/13/20.
//

#if os(iOS)
import Foundation
import UIKit

public extension UITextView {
    var markedTextNSRange: NSRange? {
        guard let markedTextRange = markedTextRange else { return nil }
        let location = offset(from: beginningOfDocument, to: markedTextRange.start)
        let length = offset(from: markedTextRange.start, to: markedTextRange.end)
        return NSRange(location: location, length: length)
    }
    
    var naiveDisplayedLineCount: Int {
//        guard let layoutManager = self.layoutManager else {
//            return 0
//        }
        
        let visibleRect = self.bounds
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: self.textContainer)
        
        var numberOfLines = 0
        layoutManager.enumerateLineFragments(forGlyphRange: visibleGlyphRange) { (_, _, _, _, _) in
            numberOfLines += 1
        }
        
        return numberOfLines
    }
    
    
    @discardableResult
    func insertTextAtCurrentCursor(textToInsert: String) -> Bool {
        guard let selectedRange = self.selectedTextRange else { return false }

        let cursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
        let updatedText = NSMutableAttributedString(attributedString: self.attributedText)
        
        updatedText.insert(NSAttributedString(string: textToInsert), at: cursorPosition)
        self.attributedText = updatedText
        return true
    }
    
}



#endif
