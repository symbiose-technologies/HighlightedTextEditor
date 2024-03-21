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
//    var selectedTextRange: UITextRange?
    var updatingUIView = false
    var growingView: RSKGrowingTextView? = nil
    var textView: UITextView? { growingView }
    #endif
    
    #if os(macOS)
    var selectedRange: NSRange? { context.selectedRange }
    var selectedRanges: [NSValue] { context.selectedRanges }
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
        
        context
            .needsRefreshPub
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncViewState()
            }
            .store(in: &cancellables)
        
        
        context.isEditingTextPub
            //skip the first 4 published events
//            .dropFirst(4)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIsEditing in
                print("context.isEditingText: \(newIsEditing)")
                self?.setIsEditing(to: newIsEditing)
            }
            .store(in: &cancellables)
        
        context.$editingActive
            .sink { isEditingActive in
                debugPrint("context.editingActive: \(isEditingActive)")
                DispatchQueue.main.async { [weak self] in
                    self?.setIsEditing(to: isEditingActive)
                }
            }
            .store(in: &cancellables)
        
//        context
//            .$highlightedTxt
//            .receive(on: DispatchQueue.main)
//            .sink { newAttrString in
//                guard let textView = self.textView else { return }
//                textView.attributedText = newAttrString
//            }
//            .store(in: &cancellables)
        
        context.$placeholderText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPlaceholder in
#if os(iOS)
                guard let growingView = self?.growingView,
                let newPlaceholder else { return }
                growingView.placeholder = NSString(string: newPlaceholder)
                #else
                
                #endif
            }
            .store(in: &cancellables)
        
        
        
        context.$placeholderTextAttr
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newPlaceholder in
#if os(iOS)
                guard let growingView = self?.growingView,
                let newPlaceholder else { return }
                growingView.attributedPlaceholder = newPlaceholder
                #else
                
                #endif
            }
            .store(in: &cancellables)
        
    }
    
    func setIsEditing(to newValue: Bool) {
        guard let textView = self.textView else { return }
        print("setIsEditing: \(newValue) currently: \(textView.isFirstResponder) contextIsActive: \(self.context.resolvedIsEditingPub.value)")
        
        self.context.didMakeActive(isActive: newValue)
        if newValue == textView.isFirstResponder {
            debugPrint("setIsEditing: \(newValue) already in correct state")
            return
        }
        debugPrint("setIsEditing: \(newValue) -- not in correct state. Setting now")
        
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
    
    func syncViewState() {
        self.syncChangesToView()
    }
    
    func syncChangesToView() {
        self.syncChangesToView_Platform()
    }
    
#if canImport(UIKit)
func syncChangesToView_Platform() {
    guard let uiView = self.growingView else { return }
    
    uiView.isScrollEnabled = false
    updatingUIView = true

    if uiView.minimumNumberOfLines != self.context.iosMinLineCount {
        uiView.minimumNumberOfLines = self.context.iosMinLineCount
    }
    if uiView.maximumNumberOfLines != self.context.iosMaxLineCount {
        uiView.maximumNumberOfLines = self.context.iosMaxLineCount
    }
    
    let highlightedText = self.context.getProcessedText()
    var didSetContextProvidedSelectionTo: UITextRange? = nil
    
    if let range = uiView.markedTextNSRange {
        uiView.setAttributedMarkedText(highlightedText, selectedRange: range)
    } else {
        //todo add conditional check on attrtext before adding
        uiView.attributedText = highlightedText
        if let pendingCursorChange = context.consumePendingCursorChange() {
            didSetContextProvidedSelectionTo = pendingCursorChange
                .setSelectedTextRangeIn(uiView as UITextView)
            
        }
    }
    uiView.isScrollEnabled = true
    
    if let didSetContextProvidedSelectionTo {
        self.context.selectedTextRange = didSetContextProvidedSelectionTo
    } else {
        uiView.selectedTextRange = self.context.selectedTextRange
    }
    
    updatingUIView = false
}
#endif
    
    #if canImport(AppKit)
    func syncChangesToView_Platform() {
        //TODO handle cursor change on macOS
        guard let view = self.textView else { return }
        self.updatingNSView = true
        let typingAttributes = view.typingAttributes
        
        let highlightedText = self.context.getProcessedText()
        view.attributedText = highlightedText
        //runintrospect
        view.selectedRanges = self.context.selectedRanges
        view.typingAttributes = typingAttributes
        self.updatingNSView = false
        
    }
    #endif
    
    
    
    
}



