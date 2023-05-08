//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/6/23.
//

import Foundation
import SwiftUI
import Combine

public class HighlightedTextEditorContext: ObservableObject, Equatable, Hashable {
    public static func == (lhs: HighlightedTextEditorContext, rhs: HighlightedTextEditorContext) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id: String
    
    public init(_ id: String = UUID().uuidString) {
        self.id = id
    }
    
    /**
     Whether or not the rich text is currently being edited.
     */
    @Published
    public var isEditingText = false
    
    
    public func stopEditingText() {
//        isEditingText = false
        if isEditingText {
            isEditingText = false
        }
    }
    
    
    public func startEditingText() {
        if !isEditingText {
            isEditingText = true
        }
    }
    
}

