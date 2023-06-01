
#if os(iOS)
import Foundation
import UIKit
import NextGrowingTextView

open class SymAutogrowingTextView: SymUITextView {

    var maxHeight: CGFloat = 0
//    weak var boundsObserver: BoundsObserving?
    var maxHeightConstraint: NSLayoutConstraint!
    var heightAnchorConstraint: NSLayoutConstraint!

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        isScrollEnabled = false
        heightAnchorConstraint = heightAnchor.constraint(greaterThanOrEqualToConstant: contentSize.height)
        heightAnchorConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            heightAnchorConstraint
        ])
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override var isScrollEnabled: Bool {
        didSet {
            // Invalidate intrinsic content size when scrolling is disabled again as a result of text
            // getting cleared/removed. In absence of the following code, the textview does not
            // resize when cleared until a character is typed in.
            guard isScrollEnabled == false,
                  oldValue == true
            else { return }
            
            invalidateIntrinsicContentSize()
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        guard maxHeight != .greatestFiniteMagnitude else { return }
        let bounds = self.bounds.integral
        let fittingSize = self.calculatedSize(attributedText: attributedText, frame: frame.size, textContainerInset: textContainerInset)
        self.isScrollEnabled = (fittingSize.height > bounds.height) || (self.maxHeight > 0 && self.maxHeight < fittingSize.height)
        heightAnchorConstraint.constant = fittingSize.height
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        var fittingSize = calculatedSize(attributedText: attributedText, frame: frame.size, textContainerInset: textContainerInset)
        if maxHeight > 0 {
            fittingSize.height = min(maxHeight, fittingSize.height)
        }
        return fittingSize
    }

    open override var bounds: CGRect {
        didSet {
            guard oldValue.height != bounds.height else { return }
//            boundsObserver?.didChangeBounds(bounds)
        }
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.becomeFirstResponder()
    }

    private func calculatedSize(attributedText: NSAttributedString, frame: CGSize, textContainerInset: UIEdgeInsets) -> CGSize {
        // Adjust for horizontal paddings in textview to exclude from overall available width for attachment
        let horizontalAdjustments = (textContainer.lineFragmentPadding * 2) + (textContainerInset.left + textContainerInset.right)
        let boundingRect = attributedText.boundingRect(with: CGSize(width: frame.width - horizontalAdjustments, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil).integral

        let insets = UIEdgeInsets(top: -textContainerInset.top, left: -textContainerInset.left, bottom: -textContainerInset.bottom, right: -textContainerInset.right)
        return boundingRect.inset(by: insets).size
    }
}
#endif
