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
    
    
    var onPastedImages: OnPastedImagesCallback?
    var onDroppedImages: OnDroppedImagesCallback?
    
    
    open override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general
        
        if pasteboard.hasImages,
            let _ = self.onPastedImages,
           let images = pasteboard.images {
            
            if let didReceive = self.onPastedImages?(images) {
                if didReceive { return }
            }
        }
        
        super.paste(sender)
    }

    /**
     Try to perform a certain drag operation, which will get
     and paste images from the drag info into the text.
     */
    open override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
        let pasteboard = draggingInfo.draggingPasteboard
        
        if pasteboard.hasImages,
            let _ = self.onDroppedImages,
           let images = pasteboard.images {
            if let didReceive = self.onDroppedImages?(images) {
                return didReceive
            }
        }
//        let pasteboard = draggingInfo.draggingPasteboard
//        if let images = pasteboard.images, images.count > 0 {
//            if self.isOverridingDropBehavior() {
//                if let ctxDel = self.contextDelegate {
//                    ctxDel.handleDroppedImages(images: images)
//                    return true
//                }
//            }
//
//            pasteImages(images, at: selectedRange().location, moveCursorToPastedContent: true)
//            return true
//        }
        return super.performDragOperation(draggingInfo)
    }

    
    // MARK: - Open Functionality

    /**
     Alert a certain title and message.

     - Parameters:
       - title: The alert title.
       - message: The alert message.
       - buttonTitle: The alert button title.
     */
    open func alert(title: String, message: String, buttonTitle: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: buttonTitle)
        alert.runModal()
    }

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
    open func scroll(to range: NSRange) {
        scrollRangeToVisible(range)
    }

    

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
}



#endif
