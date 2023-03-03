//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/3/23.
//

import Foundation


public struct HighlightedTextEditorConfig: Equatable, Hashable {
    
    var isAutoGrowing: Bool
    var minHeight: CGFloat?
    var maxHeight: CGFloat?
    
    var iosMinLineCount: Int
    var iosMaxLineCount: Int
    
    public static func defaultConfig() -> HighlightedTextEditorConfig {
        HighlightedTextEditorConfig(isAutoGrowing: true,
                                    minHeight: 50,
                                    maxHeight: 400,
                                    iosMinLineCount: 1,
                                    iosMaxLineCount: 10)
    }
}
