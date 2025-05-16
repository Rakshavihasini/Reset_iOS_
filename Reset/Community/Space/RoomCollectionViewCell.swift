//
//  RoomCollectionViewCell.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/02/25.
//


import UIKit

class RoomCollectionViewCell: UICollectionViewCell {
    
    // MARK: - UI Components
    private let liveIndicatorLabel: UILabel = {
        let label = UILabel()
        label.text = "LIVE"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let listenersStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 5
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private let listenerAvatars: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let listenerCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hostProfileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 15
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let hostNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let backgroundCardView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemPurple
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(backgroundCardView)
        backgroundCardView.addSubview(liveIndicatorLabel)
        backgroundCardView.addSubview(titleLabel)
        backgroundCardView.addSubview(listenersStackView)
        listenersStackView.addArrangedSubview(listenerAvatars)
        listenersStackView.addArrangedSubview(listenerCountLabel)
        backgroundCardView.addSubview(hostProfileImageView)
        backgroundCardView.addSubview(hostNameLabel)
        
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundCardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundCardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundCardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundCardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            liveIndicatorLabel.topAnchor.constraint(equalTo: backgroundCardView.topAnchor, constant: 10),
            liveIndicatorLabel.leadingAnchor.constraint(equalTo: backgroundCardView.leadingAnchor, constant: 10),
            
            titleLabel.topAnchor.constraint(equalTo: liveIndicatorLabel.bottomAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: backgroundCardView.leadingAnchor, constant: 10),
            
            listenersStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            listenersStackView.leadingAnchor.constraint(equalTo: backgroundCardView.leadingAnchor, constant: 10),
            
            listenerAvatars.widthAnchor.constraint(equalToConstant: 24),
            listenerAvatars.heightAnchor.constraint(equalToConstant: 24),
            
            hostProfileImageView.topAnchor.constraint(equalTo: listenersStackView.bottomAnchor, constant: 10),
            hostProfileImageView.leadingAnchor.constraint(equalTo: backgroundCardView.leadingAnchor, constant: 10),
            hostProfileImageView.widthAnchor.constraint(equalToConstant: 30),
            hostProfileImageView.heightAnchor.constraint(equalToConstant: 30),
            
            hostNameLabel.centerYAnchor.constraint(equalTo: hostProfileImageView.centerYAnchor),
            hostNameLabel.leadingAnchor.constraint(equalTo: hostProfileImageView.trailingAnchor, constant: 8),
        ])
    }
    
    // MARK: - Configure Cell
    func configure(title: String, listeners: String, hostName: String, image: UIImage?) {
        titleLabel.text = title
        listenerCountLabel.text = listeners
        hostNameLabel.text = hostName
        hostProfileImageView.image = image
    }
}
