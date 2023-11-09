#if os(iOS)
//
//  HighlightedTextEditor.UIKit.swift
//
//
//  Created by Kyle Nazario on 5/26/21.
//

import SwiftUI
import UIKit
import RSKGrowingTextView

import Combine

public struct HighlightedTextEditor: UIViewRepresentable, HighlightingTextEditor {
    public struct Internals {
        public let textView: SystemTextView
        public let scrollView: SystemScrollView?
    }

//    @Binding var text: String {
//        didSet {
//            onTextChange?(text, currentSelectionFirst)
//        }
//    }
    
    var text: String {
        context.text
//        set { context.setText(newValue) }
    }
//    

    @State var currentSelection: [NSRange] = []
    
    var highlightRules: [HighlightRule] {
        context.highlightRules
    }
    
    
    private(set) var onEditingChanged: OnEditingChangedCallback?
    private(set) var onCommit: OnCommitCallback?
    private(set) var onTextChange: OnTextChangeCallback?
    private(set) var onSelectionChange: OnSelectionChangeCallback?
    private(set) var introspect: IntrospectCallback?

    
    private(set) var onPastedContent: OnPastedContentCallback?
    private(set) var onDroppedContent: OnDroppedContentCallback?
    
    private(set) var onPastedItems: OnPastedItemsCallback?
    private(set) var onDroppedItems: OnDroppedItemsCallback?
    
    
    @ObservedObject
    private(set) var context: HighlightedTextEditorContext
    
    
    public init(
        context: HighlightedTextEditorContext
    ) {
        self.context = context
    }

    public func makeCoordinator() -> HighlightedTextEditorCoordinator {
        HighlightedTextEditorCoordinator(self)
    }

    public func makeUIView(context: Context) -> RSKGrowingTextView {
        print("[HighlightedTextEditor] makeUIView")
        
        let growingView = RSKGrowingTextView()
        
        growingView.sizeChangeCb = { size in
            self.context.setCurrentFrameSize(size)
        }
        
        
        growingView.minimumNumberOfLines = self.context.iosMinLineCount
        growingView.maximumNumberOfLines = self.context.iosMaxLineCount
        
        
        growingView.pasteItemsCallback = self.onPastedItems
        growingView.dropCallback = self.onDroppedItems
        growingView.keyboardDismissMode = .interactiveWithAccessory
        
        growingView.growingTextViewDelegate = context.coordinator
        
        let highlightedText = self.context.getProcessedText()
        growingView.attributedText = highlightedText

        growingView.backgroundColor = .clear
        
        
        context.coordinator.growingView = growingView
        updateTextViewModifiers(growingView)
        
        runIntrospect(growingView)
        
        
        return growingView
    }

    public func updateUIView(_ uiView: RSKGrowingTextView, context: Context) {
        print("[HighlightedTextEditor] updateUIView")

        uiView.isScrollEnabled = false
        context.coordinator.updatingUIView = true

        if uiView.minimumNumberOfLines != self.context.iosMinLineCount {
            uiView.minimumNumberOfLines = self.context.iosMinLineCount
        }
        if uiView.maximumNumberOfLines != self.context.iosMaxLineCount {
            uiView.maximumNumberOfLines = self.context.iosMaxLineCount
        }
        
//        let highlightedText = self.context.getProcessedText()
//
//        if let range = uiView.markedTextNSRange {
//            uiView.setAttributedMarkedText(highlightedText, selectedRange: range)
//
////            if highlightedText != uiView.attributedString {
////                uiView.setAttributedMarkedText(highlightedText, selectedRange: range)
////            }
//        } else {
//            //todo add conditional check on attrtext before adding
//            uiView.attributedText = highlightedText
//        }
//        updateTextViewModifiers(uiView)
        runIntrospect(uiView)
        uiView.isScrollEnabled = true
//        uiView.selectedTextRange = context.coordinator.selectedTextRange
        context.coordinator.updatingUIView = false
    }

    private func runIntrospect(_ textView: UITextView) {
        guard let introspect = introspect else { return }
        let internals = Internals(textView: textView, scrollView: nil)
        introspect(internals)
    }

    private func updateTextViewModifiers(_ textView: UITextView) {
        #if targetEnvironment(macCatalyst)
        // BUGFIX #19: https://stackoverflow.com/questions/60537039/change-prompt-color-for-uitextfield-on-mac-catalyst
        let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
        textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
        #endif
    }
}


extension HighlightedTextEditorCoordinator: RSKGrowingTextViewDelegate {
  
    public func growingTextView(_ textView: RSKGrowingTextView, didChangeHeightFrom growingTextViewHeightBegin: CGFloat, to growingTextViewHeightEnd: CGFloat) {
        self.context.iosHeightDidChange(growingTextViewHeightBegin, to: growingTextViewHeightEnd)
        
        self.context.setCurrentNumberOfLines(textView.numberOfLines)
    }
    
