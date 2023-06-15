//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/6/23.
//

import Foundation
import SwiftUI
import Combine

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
import RSKGrowingTextView
#endif


open class HighlightedTextEditorCoordinator: NSObject {
    
    var parent: HighlightedTextEditor

    var context: HighlightedTextEditorContext
    
    var cancellables: Set<AnyCancellable> = []
    
    #if os(iOS)
    var selectedTextRange: UITextRange?
    var updatingUIView = false
    var growingView: RSKGrowingTextView? = nil
    var textView: UITextView? { growingView }
    #endif
    
    #if os(macOS)
    var selectedRange: NSRange? = nil
    var selectedRanges: [NSValue] = []
    var updatingNSView = false
    var setSelectedRangeBlock = false
    var scrollableTextView: HighlightedTextEditor.ScrollableTextView? = nil
    var textView: SymNSTextView? { scrollableTextView?.textView }
    #endif
    
    
    init(_ parent: HighlightedTextEditor) {
        self.parent = parent
        self.context = parent.context
        super.init()
        
        self.subscribeToContextChanges()
        
    }
    
    
    
    func subscribeToContextChanges() {
        
        context.isEditingTextPub
            //skip the first 4 published events
//            .dropFirst(4)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIsEditing in
//                print("context.isEditingText: \(newIsEditing)")
                self?.setIsEditing(to: newIsEditing)
            }
            .store(in: &cancellables)
        
        
        context
            .$highlightedTxt
            .receive(on: DispatchQueue.main)
            .sink { newAttrString in
                guard let textView = self.textView else { return }
                textView.attributedText = newAttrString
            }
            .store(in: &cancellables)
        
    }
    
    func setIsEditing(to newValue: Bool) {
        guard let textView = self.textView else { return }
//        print("setIsEditing: \(newValue) currently: \(textView.isFirstResponder)")
        self.context.didMakeActive(isActive: newValue)
        if newValue == textView.isFirstResponder { return }
        if newValue {
            #if os(iOS)
            textView.becomeFirstResponder()
            #elseif os(macOS)
            textView.window?.makeFirstResponder(textView)
            #endif
        } else {
            #if os(iOS)
            textView.resignFirstResponder()
            #elseif os(macOS)
            textView.window?.makeFirstResponder(nil)
            #endif
        }
        
    }
    
}



