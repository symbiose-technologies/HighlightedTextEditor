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
#endif


open class HighlightedTextEditorCoordinator: NSObject {
    
    var parent: HighlightedTextEditor

    var displayConfig: HighlightedTextEditorConfig
    var context: HighlightedTextEditorContext
    
    var cancellables: Set<AnyCancellable> = []
    
    #if os(iOS)
    var selectedTextRange: UITextRange?
    var updatingUIView = false
    var containerView: IntrinsicHeightGrowingTextView? = nil
    var textView: UITextView? { containerView?.textView }
    #endif
    
    #if os(macOS)
    var selectedRanges: [NSValue] = []
    var updatingNSView = false
    var scrollableTextView: HighlightedTextEditor.ScrollableTextView? = nil
    var textView: SymNSTextView? { scrollableTextView?.textView }
    #endif
    
    
    init(_ parent: HighlightedTextEditor) {
        self.parent = parent
        self.context = parent.context
        self.displayConfig = parent.config
        super.init()
        
//        self.subscribeToContextChanges()
    }
    
    
    
    func subscribeToContextChanges() {
        
        context.$isEditingText
            //skip the first 4 published events
            .dropFirst(4)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIsEditing in
                self?.setIsEditing(to: newIsEditing)
            }
            .store(in: &cancellables)
    }
    
    private func setIsEditing(to newValue: Bool) {
        guard let textView = self.textView else { return }
        
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
//            print("Skipping resignFirstResponder for mac")
            textView.resignFirstResponder()
            #endif
        }
    }
    
}



