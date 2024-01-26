//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/5/23.
//
#if os(macOS)
import Foundation
import AppKit



public extension SymNSTextView {

    /**
     The spacing between the text view's edge and its text.

     This is an alias for `textContainerInset`, to make sure
     that the text view has a platform-agnostic API.
     */
    var textContentInset: CGSize {
        get { textContainerInset }
        set { textContainerInset = newValue }
    }
    
    var numberOfDisplayedLines: Int {
        guard let layoutManager = self.layoutManager, let textContainer = self.textContainer else {
            return 0
        }
        
        var numberOfLines = 0
        let visibleRect = self.visibleRect
        
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        layoutManager.enumerateLineFragments(forGlyphRange: glyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
            numberOfLines += 1
        }
        
        return numberOfLines
    }
    
    
    func insertTextAtCursor(textToInsert: String) {
        let range = self.selectedRange()
        if let textStorage = self.textStorage {
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: range, with: textToInsert)
            textStorage.endEditing()
        }
    }
    
}


// MARK: - RichTextProvider

public extension SymNSTextView {

    
    /**
     Get the rich text that is managed by the view.
     */
    var attributedString: NSAttributedString {
        get { attributedString() }
        set { textStorage?.setAttributedString(newValue) }
    }

    /**
     Whether or not the text view is the first responder.
     */
    var isFirstResponder: Bool {
        window?.firstResponder == self
    }
}


// MARK: - RichTextWriter

public extension SymNSTextView {

    /**
     Get the mutable rich text that is managed by the view.
     */
    var mutableAttributedString: NSMutableAttributedString? {
        textStorage
    }
}

#endif
