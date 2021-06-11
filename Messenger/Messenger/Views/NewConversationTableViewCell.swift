//
//  NewConversationTableViewCell.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/11/21.
//

import UIKit
import SDWebImage

class NewConversationTableViewCell: UITableViewCell {
    
    static let identifier = "NewConversationTableViewCell"
    
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
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(usernameLabel)
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
            y: 10,
            width: contentView.width-userImageView.width-32-10-userImageView.width,
            height: contentView.height-20)
//        usernameLabel.backgroundColor = .systemPink
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        userImageView.image = nil
        usernameLabel.text = nil
    }
    
    public func configure(with model: SearchResult) {
        usernameLabel.text = model.name.capitalized
        
        
        let path = "images/\(model.email)_profile_picture.png"
        
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
