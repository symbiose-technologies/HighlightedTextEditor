//////////////////////////////////////////////////////////////////////////////////
//
//  SYMBIOSE
//  Copyright 2023 Symbiose Technologies, Inc
//  All Rights Reserved.
//
//  NOTICE: This software is proprietary information.
//  Unauthorized use is prohibited.
//
// 
// Created by: Ryan Mckinney on 6/3/24
//
////////////////////////////////////////////////////////////////////////////////

import Foundation
import SwiftUI


fileprivate struct TextViewInsetPadding: EnvironmentKey {
    static var defaultValue: EdgeInsets = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}
fileprivate struct TextViewPlaceholderString: EnvironmentKey {
    static var defaultValue: String?
}
fileprivate struct TextViewAttributedString: EnvironmentKey {
    static var defaultValue: (NSMutableAttributedString) -> NSMutableAttributedString? = { _ in nil }
}
fileprivate struct TextViewEditorFont: EnvironmentKey {
    static var defaultValue: SystemFontAlias = defaultEditorFont
}

extension EnvironmentValues {
    
    var textViewEditorFont: SystemFontAlias {
        get { self[TextViewEditorFont.self] }
        set { self[TextViewEditorFont.self] = newValue }
    }
    
    /// Set padding insets.
    var textViewInsetPadding: EdgeInsets {
        get { self[TextViewInsetPadding.self] }
        set { self[TextViewInsetPadding.self] = newValue }
    }
    
//    var textViewAttributedString: (NSMutableAttributedString) -> NSMutableAttributedString? {
//        get { self[TextViewAttributedString.self] }
//        set { self[TextViewAttributedString.self] = newValue }
//    }
    var textViewPlaceholderString: String? {
        get { self[TextViewPlaceholderString.self] }
        set { self[TextViewPlaceholderString.self] = newValue }
    }
}

public enum TextViewComponent {
    /// Set editor padding
    case insetPadding
    /// Set editor placeholder
    case placeholderString
}

@available(iOS 13.0, macOS 10.15, *)
public extension View {
    /// Sets the tint color for specific MarkdownView component.
    ///
    /// ```swift
    /// TextEditorPlus(text: $text)
    ///    .textSetting(isEditable, for: .isEditable)
    ///    .textSetting(25, for: .insetPadding)
    /// ```
    ///
    /// - Parameters:
    ///   - value: The value of the component attribute.
    ///   - component: Specify the component's attribute.
    @ViewBuilder func textSetting<T>(_ value: T, for component: TextViewComponent) -> some View {
        switch component {
            case .insetPadding:
                environment(\.textViewInsetPadding, value as! EdgeInsets)
            case .placeholderString:
                environment(\.textViewPlaceholderString, value as! String?)
        }
    }

    @ViewBuilder func textEditorViewContentInset(insets: EdgeInsets) -> some View {
        environment(\.textViewInsetPadding, insets)
        
    }
    
    @ViewBuilder func textEditorViewPlaceholderTxt(placeholderTxt: String?) -> some View {
        environment(\.textViewPlaceholderString, placeholderTxt)
        
    }

    @ViewBuilder func textEditorViewFont(font: SystemFontAlias) -> some View {
        environment(\.textViewEditorFont, font)
    }
    
    
}
