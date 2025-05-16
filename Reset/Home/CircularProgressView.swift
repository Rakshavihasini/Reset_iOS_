//
//  CircularProgressView.swift
//  Reset
//
//  Created by Prasanjit Panda on 09/01/25.
//


import UIKit

class CircularProgressViewAnimated: UIView {
    private let progressLayer = CAShapeLayer()
    private let backgroundLayer = CAShapeLayer()
    private let gradientLayer = CAGradientLayer()
    
    // Container view for the circle and inner content
    private let circleContainer: UIView = {
        let view = UIView()
        return view
    }()
    
    // Top Labels
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = UIColor(red: 198/255, green: 145/255, blue: 85/255, alpha: 1)
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    // Center Labels (inside circle)
    private let innerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        return stack
    }()
    
    private let daysNumberLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textColor = UIColor(red: 198/255, green: 145/255, blue: 85/255, alpha: 1)
        return label
    }()
    
    private let daysSoberLabel: UILabel = {
        let label = UILabel()
        label.text = "days Sober"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.textColor = .gray
        return label
    }()
    
    // Bottom Stack View
    private lazy var bottomStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [milestonesStack, resetStack])
        stack.axis = .horizontal
        stack.spacing = 8  // Reduced from 20 to 8 for closer spacing
        stack.distribution = .equalCentering // Use .equalCentering instead of .center
        stack.alignment = .center
        return stack
    }()
    
    private lazy var milestonesStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [milestonesImageView, milestonesLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private lazy var resetStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [resetImageView, resetLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let milestonesImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "medal.fill")
        imageView.tintColor = UIColor(red: 198/255, green: 145/255, blue: 85/255, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let resetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
        imageView.tintColor = UIColor(red: 198/255, green: 145/255, blue: 85/255, alpha: 1)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let milestonesLabel: UILabel = {
        let label = UILabel()
        label.text = "Milestones"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    private let resetLabel: UILabel = {
        let label = UILabel()
        label.text = "Reset"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        
    }
    
    // MARK: - Setup
    private func setupView() {
    

                // Setup inner stack view
                innerStackView.addArrangedSubview(daysNumberLabel)
                innerStackView.addArrangedSubview(daysSoberLabel)
                
                // Add all subviews
                addSubview(titleLabel)
                addSubview(subtitleLabel)
                addSubview(circleContainer)
                circleContainer.addSubview(innerStackView)
                addSubview(bottomStackView)
                
                // Add layers to circle container
                circleContainer.layer.addSublayer(backgroundLayer)
                circleContainer.layer.addSublayer(gradientLayer) // Add gradient layer
                gradientLayer.mask = progressLayer // Mask gradient layer with progressLayer
                
                // Configure background layer (3D shadow)
                backgroundLayer.fillColor = UIColor.clear.cgColor
                backgroundLayer.strokeColor = UIColor(red: 190/255, green: 100/255, blue: 40/255, alpha: 0.2).cgColor
                backgroundLayer.lineWidth = 14
                backgroundLayer.shadowColor = UIColor.black.cgColor
                backgroundLayer.shadowOpacity = 0.2
                backgroundLayer.shadowRadius = 4
                backgroundLayer.shadowOffset = CGSize(width: 0, height: 2)
                
                // Configure gradient layer
        // Configure gradient layer for bronze
        gradientLayer.colors = [
            UIColor(red: 250/255, green: 232/255, blue: 220/255, alpha: 1).cgColor, // Very light bronze
            UIColor(red: 262/255, green: 200/255, blue: 170/255, alpha: 1).cgColor, // Light bronze
            UIColor(red: 216/255, green: 151/255, blue: 87/255, alpha: 1).cgColor,  // Base bronze (#D89757)
            UIColor(red: 184/255, green: 115/255, blue: 67/255, alpha: 1).cgColor,  // Darker bronze
            UIColor(red: 160/255, green: 100/255, blue: 58/255, alpha: 1).cgColor    // Dark bronze
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5) // Horizontal gradient
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

                
                // Configure progress layer
                progressLayer.fillColor = UIColor.clear.cgColor
                progressLayer.strokeColor = UIColor.black.cgColor // Stroke color is not visible due to masking
                progressLayer.lineWidth = 14
                progressLayer.lineCap = .round
                
                // Configure image sizes
                milestonesImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
                milestonesImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
                resetImageView.heightAnchor.constraint(equalToConstant: 24).isActive = true
                resetImageView.widthAnchor.constraint(equalToConstant: 24).isActive = true
            }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
                let padding: CGFloat = 20
                let circleSize = min(bounds.width - padding * 2, bounds.height * 0.5)
                
                // Layout top labels
                titleLabel.frame = CGRect(x: 0, y: padding,
                                          width: bounds.width,
                                          height: 30)
                
                subtitleLabel.frame = CGRect(x: padding, y: titleLabel.frame.maxY + 8,
                                             width: bounds.width - padding * 2,
                                             height: 40)
                
                // Layout circle container
                let circleY = subtitleLabel.frame.maxY + padding
                circleContainer.frame = CGRect(x: (bounds.width - circleSize) / 2,
                                               y: circleY,
                                               width: circleSize,
                                               height: circleSize)
                
                // Create circular path
                let radius = circleSize / 2 - progressLayer.lineWidth / 2
                let circleCenter = CGPoint(x: circleSize / 2, y: circleSize / 2)
                let startAngle = -CGFloat.pi / 2
                let endAngle = startAngle + 2 * CGFloat.pi
                
                let circularPath = UIBezierPath(arcCenter: circleCenter,
                                                radius: radius,
                                                startAngle: startAngle,
                                                endAngle: endAngle,
                                                clockwise: true)
                
                backgroundLayer.path = circularPath.cgPath
                progressLayer.path = circularPath.cgPath
                
                // Configure gradient layer frame
                gradientLayer.frame = circleContainer.bounds
                
                // Position inner stack view in the center of the circle
                let innerStackSize = CGSize(width: circleSize * 0.7, height: 60)
                innerStackView.frame = CGRect(x: (circleSize - innerStackSize.width) / 2,
                                              y: (circleSize - innerStackSize.height) / 2,
                                              width: innerStackSize.width,
                                              height: innerStackSize.height)
                
                // Position bottom stack view just below the circle
                let centerX = bounds.width / 2
                let bottomStackSize = CGSize(width: 120, height: 60) // Fixed width for the stack
                bottomStackView.frame = CGRect(
                    x: centerX - (bottomStackSize.width / 2),
                    y: circleContainer.frame.maxY + 20,
                    width: bottomStackSize.width,
                    height: bottomStackSize.height
                )
            }

    
    // MARK: - Public Methods
    func setProgress(_ progress: Float, withNumber number: Int) {
            daysNumberLabel.text = "\(number)"
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = progress
            animation.duration = 1
            progressLayer.add(animation, forKey: "progressAnimation")
            
            progressLayer.strokeEnd = CGFloat(progress)
        }
        
        func setTitle(_ title: String, subtitle: String) {
            titleLabel.text = title
            subtitleLabel.text = subtitle
        }
    }
