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
    
    public var isEditingText: Bool { isEditingTextPub.value }
    
    let isEditingTextPub = CurrentValueSubject<Bool, Never>(false)
    
    
    public func setEditingActive(isActive: Bool) {
        if isActive {
            self.startEditingText()
        } else {
            self.stopEditingText()
        }
    }
    
    
    public func stopEditingText() {
        if isEditingTextPub.value {
            isEditingTextPub.send(false)
        }
    }
    
    
    public func startEditingText() {
        if !isEditingTextPub.value {
            isEditingTextPub.send(true)
        }
    }
    
}

