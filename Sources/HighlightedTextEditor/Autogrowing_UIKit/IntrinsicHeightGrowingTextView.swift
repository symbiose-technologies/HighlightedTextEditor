//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/6/23.
//

#if os(iOS)

import SwiftUI
import UIKit
import NextGrowingTextView
//import RSKGrowingTextView
//
//public class IntrinsicHeightGrowingTextViewNEW: UIView {
//
//    let growingView: RSKGrowingTextView
//    public var textView: SymUITextView { growingView.textView }
//
//    public init() {
//        self.growingView = RSKGrowingTextView()
//
//        super.init(frame: .zero)
//
//        backgroundColor = .clear
//        addSubview(growingView)
//    }
//
//    @available(*, unavailable) required init?(coder _: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//
//}

public class IntrinsicHeightGrowingTextView: UIView {
    
    let growingView: NextGrowingTextView
    public var textView: SymUITextView { growingView.textView }
    
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



#endif
