//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/6/23.
//

import Foundation
import SwiftUI
import Combine


public protocol HighlightedTextEditorProcessor {
    
    //an optional pre-highlighting transformation of the text editor's raw string
    func preHighlightTransform(_ ogText: String) -> String
    
    //an optional transform of the annotated / highlighted text
    func postHighlightTransform(_ highlighted: NSMutableAttributedString) -> NSMutableAttributedString
}




public class HighlightedTextEditorContext: ObservableObject, Equatable, Hashable {
    public typealias HeightChangeEvent = (CGFloat, CGFloat)
    
    public static func == (lhs: HighlightedTextEditorContext, rhs: HighlightedTextEditorContext) -> Bool {
        lhs.id == rhs.id
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public let id: String
    
    
    public var isEditingText: Bool { isEditingTextPub.value }
    
    let isEditingTextPub = CurrentValueSubject<Bool, Never>(false)
    
    let willChangeHeightPub = PassthroughSubject<HeightChangeEvent, Never>()
    let didChangeHeightPub = PassthroughSubject<HeightChangeEvent, Never>()
    
    var currentHeight: CGFloat {
        currentHeightPub.value
    }
    
    
    public let currentHeightPub: CurrentValueSubject<CGFloat, Never>
    
    public let currentSizePub: CurrentValueSubject<CGSize, Never> = .init(.zero)
    public var currentSize: CGSize {
        currentSizePub.value
    }
    
    
    public let lineCountPub =  CurrentValueSubject<Int, Never>(1)
    public var lineCount: Int {
        lineCountPub.value
    }
    
    
    private var cancellables: Set<AnyCancellable> = []

    public var highlightRules: [HighlightRule]
    
    @Published public var iosMinLineCount: Int
    @Published public var iosMaxLineCount: Int
    
    @Published public var expMinHeight: CGFloat
    @Published public var expMaxHeight: CGFloat
    
    
    
    private(set) public var processors: [HighlightedTextEditorProcessor] = []
    
    //this is published to upon changes from ui/nstextview delegates
    public let rawTextChangePub: CurrentValueSubject<String, Never>
    public let highlightedTextChangePub: CurrentValueSubject<NSMutableAttributedString, Never>
    
    @Published public var highlightedTxt: NSMutableAttributedString
    public var text: String {
        highlightedTxt.string
    }
    
    @Published public var dynamicHeight: Bool
    
    
    public init(_ startingText: String = "",
                highlightRules: [HighlightRule] = .markdown,
                id: String = UUID().uuidString,
                iosMinLineCount: Int = 1,
                iosMaxLineCount: Int = 4,
                expMinHeight: CGFloat = 50,
                expMaxHeight: CGFloat = 400,
                startingHeight: CGFloat = 0,
                dynamicHeight: Bool = true
    ) {
        
        self.id = id
        self.highlightRules = highlightRules
        self.currentHeightPub = .init(startingHeight)
        self.dynamicHeight = dynamicHeight
        
        
        self.iosMinLineCount = iosMinLineCount
        self.iosMaxLineCount = iosMaxLineCount
        
        self.expMinHeight = expMinHeight
        self.expMaxHeight = expMaxHeight
        
        
        self.rawTextChangePub = .init(startingText)
        self.highlightedTextChangePub = .init(NSMutableAttributedString(string: startingText))
        self.highlightedTxt = NSMutableAttributedString(string: startingText)
        self.setupPipeline()
//        self.rawTextChangePub.send(startingText)
    }
    
    public func removeAllProcessors() {
        self.processors = []
    }
    public func insertProcessorAtFront(_ processor: HighlightedTextEditorProcessor) {
        self.processors.insert(processor, at: 0)
    }
    public func appendProcessor(_ processor: HighlightedTextEditorProcessor) {
        self.processors.append(processor)
    }
    
    
    private func setupPipeline() {
        didChangeHeightPub
            .sink { (old, new) in
                self.currentHeightPub.send(new)
            }
            .store(in: &cancellables)
        
        self.rawTextChangePub
        //todo on a bg thread / off the main thread
            .map { rawTxt in
                return self.executeRawTextToPostHighlight(rawTxt)
            }
            .sink { highlightTxt in
                self.highlightedTextChangePub.send(highlightTxt)
            }
            .store(in: &cancellables)
        
        
        self.highlightedTextChangePub
            .receive(on: DispatchQueue.main)
            .sink { finalHighlightedTxt in
                //set the published
                self.highlightedTxt = finalHighlightedTxt
                print("\n\n \(finalHighlightedTxt) \n\nCurrent line count: \(self.lineCount)")
            }
            .store(in: &cancellables)
    }
    
    public func setText(_ rawTxt: String, skipTransforms: Bool = false) {
        if skipTransforms {
            let attr = NSMutableAttributedString(string: rawTxt)
            self.highlightedTextChangePub.send(attr)
            
        } else {
            let attr = self.executeRawTextToPostHighlight(rawTxt)
            self.highlightedTextChangePub.send(attr)
        }
        
    }
    
    public func setCurrentFrameSize(_ size: CGSize) {
        self.currentSizePub.send(size)
    }
    
    public func setCurrentNumberOfLines(_ num: Int) {
        print("setting line count to \(num)")
        self.lineCountPub.send(num)
    }
    
    
    private func executeRawTextToPostHighlight(_ rawTxt: String) -> NSMutableAttributedString {
        let preHighlight = self.executePreHighlightTransform(rawTxt)
        let highlighted = HighlightedTextEditor.getHighlightedText(
            text: preHighlight,
            highlightRules: self.highlightRules)
        let postHighlighted = self.executePostHighlightTransform(highlighted)
        return postHighlighted
    }
    
    
    private func executePreHighlightTransform(_ rawTxt: String) -> String {
        guard self.processors.count > 0 else { return rawTxt }
        var txt = rawTxt
        for processor in processors {
            txt = processor.preHighlightTransform(txt)
        }
        return txt
    }
    private func executePostHighlightTransform(_ rawHighlighted: NSMutableAttributedString) -> NSMutableAttributedString {
        guard self.processors.count > 0 else { return rawHighlighted }
        var highlighted = rawHighlighted
        for processor in processors {
            highlighted = processor.postHighlightTransform(highlighted)
        }
        return highlighted
    
    }
    
    
    
    //called by the ui/nstextview delegate
    public func textDidChangeTo(_ newText: String) {
        self.rawTextChangePub.send(newText)
    }
    
    
    
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
    
    
    
    public func iosHeightWillChange(_ from: CGFloat, to: CGFloat) {
        self.willChangeHeightPub.send((from, to))
    }
    
    public func iosHeightDidChange(_ from: CGFloat, to: CGFloat) {
        self.didChangeHeightPub.send((from, to))
    }
    
}

public extension HighlightedTextEditorContext {
    
    static func defaultCtx() -> HighlightedTextEditorContext {
        HighlightedTextEditorContext()
    }
    
}
