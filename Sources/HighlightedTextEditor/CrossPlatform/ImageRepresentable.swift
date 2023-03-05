//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/5/23.
//


#if canImport(AppKit)
import AppKit

/**
 This typealias bridges platform-specific fonts, to simplify
 multi-platform support.
 */
public typealias ImageRepresentable = NSImage
#endif

#if canImport(UIKit)
import UIKit

/**
 This typealias bridges platform-specific fonts, to simplify
 multi-platform support.
 */
public typealias ImageRepresentable = UIImage
#endif
