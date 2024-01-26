#if os(macOS)
/**
 *  MacEditorTextView
 *  Copyright (c) Thiago Holanda 2020
 *  https://twitter.com/tholanda
 *
 *  Modified by Kyle Nazario 2020
 *
 *  MIT license
 */

import AppKit
import Combine
import SwiftUI
import Combine


public struct HighlightedTextEditor: NSViewRepresentable, HighlightingTextEditor {
    public struct Internals {
        public let textView: SystemTextView
        public let scrollView: SystemScrollView?
    }
    
    
    var text: String {
        context.text
//        set { context.setText(newValue) }
    }
    
    
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

    public func makeNSView(context: Context) -> ScrollableTextView {
        print("[HighlightedTextEditor] makeNSView called")

        let textView = ScrollableTextView(self.context)
        
        textView.delegate = context.coordinator
        
        textView.textView.sizeChangeCb = { size in
            self.context.setCurrentFrameSize(size)
        }
        
        textView.textView.onPastedContent = self.onPastedContent
        textView.textView.onDroppedContent = self.onDroppedContent
        
//        textView.textView.attributedText = self.context.highlightedTxt
        textView.attributedText = self.context.getProcessedText()
        
        textView.textView.usesFindBar = true
        
        self.context.selectedRange = textView.textView.selectedRange()
//        context.coordinator.selectedRange = textView.textView.selectedRange()
        
        context.coordinator.scrollableTextView = textView
//        if context.coordinator.context.isEditingText {
//            textView.window?.makeFirstResponder(textView)
//        }
        
        runIntrospect(textView)
        
        return textView
    }
    
    public func updateNSView(_ view: ScrollableTextView, context: Context) {
        print("[HighlightedTextEditor] updateNSView called")
//        context.coordinator.updatingNSView = true
//        let typingAttributes = view.textView.typingAttributes
//
////        let highlightedText = HighlightedTextEditor.getHighlightedText(
////            text: text,
////            highlightRules: highlightRules
////        )
//
//        let highlightedText = self.context.getProcessedText()
//        view.attributedText = highlightedText
        runIntrospect(view)
//        
//        view.selectedRanges = context.coordinator.selectedRanges
//        view.textView.typingAttributes = typingAttributes
//        context.coordinator.updatingNSView = false
    }

    public func updateNSViewSymbiose(_ view: ScrollableTextView, context: Context) {
        context.coordinator.updatingNSView = true
        
        let typingAttributes = view.textView.typingAttributes

        let highlightedText = HighlightedTextEditor.getHighlightedText(
            text: text,
            highlightRules: highlightRules
        )
        let textIsDifferent = view.attributedText != highlightedText


//        let cursorPosition = view.textView.selectedRange()
        let cursorPosition = context.coordinator.selectedRange ?? NSMakeRange(0, 0)
        
        let adjustedCursorPosition = min(cursorPosition.location, highlightedText.string.count)
        let newSelectedRange = NSMakeRange(adjustedCursorPosition, 0)
        
        if textIsDifferent {
            DispatchQueue.main.async {
                view.textView.textStorage?.beginEditing()
                print("[HighlightedTextEditor] AppKit updating textStorage newCursorPos: \(adjustedCursorPosition) oldCursorPos: \(cursorPosition.location)")
                context.coordinator.setSelectedRangeBlock = true
                view.textView.attributedText = highlightedText
                view.textView.typingAttributes = typingAttributes
                context.coordinator.setSelectedRangeBlock = false
                
                print("[HighlightedTextEditor] AppKit setting selected range!")
                view.textView.setSelectedRange(newSelectedRange)

                
                
//                if adjustedCursorPosition != highlightedText.string.count {
//                    print("[HighlightedTextEditor] AppKit setting selected range!")
//                    view.textView.setSelectedRange(newSelectedRange)
//                }
                view.textView.textStorage?.endEditing()
            }
        }
            
        runIntrospect(view)

//        view.textView.typingAttributes = typingAttributes
        context.coordinator.updatingNSView = false
    }

