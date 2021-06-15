//
//  TableViewCell.swift
//  Messenger
//
//  Created by Jervy Umandap on 6/14/21.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    private let optionLabel: UILabel = {
        let label = UILabel()
        
        return label
    }()
    
    private let iconContainer: UIView = {
        let view = UIView()
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        view.backgroundColor = .systemBlue
        return view
    }()
    
    private let icon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.layer.masksToBounds = true
        imageView.clipsToBounds = true
        imageView.tintColor = .white
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(icon)
        contentView.addSubview(optionLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconContainerSize = contentView.height*0.7
        iconContainer.frame = CGRect(
            x: 16,
            y: (contentView.height-iconContainerSize)/2,
            width: iconContainerSize,
            height: iconContainerSize)
        iconContainer.layer.cornerRadius = iconContainerSize/2
        
        let iconSize = iconContainerSize*0.6
        icon.frame = CGRect(
            x: (iconContainer.width-iconSize)/2,
            y: (iconContainer.height-iconSize)/2,
            width: iconSize,
            height: iconSize)
        
        optionLabel.frame = CGRect(
            x: iconContainer.right+10,
            y: 0,
            width: contentView.width-iconContainer.width-32-10,
            height: contentView.height)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        optionLabel.text = nil
        icon.image = nil
        
    }
    
    public func setUp(withModel viewModel: ProfileViewModel) {
        
        optionLabel.text = viewModel.title
        
        switch viewModel.viewModelType {
        case .logout:
            textLabel?.textColor = .label
            textLabel?.textAlignment = .left
            icon.image = UIImage(systemName: viewModel.iconName)
            iconContainer.backgroundColor = viewModel.color
        case .legalPolicies:
            textLabel?.textColor = .label
            textLabel?.textAlignment = .left
            accessoryType = .disclosureIndicator
            icon.image = UIImage(systemName: viewModel.iconName)
            iconContainer.backgroundColor = viewModel.color
        case .help:
            textLabel?.textColor = .systemRed
            textLabel?.textAlignment = .left
            accessoryType = .disclosureIndicator
            icon.image = UIImage(systemName: viewModel.iconName)
            iconContainer.backgroundColor = viewModel.color
        }
    }
}
