#if os(iOS)
//
//  HighlightedTextEditor.UIKit.swift
//
//
//  Created by Kyle Nazario on 5/26/21.
//

import SwiftUI
import UIKit
import NextGrowingTextView


public class IntrinsicHeightGrowingTextView: UIView {
    
    let growingView: NextGrowingTextView
    public var textView: UITextView { growingView.textView }
    
    public init() {
        self.growingView = NextGrowingTextView()
        
        super.init(frame: .zero)
        
        backgroundColor = .clear
        addSubview(growingView)
    }
    
    @available(*, unavailable) required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var explicitHeight: CGFloat = .zero
    
    public var contentHeight: CGFloat = .zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    public override var intrinsicContentSize: CGSize {
        .init(width: UIView.noIntrinsicMetric, height: contentHeight)
//        .init(width: UIView.noIntrinsicMetric, height: growingView.intrinsicContentSize.height)
    }


    public override var frame: CGRect {
        didSet {
            guard frame != oldValue else { return }

            growingView.frame = self.bounds
            growingView.layoutIfNeeded()

            let targetSize = CGSize(width: frame.width, height: UIView.layoutFittingCompressedSize.height)

            contentHeight = growingView.systemLayoutSizeFitting(targetSize,
                                                                withHorizontalFittingPriority: .required,
                                                                verticalFittingPriority: .fittingSizeLevel).height
        }
    }
}





public struct HighlightedTextEditor: UIViewRepresentable, HighlightingTextEditor {
    public struct Internals {
        public let textView: SystemTextView
        public let scrollView: SystemScrollView?
    }

    @Binding var text: String {
        didSet {
            onTextChange?(text)
        }
    }

    let highlightRules: [HighlightRule]
    let config: HighlightedTextEditorConfig

    private(set) var onEditingChanged: OnEditingChangedCallback?
    private(set) var onCommit: OnCommitCallback?
    private(set) var onTextChange: OnTextChangeCallback?
    private(set) var onSelectionChange: OnSelectionChangeCallback?
    private(set) var introspect: IntrospectCallback?

    public init(
        text: Binding<String>,
        highlightRules: [HighlightRule],
        config: HighlightedTextEditorConfig = .defaultConfig()
    ) {
        _text = text
        self.highlightRules = highlightRules
        self.config = config
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> IntrinsicHeightGrowingTextView {
        let intrinsicGrowingTextView = IntrinsicHeightGrowingTextView()
        let growingView = intrinsicGrowingTextView.growingView
        
        growingView.backgroundColor = .orange
        
        
        growingView.actionHandler = context.coordinator.growingActionHandler
        
        
        
        growingView.configuration = .init(
            minLines: config.iosMinLineCount,
            maxLines: config.iosMaxLineCount,
            isAutomaticScrollToBottomEnabled: true,
            isFlashScrollIndicatorsEnabled: false
        )
        growingView.textView.delegate = context.coordinator
        updateTextViewModifiers(growingView.textView)
        
        
        context.coordinator.containerView = intrinsicGrowingTextView
        
        return intrinsicGrowingTextView
    }

    public func updateUIView(_ uiView: IntrinsicHeightGrowingTextView, context: Context) {
        
        print("NextGrowingTextView intrinsicContentSize: textView.intrinsicSize: \(uiView.textView.intrinsicContentSize) growingView.intrinsicSize: \(uiView.intrinsicContentSize)")
        print("NextGrowingTextView frameSize: textView.frame: \(uiView.textView.frame.size) growingView.frame.size: \(uiView.frame.size)")
        
        
        
        uiView.textView.isScrollEnabled = false
        context.coordinator.updatingUIView = true

        let highlightedText = HighlightedTextEditor.getHighlightedText(
            text: text,
            highlightRules: highlightRules
        )

        if let range = uiView.textView.markedTextNSRange {
            uiView.textView.setAttributedMarkedText(highlightedText, selectedRange: range)
        } else {
            uiView.textView.attributedText = highlightedText
        }
        updateTextViewModifiers(uiView.textView)
        runIntrospect(uiView.textView)
        uiView.textView.isScrollEnabled = true
        uiView.textView.selectedTextRange = context.coordinator.selectedTextRange
        context.coordinator.updatingUIView = false
    }

    private func runIntrospect(_ textView: UITextView) {
        guard let introspect = introspect else { return }
        let internals = Internals(textView: textView, scrollView: nil)
        introspect(internals)
    }

    private func updateTextViewModifiers(_ textView: UITextView) {
        // BUGFIX #19: https://stackoverflow.com/questions/60537039/change-prompt-color-for-uitextfield-on-mac-catalyst
        let textInputTraits = textView.value(forKey: "textInputTraits") as? NSObject
        textInputTraits?.setValue(textView.tintColor, forKey: "insertionPointColor")
    }

    public final class Coordinator: NSObject, UITextViewDelegate {
        var parent: HighlightedTextEditor
        var selectedTextRange: UITextRange?
        var updatingUIView = false

        var containerView: IntrinsicHeightGrowingTextView? = nil
        
        let displayConfig: HighlightedTextEditorConfig
        
        init(_ markdownEditorView: HighlightedTextEditor) {
            self.parent = markdownEditorView
            self.displayConfig = parent.config
        }
        
        func updateTextViewHeight(_ newHeight: CGFloat) {
            guard let container = containerView else { return }
//            container.contentHeight = newHeight
            
            UIView.animate(withDuration: 1.0) {
//                container.frame = containerNewFrame
                container.contentHeight = newHeight
            }
            
        }
        
        
        public func growingActionHandler(_ action: NextGrowingTextView.Action) {
            print("[GrowingActionHandler] action: \(action)")
            switch action {
            case .willChangeHeight(let newHeight):
                self.updateTextViewHeight(newHeight)
            default:
                return
            }
        }

        public func textViewDidChange(_ textView: UITextView) {
            // For Multistage Text Input
            guard textView.markedTextRange == nil else { return }

            parent.text = textView.text
            selectedTextRange = textView.selectedTextRange
        }

        public func textViewDidChangeSelection(_ textView: UITextView) {
            guard let onSelectionChange = parent.onSelectionChange,
                  !updatingUIView
            else { return }
            selectedTextRange = textView.selectedTextRange
            onSelectionChange([textView.selectedRange])
        }

        public func textViewDidBeginEditing(_ textView: UITextView) {
            parent.onEditingChanged?()
        }

        public func textViewDidEndEditing(_ textView: UITextView) {
            parent.onCommit?()
        }
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
}
#endif
