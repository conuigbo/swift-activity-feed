//
//  PostDetailTableViewController.swift
//  GetStreamActivityFeed
//
//  Created by Alexey Bukhtin on 01/02/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

open class PostDetailTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let refreshControl  = UIRefreshControl(frame: .zero)
    var activityPresenter: ActivityPresenter<Activity>?
    var reactionPaginator: ReactionPaginator<ReactionExtraData, User>?
    let textToolBar = TextToolBar.textToolBar
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        UIApplication.shared.appDelegate.currentUser?.loadAvatar { [weak self] in
            self?.setupCommentTextField(avatarImage: $0)
        }
        
        if let activityPresenter = activityPresenter {
            reactionPaginator = activityPresenter.reactionPaginator(reactionKind: .comment)
            reactionPaginator?.load(completion: commentsLoaded)
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

// MARK: - Table view data source

extension PostDetailTableViewController: UITableViewDataSource, UITableViewDelegate {
    
    func setupTableView() {
        tableView.refreshControl = refreshControl
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerPostCells()
        
        refreshControl.addValueChangedAction { [weak self] control in
            if let self = self {
                self.reactionPaginator?.load(completion: self.commentsLoaded)
            }
        }
    }
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let activityPresenter = activityPresenter else {
            return 0
        }
        
        let activity = activityPresenter.activity.originalActivity
        
        switch section {
        case 0: return activityPresenter.cellsCount - 1
        case 1: return activity.likesCount > 0 ? 1 : 0
        case 2: return activity.repostsCount
        case 3:
            if let reactionPaginator = reactionPaginator {
                return reactionPaginator.count + (reactionPaginator.hasNext ? 1 : 0)
            }
        default: break
        }
        
        return 0
    }
    
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let title = sectionHeader(in: section) else {
            return nil
        }
        
        let view = UIView(frame: .zero)
        view.backgroundColor = Appearance.Color.lightGray
        
        let label = UILabel(frame: .zero)
        label.textColor = .gray
        label.attributedText = NSAttributedString(string: title.uppercased(), attributes: Appearance.headerTextAttributes())
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.top.bottom.equalToSuperview()
        }
        
        return view
    }
    
    private func sectionHeader(in section: Int) -> String? {
        guard let activity = activityPresenter?.activity.originalActivity else {
            return nil
        }
        
        switch section {
        case 1: return activity.likesCount > 0 ? "Liked (\(activity.likesCount))" : nil
        case 2: return activity.repostsCount > 0 ? "Reposts (\(activity.repostsCount))" : nil
        case 3: return activity.commentsCount > 0 ? "Comments (\(activity.commentsCount))" : nil
        default: return nil
        }
    }
    
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 || sectionHeader(in: section) == nil ? 0 : 30
    }
    
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let activityPresenter = activityPresenter else {
            return .unused
        }
        
        switch indexPath.section {
        case 0:
            if let cell = tableView.postCell(at: indexPath, in: self, type: .detail, presenter: activityPresenter) {
                if let cell = cell as? PostHeaderTableViewCell {
                    cell.updateAvatar(with: activityPresenter.activity)
                }
                
                return cell
            }
        case 1:
            let cell = tableView.dequeueReusableCell(for: indexPath) as ActionUsersTableViewCell
            cell.titleLabel.text = activityPresenter.reactionTitle(kindOf: .like, suffix: "liked the post")
            cell.avatarsStackView.loadImages(with: activityPresenter.reactionUserAvatarURLs(kindOf: .like))
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(for: indexPath) as ActionUsersTableViewCell
            cell.titleLabel.text = activityPresenter.reactionTitle(kindOf: .repost, suffix: "reposted the post")
            cell.avatarsStackView.loadImages(with: activityPresenter.reactionUserAvatarURLs(kindOf: .repost))
            return cell
            
        case 3:
            guard let reactionPaginator = reactionPaginator else {
                return .unused
            }
            
            if indexPath.row >= reactionPaginator.count {
                reactionPaginator.loadNext(completion: commentsLoaded)
                return tableView.dequeueReusableCell(for: indexPath) as PaginationTableViewCell
            }
            
            let cell = tableView.dequeueReusableCell(for: indexPath) as CommentTableViewCell
            let comment = reactionPaginator.items[indexPath.row]
            
            if case .comment(let text) = comment.data {
                cell.updateComment(name: comment.user.name, comment: text, date: comment.created)
                
                comment.user.loadAvatar { [weak cell] in
                    if let image = $0 {
                        cell?.avatarImageView?.image = image
                    }
                }
            }
            
            return cell
            
        default:
            break
        }
        
        return .unused
    }
    
    open func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && activityPresenter?.ogData != nil
    }
    
    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let openGraph = activityPresenter?.ogData {
            let viewController = WebViewController()
            viewController.url = openGraph.url
            viewController.title = openGraph.title
            present(UINavigationController(rootViewController: viewController), animated: true)
        }
    }
}

// MARK: - Comment Text Field

extension PostDetailTableViewController: UITextViewDelegate {
    private func setupCommentTextField(avatarImage: UIImage?) {
        textToolBar.placeholderText = "Leave reply"
        textToolBar.addToSuperview(view)
        textToolBar.textView.delegate = self
        textToolBar.avatarView.image = avatarImage
        textToolBar.sendButton.addTarget(self, action: #selector(send(_:)), for: .touchUpInside)
        
        tableView.snp.makeConstraints { make in
            make.bottom.equalTo(textToolBar.snp.top)
        }
    }
    
    @objc func send(_ button: UIButton) {
        view.endEditing(true)
        
        guard let text = textToolBar.textView.text, !text.isEmpty, let activityPresenter = activityPresenter else {
            return
        }
        
        textToolBar.textView.text = nil
        textToolBar.addPlaceholder()
        textToolBar.textView.isEditable = false
        
        activityPresenter.reactionPresenter.addComment(for: activityPresenter.activity, text: text) { [weak self] in
            if let self = self {
                self.textToolBar.textView.isEditable = true
                
                if let error = $0.error {
                    self.showErrorAlert(error)
                } else {
                    self.reactionPaginator?.load(completion: self.commentsLoaded)
                }
            }
        }
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textToolBar.clearPlaceholder()
        return true
    }
    
    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        textToolBar.addPlaceholder()
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        textToolBar.sendButton.isEnabled = !textView.text.isEmpty
        textToolBar.updateTextHeightIfNeeded()
    }
}

// MARK: - Comments Pagination

extension PostDetailTableViewController {
    private func commentsLoaded(_ error: Error?) {
        refreshControl.endRefreshing()
        
        if let error = error {
            showErrorAlert(error)
        } else {
            tableView.reloadSections([3], with: .none)
        }
    }
}
