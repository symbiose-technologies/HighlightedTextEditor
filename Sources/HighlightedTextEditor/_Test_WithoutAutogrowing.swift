//
//#if os(iOS)
////
////  HighlightedTextEditor.UIKit.swift
////
////
////  Created by Kyle Nazario on 5/26/21.
////
//
//import SwiftUI
//import UIKit
//import NextGrowingTextView
//import Combine
//
//public struct HighlightedTextEditorWrapped: View {
//
//    @Binding var text: String
//    var highlightRules: [HighlightRule]
//    var context: HighlightedTextEditorContext
//    var config: HighlightedTextEditorConfig
//
//    let minHeight: CGFloat
//    let maxHeight: CGFloat
//
//    @State var height: CGFloat?
//
//    public init(
//        text: Binding<String>,
//        highlightRules: [HighlightRule],
//        context: HighlightedTextEditorContext,
//        minHeight: CGFloat = 50.0,
//        maxHeight: CGFloat = 300.0,
//        config: HighlightedTextEditorConfig = .defaultConfig()
//    ) {
//        self._text = text
//        self.highlightRules = highlightRules
//        self.context = context
//        self.config = config
//        self.minHeight = minHeight
//        self.maxHeight = maxHeight
//    }
//
//    public var body: some View {
//        HighlightedTextEditor(text: self.$text,
//                              highlightRules: self.highlightRules,
//                              context: self.context,
//                              config: self.config)
//        .frame(height: height ?? minHeight)
//    }
//
//}
//
//public struct HighlightedTextEditor: UIViewRepresentable, HighlightingTextEditor {
//    public struct Internals {
//        public let textView: SystemTextView
//        public let scrollView: SystemScrollView?
//    }
//
//    @Binding var text: String {
//        didSet {
//            onTextChange?(text, currentSelectionFirst)
//        }
//    }
//
//    @State var currentSelection: [NSRange] = []
//
//
//    let highlightRules: [HighlightRule]
//    let config: HighlightedTextEditorConfig
//
//    private(set) var onEditingChanged: OnEditingChangedCallback?
//    private(set) var onCommit: OnCommitCallback?
//    private(set) var onTextChange: OnTextChangeCallback?
//    private(set) var onSelectionChange: OnSelectionChangeCallback?
//    private(set) var introspect: IntrospectCallback?
//
//
//    private(set) var onPastedContent: OnPastedContentCallback?
//    private(set) var onDroppedContent: OnDroppedContentCallback?
//
//    private(set) var onPastedItems: OnPastedItemsCallback?
//    private(set) var onDroppedItems: OnDroppedItemsCallback?
//
//
//    @ObservedObject
//    private(set) var context: HighlightedTextEditorContext
//
//    private(set) var explicitHeight: NSLayoutConstraint? = nil
//
//    public init(
//        text: Binding<String>,
//        highlightRules: [HighlightRule],
//        context: HighlightedTextEditorContext,
//        config: HighlightedTextEditorConfig = .defaultConfig()
//    ) {
//        _text = text
//        self.highlightRules = highlightRules
//        self.context = context
//        self.config = config
//    }
//
//    public func makeCoordinator() -> HighlightedTextEditorCoordinator {
//        HighlightedTextEditorCoordinator(self)
//    }
//
//
//
//    public func makeUIView(context: Context) -> SymAutogrowingTextView {
//
//        let symTextView = SymAutogrowingTextView()
//        symTextView.translatesAutoresizingMaskIntoConstraints = false
//
//        symTextView.pasteItemsCallback = self.onPastedItems
//        symTextView.dropCallback = self.onDroppedItems
//        symTextView.keyboardDismissMode = .interactiveWithAccessory
//
//
////        symTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        symTextView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
//
//
//        symTextView.isEditable = true
//        if self.config.isAutoGrowing {
//            symTextView.isScrollEnabled = false
//        }
//
//        //add a max and min height to the symTextView via NSLayoutConstraint
//        if let _ = config.minHeight,
//           let maxHeight = config.maxHeight {
//            symTextView.maxHeight = maxHeight
//
////            symTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight).isActive = true
////            symTextView.heightAnchor.constraint(equalToConstant: maxHeight).isActive = true
//        }
//
//
//
//        symTextView.delegate = context.coordinator
////        updateTextViewModifiers(symTextView)
//
//        context.coordinator.containerView = symTextView
//
//
//        return symTextView
//    }
//
//
//    public func updateUIView(_ uiView: SymAutogrowingTextView, context: Context) {
//
//        context.coordinator.updatingUIView = true
//
//        let highlightedText = HighlightedTextEditor.getHighlightedText(
//            text: text,
//            highlightRules: highlightRules
//        )
//        if let range = uiView.markedTextNSRange {
//            uiView.setAttributedMarkedText(highlightedText, selectedRange: range)
//        } else {
//            if uiView.attributedText != highlightedText {
//                uiView.attributedText = highlightedText
//            }
//        }
//
//        updateTextViewModifiers(uiView)
//
//        runIntrospect(uiView)
//
////        uiView.isScrollEnabled = true
//        uiView.selectedTextRange = context.coordinator.selectedTextRange
//        context.coordinator.updatingUIView = false
//    }
//
//    private func runIntrospect(_ textView: UITextView) {
//        guard let introspect = introspect else { return }
//        let internals = Internals(textView: textView, scrollView: nil)
//        introspect(internals)
//    }
//
//    private func updateTextViewModifiers(_ textView: UITextView) {
//        // BUGFIX #19: https://stackoverflow.com/questions/60537039/change-prompt-color-for-uitextfield-on-mac-catalyst
//        let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
//        textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
//    }
//}
//
//
//
//extension HighlightedTextEditorCoordinator: UITextViewDelegate {
//    func updateTextViewHeight(_ newHeight: CGFloat) {
////        guard let container = containerView else { return }
////        UIView.animate(withDuration: 1.0) {
////            container.contentHeight = newHeight
////        }
//    }
//
//
//    public func growingActionHandler(_ action: NextGrowingTextView.Action) {
////        print("[GrowingActionHandler] action: \(action)")
//        switch action {
//        case .willChangeHeight(let newHeight):
//            self.updateTextViewHeight(newHeight)
//        default:
//            return
//        }
//    }
//
//    private func updateHeightConstraint(_ textView: UITextView, activateConstraint: Bool) {
//        guard let maxHeight = self.displayConfig.maxHeight else { return }
//        if activateConstraint {
//            if let heightConstraint = textView.constraints.first(where: { $0.firstAttribute == .height }) {
//                if maxHeight != heightConstraint.constant {
//                    heightConstraint.constant = maxHeight
//                }
//                if heightConstraint.priority != .defaultHigh {
//                    heightConstraint.priority = .defaultHigh
//                }
//                if !heightConstraint.isActive {
//                    heightConstraint.isActive = true
//                }
//            } else {
//                let heightConstraint = textView.heightAnchor.constraint(equalToConstant: maxHeight)
//                heightConstraint.priority = .defaultHigh
//                heightConstraint.isActive = true
//            }
//        } else {
//            if let heightConstraint = textView.constraints.first(where: { $0.firstAttribute == .height }) {
//                if heightConstraint.isActive {
//                    heightConstraint.isActive = false
//                }
//            }
//        }
//    }
//
//    public func textViewDidChange(_ textView: UITextView) {
//        // For Multistage Text Input
//        guard textView.markedTextRange == nil else { return }
//
////        let calculatedHeight = textView.contentSize.height
////        if let maxHeight = self.displayConfig.maxHeight,
////           let _ = self.displayConfig.minHeight {
////
////            if calculatedHeight >= maxHeight {
////                //needs to scroll
//////                self.updateHeightConstraint(textView, activateConstraint: true)
////                if !textView.isScrollEnabled {
////                    DispatchQueue.main.async {
////                        textView.isScrollEnabled = true
////                    }
////                }
////            } else {
//////                self.updateHeightConstraint(textView, activateConstraint: false)
////                if textView.isScrollEnabled {
////                    DispatchQueue.main.async {
////                        textView.isScrollEnabled = false
////                    }
////                }
////            }
////        }
//
//        if parent.text != textView.text {
//            parent.text = textView.text
//        }
//        if selectedTextRange != textView.selectedTextRange {
//            selectedTextRange = textView.selectedTextRange
//        }
//    }
//
//    public func textViewDidChangeSelection(_ textView: UITextView) {
//        guard !updatingUIView
//        else { return }
//        selectedTextRange = textView.selectedTextRange
//        self.parent.currentSelection = [textView.selectedRange]
//        guard let onSelectionChange = parent.onSelectionChange else { return }
//
//        onSelectionChange([textView.selectedRange])
//    }
//
//    public func textViewDidBeginEditing(_ textView: UITextView) {
//        parent.onEditingChanged?()
//    }
//
//    public func textViewDidEndEditing(_ textView: UITextView) {
//        parent.onCommit?()
//    }
//    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
//        return true
//    }
//
//    public func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
//        return false // Prevent pasted images from being intercepted
//    }
//}
//
//
//
//
//public extension HighlightedTextEditor {
//    func introspect(callback: @escaping IntrospectCallback) -> Self {
//        var new = self
//        new.introspect = callback
//        return new
//    }
//
//    func onSelectionChange(_ callback: @escaping (_ selectedRange: NSRange) -> Void) -> Self {
//        var new = self
//        new.onSelectionChange = { ranges in
//            guard let range = ranges.first else { return }
//            callback(range)
//        }
//        return new
//    }
//
//    func onCommit(_ callback: @escaping OnCommitCallback) -> Self {
//        var new = self
//        new.onCommit = callback
//        return new
//    }
//
//    func onEditingChanged(_ callback: @escaping OnEditingChangedCallback) -> Self {
//        var new = self
//        new.onEditingChanged = callback
//        return new
//    }
//
//    func onTextChange(_ callback: @escaping OnTextChangeCallback) -> Self {
//        var new = self
//        new.onTextChange = callback
//        return new
//    }
//
//
//    //for iOS
//    func onPastedItems(_ callback: @escaping OnPastedItemsCallback) -> Self {
//        var editor = self
//        editor.onPastedItems = callback
//        return editor
//    }
//    //for iOS
//    func onDroppedItems(_ callback: @escaping OnDroppedItemsCallback) -> Self {
//        var editor = self
//        editor.onDroppedItems = callback
//        return editor
//    }
//
//    //for macOS
//    func onPastedContent(_ callback: @escaping OnPastedContentCallback) -> Self {
//        var editor = self
//        editor.onPastedContent = callback
//        return editor
//    }
//
//    //for macOS
//    func onDroppedContent(_ callback: @escaping OnDroppedContentCallback) -> Self {
//        var editor = self
//        editor.onDroppedContent = callback
//        return editor
//    }
//
//
//}
//#endif
