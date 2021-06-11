//
//  ConversationTableViewCell.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/8/21.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        
        return imageView
    }()
    
    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let imageSize = contentView.height*0.90
        
        userImageView.frame = CGRect(
            x: 16,
            y: (contentView.height-imageSize)/2,
            width: imageSize,
            height: imageSize)
        userImageView.layer.cornerRadius = imageSize/2
//        userImageView.backgroundColor = .systemGreen
        
        usernameLabel.frame = CGRect(
            x: userImageView.right+10,
            y: 5,
            width: contentView.width-userImageView.width-32-10-userImageView.width,
            height: (contentView.height/2)-5)
//        usernameLabel.backgroundColor = .systemPink
        
        userMessageLabel.frame = CGRect(
            x: userImageView.right+10,
            y: usernameLabel.bottom,
            width: contentView.width-userImageView.width-32-10-userImageView.width,
            height: (contentView.height/2)-5)
//        userMessageLabel.backgroundColor = .systemTeal
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userImageView.image = nil
        usernameLabel.text = nil
        userMessageLabel.text = nil
    }
    
    public func configure(with model: Conversation) {
        usernameLabel.text = model.name.capitalized
        userMessageLabel.text = model.latestMessage.text
        
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        
        StorageManager.shared.getDownloadURL(forPath: path, completion: { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("Failed to get image url: - \(error.localizedDescription)")
            }
        })
    }
    
}
