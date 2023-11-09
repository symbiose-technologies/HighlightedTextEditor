//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// 
// Created by: Ryan Mckinney on 11/2/23
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
import SwiftUI
import Combine


public enum CursorChangePos: Equatable, Hashable {
    case beginning
    case end
    case endOf(substring: String)
    case beginningOf(substring: String)
    case range(start: Int, end: Int)
}

#if canImport(UIKit)
public extension CursorChangePos {
    
    
    func setSelectedTextRangeIn(_ view: UITextView) -> UITextRange? {
        
        let newPosition: UITextPosition?
        
        switch self {
        case .beginning:
            newPosition = view.beginningOfDocument
            
        case .end:
            newPosition = view.endOfDocument
            
        case .endOf(let substring):
            newPosition = view.positionOf(substring: substring, atEnd: true)
            
        case .beginningOf(let substring):
            newPosition = view.positionOf(substring: substring, atEnd: false)
            
        case .range(let start, let end):
            newPosition = view.positionInRange(start: start, end: end)
        }
        
        if let newPosition = newPosition {
            let textPos = view.textRange(from: newPosition, to: newPosition)
            view.selectedTextRange = textPos
            return textPos
        }
        return nil
        
        // Any additional logic for adjusting text view after text change
//        self.scrollRangeToVisible(NSMakeRange(self.attributedText.length - 1, 0))
    }
    
}

extension UITextView {
    
    func positionOf(substring: String, atEnd: Bool) -> UITextPosition? {
        if let range = self.attributedText.string.range(of: substring) {
            let utf16Start = range.lowerBound.samePosition(in: self.attributedText.string.utf16)
            let utf16End = range.upperBound.samePosition(in: self.attributedText.string.utf16)
            let location = self.attributedText.string.utf16.distance(from: self.attributedText.string.utf16.startIndex, to: utf16Start!)
            let length = self.attributedText.string.utf16.distance(from: utf16Start!, to: utf16End!)
            return atEnd ? self.position(from: self.beginningOfDocument, offset: location + length) :
                self.position(from: self.beginningOfDocument, offset: location)
        }
        return nil
    }
    
    func positionInRange(start: Int, end: Int) -> UITextPosition? {
        guard start <= end else { return nil }
        guard let startPosition = self.position(from: self.beginningOfDocument, offset: start),
              let endPosition = self.position(from: startPosition, offset: end - start) else { return nil }
        
        return endPosition
    }
}

#endif
