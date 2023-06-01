//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/3/23.
//

import Foundation


public struct HighlightedTextEditorConfig: Equatable, Hashable {
    
    public var isAutoGrowing: Bool
    public var minHeight: CGFloat?
    public var maxHeight: CGFloat?
    
    public var iosMinLineCount: Int
    public var iosMaxLineCount: Int
    
    public init(isAutoGrowing: Bool, minHeight: CGFloat? = nil, maxHeight: CGFloat? = nil, iosMinLineCount: Int, iosMaxLineCount: Int) {
        self.isAutoGrowing = isAutoGrowing
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.iosMinLineCount = iosMinLineCount
        self.iosMaxLineCount = iosMaxLineCount
    }
    
    public static func defaultConfig() -> HighlightedTextEditorConfig {
        HighlightedTextEditorConfig(isAutoGrowing: true,
                                    minHeight: 50,
                                    maxHeight: 400,
                                    iosMinLineCount: 1,
                                    iosMaxLineCount: 10)
    }
}
