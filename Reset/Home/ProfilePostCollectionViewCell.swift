//
//  ProfilePostCollectionViewCell.swift
//  Reset
//
//  Created by Prasanjit Panda on 07/01/25.
//

import UIKit

class ProfilePostCollectionViewCell: UICollectionViewCell {
    static let identifier = "ProfilePostCollectionViewCell"
    
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(postImageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        postImageView.frame = contentView.bounds
    }
    
    public func configure(with image: UIImage) {
        postImageView.image = image
    }
}
