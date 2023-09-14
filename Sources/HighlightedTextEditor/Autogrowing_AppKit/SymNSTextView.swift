//
//  File.swift
//  
//
//  Created by Ryan Mckinney on 3/5/23.
//
#if os(macOS)
import Foundation
import AppKit

open class SymNSTextView: NSTextView {
    
    // MARK: - Overrides

    /**
     Paste the current pasteboard content into the text view.
     */
    
    open override var frame: CGRect {
        didSet {
            let newSize = self.frame.size
            if oldValue.size != newSize {
                self.sizeChangeCb?(newSize)
            }
        }
    }
    
    public var sizeChangeCb: ((CGSize) -> Void)?

    
    var onPastedContent: OnPastedContentCallback?
    var onDroppedContent: OnDroppedContentCallback?
    
    open var attributedText: NSAttributedString {
        get { attributedString() }
        set {
            textStorage?.setAttributedString(newValue)
        }
    }
    
//    open override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
//        return super.readablePasteboardTypes + [NSPasteboard.PasteboardType.tiff]
//    }

    
    
    open override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        let didHandle = self.receiveContents(pasteboard, isPaste: true)
        if didHandle { return }
        
//        if pasteboard.hasImages,
//            let _ = self.onPastedImages,
//           let images = pasteboard.images {
//
//            if let didReceive = self.onPastedImages?(images) {
//                if didReceive { return }
//            }
//        }
        
        super.paste(sender)
    }

    open func receiveContents(_ pasteboard: NSPasteboard, isPaste: Bool) -> Bool {
        var objectsAndTypes: [NSPasteboard.PasteboardType: Any] = [:]
           
        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                // You can interpret the data based on the type here
                // For example, you might convert it to a string or image based on known types
                // For this example, we'll just store the raw data
                objectsAndTypes[type] = data
            }
        }
        for (type, object) in objectsAndTypes {
            print("Type: \(type), Object: \(object)")
        }
        
        
        
        var images: [ImageRepresentable] = []
        var files: [URL] = []
        
        
//        if let imageData = pasteboard.data(forType: NSPasteboard.PasteboardType.tiff) {
//            if let image = NSImage(data: imageData) {
//                images.append(image)
//            }
//        }
        
        pasteboard.readObjects(forClasses: [NSImage.self, NSURL.self], options: nil)?.forEach { eachObject in
            if let image = eachObject as? ImageRepresentable {
                images.append(image)
            } else if let eachURL = eachObject as? URL {
                print(eachURL.path)
                files.append(eachURL)
            }
        }
        if isPaste {
            return self.onPastedContent?(images, files) ?? false
        } else {
            return self.onDroppedContent?(images, files) ?? false
        }
    }
    
    /**
     Try to perform a certain drag operation, which will get
     and paste images from the drag info into the text.
     */
    open override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        let pasteboard = draggingInfo.draggingPasteboard
        return self.receiveContents(pasteboard, isPaste: false)
//        if pasteboard.hasImages,
//            let _ = self.onDroppedImages,
//           let images = pasteboard.images {
//            self.onDroppedImages?(images)
////            if let didReceive = self.onDroppedImages?(images) {
////                return didReceive
////            }
//        }
        
//        return super.performDragOperation(draggingInfo)
    }

    
    open override func draggingEntered(_ draggingInfo: NSDraggingInfo) -> NSDragOperation  {
        let isHandling: Bool = true
            switch (isHandling) {
                case true:
                    color(to: .secondaryLabelColor)
                    return .copy
                case false:
                    color(to: .clear)
                    return .init()
            }
    }
    
    open override func draggingExited(_ sender: NSDraggingInfo?)
    { color(to: .clear) }

    open override func draggingEnded(_ sender: NSDraggingInfo)
    { color(to: .clear) }
    
    func color(to color: NSColor)
        {
            self.backgroundColor = color
//            self.wantsLayer = true
//            self.layer?.backgroundColor = color.cgColor
        }
    
    // MARK: - Open Functionality

    /**
     Alert a certain title and message.

     - Parameters:
       - title: The alert title.
       - message: The alert message.
       - buttonTitle: The alert button title.
     */
//    open func alert(title: String, message: String, buttonTitle: String) {
//        let alert = NSAlert()
//        alert.messageText = title
//        alert.informativeText = message
//        alert.alertStyle = NSAlert.Style.warning
//        alert.addButton(withTitle: buttonTitle)
//        alert.runModal()
//    }

    /**
     Copy the current selection.
     */
//    open func copySelection() {
//        let pasteboard = NSPasteboard.general
//        let range = safeRange(for: selectedRange)
//        let text = richText(at: range)
//        pasteboard.clearContents()
//        pasteboard.setString(text.string, forType: .string)
//    }

    /**
     Try to redo the latest undone change.
     */
    open func redoLatestChange() {
        undoManager?.redo()
    }

    /**
     Scroll to a certain range.

     - Parameters:
       - range: The range to scroll to.
     */
//    open func scroll(to range: NSRange) {
//        scrollRangeToVisible(range)
//    }

    

    /**
     Undo the latest change.
     */
    open func undoLatestChange() {
        undoManager?.undo()
    }
    
    /**
     Get a safe range for the provided range.

     A safe range is limited to the bounds of the attributed
     string and helps protecting against range overflow.

     - Parameters:
       - range: The range for which to get a safe range.
     */
    func safeRange(for range: NSRange) -> NSRange {
        let length = attributedString.length
        return NSRange(
            location: max(0, min(length-1, range.location)),
            length: min(range.length, max(0, length - range.location)))
    }
    
    
    

    open override func menu(for event: NSEvent) -> NSMenu? {
       let menu = super.menu(for: event)

       let selectedRange = self.selectedRange()
       if selectedRange.length > 0 {
           let highlightAction = NSMenuItem(title: "Highlight", action: #selector(highlightAction(_:)), keyEquivalent: "")
           highlightAction.target = self
           menu?.addItem(highlightAction)
       }

       let addBookmarkAction = NSMenuItem(title: "Add Bookmark", action: #selector(addBookmarkAction(_:)), keyEquivalent: "")
       addBookmarkAction.target = self
       menu?.addItem(addBookmarkAction)

       return menu
   }

   @objc func highlightAction(_ sender: Any) {
       // Highlight action
       print("highlight")
   }

   @objc func addBookmarkAction(_ sender: Any) {
       // Add bookmark action
       print("add bookmark")
   }
    
}



#endif
