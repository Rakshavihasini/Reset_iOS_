//
//  SpacesCollectionViewCell.swift
//  Reset
//
//  Created by Prasanjit Panda on 10/12/24.
//

import UIKit

class SpacesCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var spaceTitle: UILabel!
    
    @IBOutlet weak var spaceDesc: UILabel!
    
    @IBOutlet weak var spaceCardView: UIView!
    
    @IBOutlet weak var profileImagesStackView: UIStackView!
    
    private let joinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Join", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .light)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor.white
        button.layer.cornerRadius = 12
        
        // Add drop shadow
        button.layer.shadowColor = UIColor.systemGray2.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 3) // Slightly below the button
        button.layer.shadowOpacity = 0.3  // Adjust shadow strength
        button.layer.shadowRadius = 4    // Smooth blur effect
        button.layer.masksToBounds = false  // Ensure shadow appears outside the button

        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    
    
    override func awakeFromNib() {
        
        super.awakeFromNib()
        profileImagesStackView.translatesAutoresizingMaskIntoConstraints = false

        // Remove any existing constraints affecting horizontal alignment of the stack view
        profileImagesStackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor, constant: 100).isActive = true

        // Initialization code
        
        spaceCardView.layer.cornerRadius = 16
        spaceCardView.layer.shadowColor = UIColor.black.cgColor
        spaceCardView.layer.shadowRadius = 700
        spaceCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        spaceCardView.layer.shadowOpacity = 0.3
        spaceCardView.layer.shadowPath = UIBezierPath(roundedRect: spaceCardView.bounds, cornerRadius: 16).cgPath
        spaceCardView.backgroundColor = UIColor(red: 255/255.0, green: 240/255.0, blue: 220/255.0, alpha: 1.0)

        
        // Join button setup
        contentView.addSubview(joinButton)
        NSLayoutConstraint.activate([
            joinButton.leadingAnchor.constraint(equalTo: spaceCardView.leadingAnchor, constant: 16), // Align left inside card
            joinButton.bottomAnchor.constraint(equalTo: spaceCardView.bottomAnchor, constant: -16), // Stick to bottom inside card
            joinButton.widthAnchor.constraint(equalToConstant: 80),
            joinButton.heightAnchor.constraint(equalToConstant: 26)
        ])

        
    }
    
    
    
    
    
    
    func configureCell(with space: Space, profileImages: [UIImage]) {
        spaceTitle.text = space.title
        spaceDesc.text = space.description
        configureProfileImages(with: profileImages)
    }
    
    func configureProfileImages(with images: [UIImage]) {
        // Clear previous images
        profileImagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        guard !images.isEmpty else { return }
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        profileImagesStackView.addArrangedSubview(containerView)
        
        let imageSize: CGFloat = 37
        let spacing: CGFloat = 26
        
        // Create and position surrounding images FIRST
        let positions: [(CGFloat, CGFloat)] = [
            (0, -spacing),    // Top
            (0, spacing),     // Bottom
            (-spacing, 0),    // Left
            (spacing, 0)      // Right
        ]
        
        for (index, position) in positions.enumerated() {
            if index + 1 >= images.count { break }
            
            let imageView = UIImageView(image: images[index + 1])
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = imageSize / 2
            imageView.layer.borderColor = UIColor.white.cgColor
            containerView.addSubview(imageView)
            
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor, constant: position.0),
                imageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: position.1),
                imageView.widthAnchor.constraint(equalToConstant: imageSize),
                imageView.heightAnchor.constraint(equalToConstant: imageSize)
            ])
        }
        
        // Create middle image LAST (to be on top)
        let middleImageView = UIImageView(image: images[0])
        middleImageView.contentMode = .scaleAspectFill
        middleImageView.clipsToBounds = true
        middleImageView.layer.cornerRadius = imageSize / 2
        containerView.addSubview(middleImageView)
        
        middleImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            middleImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            middleImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            middleImageView.widthAnchor.constraint(equalToConstant: imageSize),
            middleImageView.heightAnchor.constraint(equalToConstant: imageSize)
        ])
    }
    
}
