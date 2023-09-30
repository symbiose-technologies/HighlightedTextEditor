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
    
    //source of truth
    public let resolvedIsEditingPub = CurrentValueSubject<Bool, Never>(false)
    
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
//    @Published public var currentSize: CGSize = .zero
    
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
    
//    @Published public var highlightedTxt: NSMutableAttributedString
    public var highlightedTxt: NSMutableAttributedString
    
    public var text: String {
        highlightedTxt.string
    }
    
//    @Published public var viewText: String
    public var viewText: String { _viewText.value }
    public var _viewText: CurrentValueSubject<String, Never>
    public var viewTextPub: AnyPublisher<String, Never> {
        _viewText.eraseToAnyPublisher()
    }
    
    @Published public var dynamicHeight: Bool
    
    private var _needsRefreshPub =  PassthroughSubject<Bool, Never>()
    public var needsRefreshPub: AnyPublisher<Bool, Never> { _needsRefreshPub.eraseToAnyPublisher() }
    
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
        self.highlightedTxt = NSMutableAttributedString(string: startingText)
//        self.viewText = startingText
        self._viewText = .init(startingText)
        
        self.setupPipeline()
//        self.rawTextChangePub.send(startingText)
    }
    
    private func setNeedsViewRefresh() {
        self._needsRefreshPub.send(true)
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
            .sink { [weak self] rawTxt in
                self?.processRawText(rawTxt)
            }
            .store(in: &cancellables)
        
        
//        self.rawTextChangePub
//        //todo on a bg thread / off the main thread
//            .map { rawTxt in
////                return self.executeRawTextToPostHighlight(rawTxt)
//                self.processRawText(rawTxt)
//            }
//            .sink { highlightTxt in
//                self.highlightedTextChangePub.send(highlightTxt)
//            }
//            .store(in: &cancellables)
//        
        
//        self.highlightedTextChangePub
//            .receive(on: DispatchQueue.main)
//            .sink { finalHighlightedTxt in
//                //set the published
//                self.highlightedTxt = finalHighlightedTxt
////                print("\n\n \(finalHighlightedTxt) \n\nCurrent line count: \(self.lineCount)")
//            }
//            .store(in: &cancellables)
    }
    
    private let textProcessingQueue = DispatchQueue(label: "com.symbiose.fractal.text-processing", qos: .userInitiated)
    private var isProcessingText: Bool = false
    private var latestRawText: String?
    
    
    private func processRawText(_ rawTxt: String) {
        textProcessingQueue.sync { [weak self] in
            guard let self = self else { return }
            
            if self.isProcessingText {
                self.latestRawText = rawTxt
                return
            }
            self.isProcessingText = true
            let attr = self.executeRawTextToPostHighlight(rawTxt)
            DispatchQueue.main.async {
//                self.highlightedTextChangePub.send(attr)
                self.highlightedTxt = attr
            }
            
            if let latestRawText = self.latestRawText {
                self.latestRawText = nil
                self.processRawText(latestRawText)
            }
            
            self.isProcessingText = false
        }
    }
    
    private func setViewText(_ rawTxt: String) {
//        self.viewText = rawTxt
        self._viewText.send(rawTxt)
    }
    
    func getProcessedText() -> NSMutableAttributedString {
        let attr = self.executeRawTextToPostHighlight(self.viewText)
        self.highlightedTxt = attr
        return attr
    }
    
    func processUpdatedText(_ rawTxt: String) -> NSMutableAttributedString {
        let attr = self.executeRawTextToPostHighlight(rawTxt)
        return attr
    }
    
    public func setText(_ rawTxt: String, skipTransforms: Bool = false) {
        if skipTransforms {
            let attr = NSMutableAttributedString(string: rawTxt)
            self.setViewText(rawTxt)
//            self.viewText = rawTxt
            self.highlightedTxt = attr
            self.setNeedsViewRefresh()
            
        } else {
//            self.viewText = rawTxt
            self.setViewText(rawTxt)
            let attr = self.executeRawTextToPostHighlight(rawTxt)
            self.highlightedTxt = attr
            self.setNeedsViewRefresh()
            
        }
        
    }
    
    public func setCurrentFrameSize(_ size: CGSize) {
//        self.currentSize = size
        self.currentSizePub.send(size)
    }
    
    public func setCurrentNumberOfLines(_ num: Int) {
//        print("setting line count to \(num)")
        self.lineCountPub.send(num)
    }
    
    
    
    func executeRawTextToPostHighlight(_ rawTxt: String) -> NSMutableAttributedString {
        let preHighlight = self.executePreHighlightTransform(rawTxt)
        let highlighted = HighlightedTextEditor.getHighlightedText(
            text: preHighlight,
            highlightRules: self.highlightRules
        )
        let postHighlighted = self.executePostHighlightTransform(highlighted)
        return postHighlighted
    }
    
    
    @inlinable
    func executePreHighlightTransform(_ rawTxt: String) -> String {
        guard self.processors.count > 0 else { return rawTxt }
        var txt = rawTxt
        for processor in processors {
            txt = processor.preHighlightTransform(txt)
        }
        return txt
    }
    
    
    @inlinable
    func executePostHighlightTransform(_ rawHighlighted: NSMutableAttributedString) -> NSMutableAttributedString {
        guard self.processors.count > 0 else { return rawHighlighted }
        var highlighted = rawHighlighted
        for processor in processors {
            highlighted = processor.postHighlightTransform(highlighted)
        }
        return highlighted
    
    }
    
    
    
    //called by the ui/nstextview delegate
    public func textDidChangeTo(_ newText: String) {
        self.setViewText(newText)
//        self.rawTextChangePub.send(newText)
    }
    
    //called by the coordinator AFTER making the editor active/inactive
    public func didMakeActive(isActive: Bool) {
        self.resolvedIsEditingPub.send(isActive)
    }
    
    
    //called to SET the active/inactive state of the editor
    public func setEditingActive(isActive: Bool) {
        if isActive {
            self.startEditingText()
        } else {
            self.stopEditingText()
        }
    }
    
    
    public func stopEditingText() {
        if resolvedIsEditingPub.value {
            isEditingTextPub.send(false)
        }
    }
    
    
    public func startEditingText() {
        if !resolvedIsEditingPub.value {
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
