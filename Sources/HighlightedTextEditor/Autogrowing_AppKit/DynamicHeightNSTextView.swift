//
//  File.swift
//
//
//  Created by Ryan Mckinney on 1/19/23.
//
#if os(macOS)
import Foundation
import AppKit

open class DynamicHeightNSTextView: SymNSTextView {

    var scrollViewHeight: NSLayoutConstraint? = nil
    var maxHeight: CGFloat = CGFloat.greatestFiniteMagnitude
    var minHeight: CGFloat = 50.0
    
    
    
    override init(frame frameRect: NSRect,
                  textContainer container: NSTextContainer?) {
        
        super.init(frame: frameRect, textContainer: container)
        
    }

    open override var intrinsicContentSize: NSSize {
        guard let container = self.textContainer,
              let layoutMgr = self.layoutManager else { return NSSize(width: 0.0, height: 0.0)}
        layoutMgr.ensureLayout(for: container)
        let size = layoutMgr.usedRect(for: container).size
        let modifiedSize = NSSize(width: size.width, height: max(size.height, 40))
        return modifiedSize
    }
    
//    open override var attributedText: NSAttributedString {
//
//    }
    
    open override var attributedText: NSAttributedString {
        didSet {
//            print("[DynamicHeightNSTextView] didSet attributedText")
            self.syncHeight(animated: false)
        }
    }
    
    func syncHeight(animated: Bool) {
//        print("[DynamicHeightNSTextView] syncHeight animated: \(animated)")

        self.invalidateIntrinsicContentSize()
               
        if let scrollHeight = self.scrollViewHeight {
            let newHeight = min(self.maxHeight, max(self.intrinsicContentSize.height, self.minHeight))
            
            if animated {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    scrollHeight.constant = newHeight
                }
//                NSAnimationContext.current.duration = 0.25
//                scrollHeight.animator().constant = newHeight
            } else {
                scrollHeight.constant = newHeight
            }
        }
    }
    
    
    open override func didChangeText() {
//        print("[DynamicHeightNSTextView] didChangeText")
        super.didChangeText()
        
        self.invalidateIntrinsicContentSize()
               
//        if let scrollHeight = self.scrollViewHeight {
//            let newHeight = min(self.maxHeight, max(self.intrinsicContentSize.height, self.minHeight))
//            NSAnimationContext.current.duration = 0.25
//            scrollHeight.animator().constant = newHeight
//        }
        
    }
    
    
    
    
    override init(frame frameRect: NSRect) {
        // this will end up calling init(frame:textContainer:)
        super.init(frame: frameRect)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    open func setupDynamicHeight(scrollView: NSScrollView,
                                 maxHeight: CGFloat? = nil,
                                 minHeight: CGFloat? = nil) {
        
        if let mHeight = maxHeight,
            let minHeight = minHeight {
            if let _ = self.scrollViewHeight { return }
            self.maxHeight = mHeight
            self.minHeight = minHeight
            
            let heightConstraint = scrollView.heightAnchor.constraint(equalToConstant: max(self.intrinsicContentSize.height, minHeight))
            heightConstraint.priority = NSLayoutConstraint.Priority(900)
            NSLayoutConstraint.activate([heightConstraint])
            self.scrollViewHeight = heightConstraint
            
        }
    }
    
    
    
    
}



#endif