    private func runIntrospect(_ view: ScrollableTextView) {
        guard let introspect = introspect else { return }
        let internals = Internals(textView: view.textView, scrollView: view.scrollView)
        introspect(internals)
        
        view.textView.onPastedContent = self.onPastedContent
        view.textView.onDroppedContent = self.onDroppedContent
        
    }
}

extension HighlightedTextEditorCoordinator: NSTextViewDelegate {
    
    public func textView(
        _ textView: NSTextView,
        shouldChangeTextIn affectedCharRange: NSRange,
        replacementString: String?
    ) -> Bool {
        return true
    }

    public func textDidBeginEditing(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }
        
        let content = String(textView.textStorage?.string ?? "")
        self.context.textDidChangeTo(content)
        self.syncChangesToView()
        
        context.setEditingActive(isActive: true)
        parent.onEditingChanged?()
    }

    public func textDidChange(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else { return }
        let content = String(textView.textStorage?.string ?? "")
        self.context.textDidChangeTo(content)
        self.syncChangesToView()
        
        self.context.selectedRange = textView.selectedRange()
        self.context.selectedRanges = textView.selectedRanges
//        selectedRange = textView.selectedRange()
//        selectedRanges = textView.selectedRanges
        
        
        parent.onTextChange?(content, selectedRange)
//        print("Text did change: \(content)")
//        print("Selected range: \(String(describing: selectedRange))")
    }
    
    public func textViewDidChangeSelection(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView,
              let onSelectionChange = parent.onSelectionChange,
              !updatingNSView,
              let ranges = textView.selectedRanges as? [NSRange]
        else { return }
        self.context.selectedRanges = textView.selectedRanges
//        selectedRanges = textView.selectedRanges
        DispatchQueue.main.async {
            onSelectionChange(ranges)
        }
        
    }

    
    public func textViewDidChangeSelectionSymbiose(_ notification: Notification) {
//        guard !updatingNSView else {
//            print("[HighlightedTextEditor] AppKit textViewDidChangeSelection: ignoring due to updatingNSView being true")
//            return
//        }

        guard !setSelectedRangeBlock else {
            print("[HighlightedTextEditor] AppKit textViewDidChangeSelection: ignoring due to updatingNSView being true")
            return
        }
        
        guard let textView = notification.object as? NSTextView else { return }
        
        let currentSelectedRange = textView.selectedRange()
        print("[HighlightedTextEditor] AppKit textViewDidChangeSelection to: \(currentSelectedRange) from previous: \(self.selectedRange ?? NSRange(location: -1, length: -1))")
//        self.selectedRange = currentSelectedRange
//        self.selectedRanges = textView.selectedRanges
        
        self.context.selectedRange = currentSelectedRange
        self.context.selectedRanges = textView.selectedRanges
        
//        self.parent.currentSelection = [currentSelectedRange]
        DispatchQueue.main.async { [weak self] in
            self?.parent.onSelectionChange?([currentSelectedRange])
        }

        
    }

    public func textDidEndEditing(_ notification: Notification) {
        guard let textView = notification.object as? NSTextView else {
            return
        }
        let content = String(textView.textStorage?.string ?? "")
        self.context.textDidChangeTo(content)
        
        context.setEditingActive(isActive: false)
        
        parent.onCommit?()
        
    }
    
}

public extension HighlightedTextEditor {
    class ScrollableTextView: NSView {
        weak var delegate: NSTextViewDelegate?

        var attributedText: NSAttributedString {
            didSet {
                textView.attributedText = attributedText
//                textView.textStorage?.setAttributedString(attributedText)
            }
        }

        var selectedRanges: [NSValue] = [] {
            didSet {
                guard selectedRanges.count > 0 else {
                    return
                }
                textView.selectedRanges = selectedRanges
            }
        }

        
        public lazy var scrollView: NSScrollView = {
            let scrollView = NSScrollView()
            scrollView.drawsBackground = false
            
            scrollView.borderType = .noBorder
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalRuler = false
            scrollView.autoresizingMask = [.width, .height]
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            return scrollView
        }()