    public func growingTextView(_ textView: RSKGrowingTextView, willChangeHeightFrom growingTextViewHeightBegin: CGFloat, to growingTextViewHeightEnd: CGFloat) {
        self.context.iosHeightWillChange(growingTextViewHeightBegin, to: growingTextViewHeightEnd)
    }
    
    
    public func textViewDidChange(_ textView: UITextView) {
        // For Multistage Text Input
        guard textView.markedTextRange == nil else { return }
        
        self.context.textDidChangeTo(textView.text)
        self.syncChangesToView()
        
        self.context.selectedTextRange = textView.selectedTextRange
        self.parent.onTextChange?(textView.text, parent.currentSelectionFirst)
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        guard !updatingUIView
        else { return }
        self.context.selectedTextRange = textView.selectedTextRange
        self.parent.currentSelection = [textView.selectedRange]
        guard let onSelectionChange = parent.onSelectionChange else { return }
        
        onSelectionChange([textView.selectedRange])
    }

    public func textViewDidBeginEditing(_ textView: UITextView) {
//        if !context.isEditingText {
//            DispatchQueue.main.async { [weak self] in
//                
//                self?.context.isEditingText = true
//            }
//        }
        context.setEditingActive(isActive: true)
        
        parent.onEditingChanged?()
    }

    public func textViewDidEndEditing(_ textView: UITextView) {
//        if context.isEditingText {
//            DispatchQueue.main.async { [weak self] in
//                self?.context.isEditingText = false
//            }
//        }
//
        context.setEditingActive(isActive: false)
        
        parent.onCommit?()
    }
    
//    @available(iOS 16.0, *)
//    public func textView(_ textView: UITextView,
//                         editMenuForTextIn range: NSRange,
//                         suggestedActions: [UIMenuElement]) -> UIMenu? {
//        var additionalActions: [UIMenuElement] = []
//        if range.length > 0 {
//            let highlightAction = UIAction(title: "Highlight", image: UIImage(systemName: "highlighter")) { action in
//                // The highlight action.
//                print("highlight")
//            }
//            additionalActions.append(highlightAction)
//        }
//        let addBookmarkAction = UIAction(title: "Add Bookmark", image: UIImage(systemName: "bookmark")) { action in
//            // The bookmark action.
//            print("add bookmark")
//
//        }
//        additionalActions.append(addBookmarkAction)
//        return UIMenu(children: suggestedActions + additionalActions)
//    }
    
    @available(iOS 16.0, *)
    public func textView(
        _ textView: UITextView,
        willDismissEditMenuWith animator: UIEditMenuInteractionAnimating
    ) {
        print("[textView] willDismissEditMenuWith")
    }
    
    @available(iOS 16.0, *)
    public func textView(
        _ textView: UITextView,
        willPresentEditMenuWith animator: UIEditMenuInteractionAnimating
    ){
        print("[textView] didDismissEditMenuWith")
    }
    
    
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return true
    }
            
    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return false // Prevent pasted images from being intercepted
    }
}




public extension HighlightedTextEditor {
    func introspect(callback: @escaping IntrospectCallback) -> Self {
        var new = self
        new.introspect = callback
        return new
    }

    func onSelectionChange(_ callback: @escaping (_ selectedRange: NSRange) -> Void) -> Self {
        var new = self
        new.onSelectionChange = { ranges in
            guard let range = ranges.first else { return }
            callback(range)
        }
        return new
    }

    func onCommit(_ callback: @escaping OnCommitCallback) -> Self {
        var new = self
        new.onCommit = callback
        return new
    }

    func onEditingChanged(_ callback: @escaping OnEditingChangedCallback) -> Self {
        var new = self
        new.onEditingChanged = callback
        return new
    }

    func onTextChange(_ callback: @escaping OnTextChangeCallback) -> Self {
        var new = self
        new.onTextChange = callback
        return new
    }
    
    
    //for iOS
    func onPastedItems(_ callback: @escaping OnPastedItemsCallback) -> Self {
        var editor = self
        editor.onPastedItems = callback
        return editor
    }
    //for iOS
    func onDroppedItems(_ callback: @escaping OnDroppedItemsCallback) -> Self {
        var editor = self
        editor.onDroppedItems = callback
        return editor
    }
    
    //for macOS
    func onPastedContent(_ callback: @escaping OnPastedContentCallback) -> Self {
        var editor = self
        editor.onPastedContent = callback
        return editor
    }
    
    //for macOS
    func onDroppedContent(_ callback: @escaping OnDroppedContentCallback) -> Self {
        var editor = self
        editor.onDroppedContent = callback
        return editor
    }
    
    
}
#endif
