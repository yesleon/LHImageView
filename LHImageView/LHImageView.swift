//
//  LHImageView.swift
//  Storyboards
//
//  Created by 許立衡 on 2018/10/22.
//  Copyright © 2018 narrativesaw. All rights reserved.
//

import UIKit
import MobileCoreServices
import LHConvenientMethods

public protocol LHImageViewDelegate: AnyObject {
    func imageViewDidChange(_ imageView: LHImageView)
    func customMenuItems(for imageView: LHImageView) -> [UIMenuItem]?
    func imageView(_ imageView: LHImageView, performAction action: Selector, sender: Any?)
}

@IBDesignable
open class LHImageView: UIImageView {
    
    @IBInspectable
    open var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable
    open var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            } else {
                return nil
            }
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    @IBInspectable
    open var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    open weak var delegate: LHImageViewDelegate?
    
    override open var canBecomeFirstResponder: Bool {
        return isUserInteractionEnabled
    }
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPress)))
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissMenu)))
        let panGesture: UIGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dismissMenu))
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
        
        let dragInteraction = UIDragInteraction(delegate: self)
        dragInteraction.isEnabled = true
        addInteraction(dragInteraction)
        
        let dropInteraction = UIDropInteraction(delegate: self)
        addInteraction(dropInteraction)
    }
    
    private func setMenuVisible(_ visible: Bool, animated: Bool) {
        let menuController = UIMenuController.shared
        if visible {
            menuController.menuItems = delegate?.customMenuItems(for: self)
            becomeFirstResponder()
            menuController.setTargetRect(bounds, in: self)
            menuController.setMenuVisible(true, animated: animated)
        } else {
            menuController.menuItems = nil
            resignFirstResponder()
            menuController.setMenuVisible(false, animated: animated)
        }
    }
    
    @objc private func dismissMenu(_ sender: Any) {
        setMenuVisible(false, animated: true)
    }
    
    @objc private func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        setMenuVisible(true, animated: true)
    }

    override open func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let items = delegate?.customMenuItems(for: self) {
            let actions = items.map { $0.action }
            if actions.contains(action) {
                return true
            }
        }
        switch action {
        case #selector(delete), #selector(cut), #selector(copy(_:)), #selector(_share):
            return image != nil
        case #selector(paste(_:)):
            return UIPasteboard.general.hasImages
        default:
            return false
        }
    }
    
    override open func delete(_ sender: Any?) {
        image = nil
        delegate?.imageViewDidChange(self)
    }
    
    override open func cut(_ sender: Any?) {
        UIPasteboard.general.image = image
        image = nil
        delegate?.imageViewDidChange(self)
    }
    
    override open func copy(_ sender: Any?) {
        UIPasteboard.general.image = image
    }
    
    override open func paste(_ sender: Any?) {
        image = UIPasteboard.general.image
        delegate?.imageViewDidChange(self)
    }
    
    @objc open func _share(_ sender: Any?) {
        guard let image = image else { return }
        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self
            popoverController.sourceRect = bounds
        }
        if let topVC = window?.topViewController {
            topVC.present(activityVC, animated: true)
        }
    }

}

extension LHImageView: UIGestureRecognizerDelegate {
    
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}

extension LHImageView: UIDragInteractionDelegate {
    
    open func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem] {
        guard let image = image else { return [] }
        
        let provider = NSItemProvider(object: image)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = image
        return [item]
    }
    
}

extension LHImageView: UIDropInteractionDelegate {
    
    open func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.hasItemsConforming(toTypeIdentifiers: [kUTTypeImage as String]) && session.items.count == 1
    }
    
    open func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    open func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        if let item = session.items.first, let image = item.localObject as? UIImage {
            self.image = image
            self.delegate?.imageViewDidChange(self)
        } else {
            session.loadObjects(ofClass: UIImage.self) { imageItems in
                let images = imageItems as! [UIImage]
                self.image = images.first
                self.delegate?.imageViewDidChange(self)
            }
        }
    }
    
    open func dropInteraction(_ interaction: UIDropInteraction, item: UIDragItem, willAnimateDropWith animator: UIDragAnimating) {
        alpha = 0
        animator.addCompletion { position in
            self.alpha = 1
        }
    }
    
    open func dropInteraction(_ interaction: UIDropInteraction, previewForDropping item: UIDragItem, withDefault defaultPreview: UITargetedDragPreview) -> UITargetedDragPreview? {
        return UITargetedDragPreview(view: self)
    }
    
}