        public lazy var textView: SymNSTextView = {
            if self.context.dynamicHeight {
                return self.dynamicTextView
            } else {
                return self.vanillaTextView
            }
        }()
        
        
        public lazy var vanillaTextView: SymNSTextView = {
            let contentSize = scrollView.contentSize
            let textStorage = NSTextStorage()

            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
            textContainer.widthTracksTextView = true
            textContainer.containerSize = NSSize(
                width: contentSize.width,
                height: CGFloat.greatestFiniteMagnitude
            )

            layoutManager.addTextContainer(textContainer)

            let textView = SymNSTextView(frame: .zero, textContainer: textContainer)
            textView.usesAdaptiveColorMappingForDarkAppearance = true

            textView.autoresizingMask = .width
//            textView.backgroundColor = NSColor.clear
            textView.delegate = self.delegate
            textView.allowsUndo = true
            
            textView.drawsBackground = true
            textView.backgroundColor = .clear
            
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: contentSize.height)
            textView.textColor = NSColor.labelColor

            return textView
        }()
        
        
        public lazy var dynamicTextView: DynamicHeightNSTextView = {
            let contentSize = scrollView.contentSize
            let textStorage = NSTextStorage()
            
            
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            let textContainer = NSTextContainer(containerSize: scrollView.frame.size)
            textContainer.widthTracksTextView = true
            
            print("[DynamicHeightNSTextView] upon init contentSize: \(contentSize)")
            
            textContainer.containerSize = NSSize(
                width: contentSize.width,
                height: .greatestFiniteMagnitude
            )

            layoutManager.addTextContainer(textContainer)

            let textView = DynamicHeightNSTextView(frame: .zero, textContainer: textContainer)
            textView.usesAdaptiveColorMappingForDarkAppearance = true

        
            
            textView.autoresizingMask = [.width, .height]
            
            textView.delegate = self.delegate
            
            textView.allowsUndo = true
            
            textView.drawsBackground = true
            textView.backgroundColor = .clear
            
            
            textView.isHorizontallyResizable = false
            textView.isVerticallyResizable = true
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            textView.minSize = NSSize(width: 0, height: contentSize.height)
            textView.textColor = NSColor.labelColor

            return textView
        }()

        // MARK: - Init

        var context: HighlightedTextEditorContext
        
        init(_ context: HighlightedTextEditorContext) {
            self.attributedText = NSMutableAttributedString()
            self.context = context
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - Life cycle

        override public func viewWillDraw() {
            super.viewWillDraw()

            setupScrollViewConstraints()
            setupTextView()
            print("HighlightedTextEditor -- ScrollableTextView -- viewWillDraw!")
            
        }

        
        
        func setupScrollViewConstraints() {
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            addSubview(scrollView)

            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: topAnchor),
                scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
                scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: leadingAnchor)
            ])
        }

        func setupTextView() {
            scrollView.documentView = textView
            if self.context.dynamicHeight,
               let dynamicHView = textView as? DynamicHeightNSTextView {
                dynamicHView.setupDynamicHeight(scrollView: scrollView,
                                                maxHeight: context.expMaxHeight,
                                                minHeight: context.expMinHeight)
            }
        }
    }
}

public extension HighlightedTextEditor {
    func introspect(callback: @escaping IntrospectCallback) -> Self {
        var editor = self
        editor.introspect = callback
        return editor
    }

    func onCommit(_ callback: @escaping OnCommitCallback) -> Self {
        var editor = self
        editor.onCommit = callback
        return editor
    }

    func onEditingChanged(_ callback: @escaping OnEditingChangedCallback) -> Self {
        var editor = self
        editor.onEditingChanged = callback
        return editor
    }

    func onTextChange(_ callback: @escaping OnTextChangeCallback) -> Self {
        var editor = self
        editor.onTextChange = callback
        return editor
    }

    func onSelectionChange(_ callback: @escaping OnSelectionChangeCallback) -> Self {
        var editor = self
        editor.onSelectionChange = callback
        return editor
    }

    func onSelectionChange(_ callback: @escaping (_ selectedRange: NSRange) -> Void) -> Self {
        var editor = self
        editor.onSelectionChange = { ranges in
            guard let range = ranges.first else { return }
            callback(range)
        }
        return editor
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
