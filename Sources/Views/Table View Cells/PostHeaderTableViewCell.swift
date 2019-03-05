//
//  PostHeaderTableViewCell.swift
//  GetStreamActivityFeed
//
//  Created by Alexey Bukhtin on 18/01/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Nuke
import GetStream

open class PostHeaderTableViewCell: BaseTableViewCell {

    @IBOutlet public weak var avatarButton: UIButton!
    @IBOutlet public weak var nameLabel: UILabel!
    @IBOutlet private weak var repostInfoStackView: UIStackView!
    @IBOutlet private weak var repostInfoLabel: UILabel!
    @IBOutlet public weak var dateLabel: UILabel!
    @IBOutlet public weak var messageLabel: UILabel!
    @IBOutlet private weak var messageBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var photoImageView: UIImageView!
    
    public var repost: String? {
        get {
            return repostInfoLabel.text
        }
        set {
            if let reply = newValue {
                repostInfoStackView.isHidden = false
                repostInfoLabel.text = reply
            } else {
                repostInfoStackView.isHidden = true
            }
        }
    }
    
    open override func reset() {
        updateAvatar(with: nil)
        avatarButton.removeTap()
        avatarButton.isEnabled = true
        avatarButton.isUserInteractionEnabled = true
        nameLabel.text = nil
        dateLabel.text = nil
        repostInfoLabel.text = nil
        repostInfoStackView.isHidden = true
        messageLabel.text = nil
        messageBottomConstraint.priority = .defaultHigh + 1
        photoImageView.image = nil
        photoImageView.isHidden = true
    }
    
    public func updateAvatar(with image: UIImage?) {
        if let image = image {
            avatarButton.setImage(image, for: .normal)
            avatarButton.contentHorizontalAlignment = .fill
            avatarButton.contentVerticalAlignment = .fill
        } else {
            avatarButton.setImage(.profileIcon, for: .normal)
            avatarButton.contentHorizontalAlignment = .center
            avatarButton.contentVerticalAlignment = .center
        }
    }
    
    public func updatePhoto(with url: URL) {
        messageBottomConstraint.priority = .defaultLow
        photoImageView.isHidden = false
        
        ImagePipeline.shared.loadImage(with: url) { [weak self] response, error in
            self?.photoImageView.image = response?.image
        }
    }
}

extension PostHeaderTableViewCell {
    
    func update(with activity: Activity) {
        let originalActivity = activity.original
        nameLabel.text = originalActivity.actor.name
        messageLabel.text = originalActivity.text
        
        switch originalActivity.object {
        case .text(let text):
            messageLabel.text = text
        case .image(let url):
            updatePhoto(with: url)
        case .following(let user):
            messageLabel.text = "Follow to \(user.name)"
        default:
            return
        }
        
        dateLabel.text = activity.time?.relative
        
        if activity.verb == .repost {
            repost = "reposted by \(activity.actor.name)"
        }
    }
    
    func updateAvatar(with activity: Activity, action: UIControl.Action? = nil) {
        if let action = action {
            avatarButton.addTap(action)
        } else {
            avatarButton.isUserInteractionEnabled = false
        }
        
        if let avatarURL = activity.actor.avatarURL {
            ImagePipeline.shared.loadImage(with: avatarURL.imageRequest(in: avatarButton)) { [weak self] response, error in
                self?.updateAvatar(with: response?.image)
            }
        }
    }
}
