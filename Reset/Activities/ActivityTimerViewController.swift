//
//  ActivityTimerViewController.swift
//  Reset
//
//  Created by System on Date.
//

import UIKit
import CoreText

class ActivityTimerViewController: UIViewController {
    
    // MARK: - Properties
    private let activity: Activity
    private let duration: Int // in minutes
    private var timer: Timer?
    private var timeRemaining: Int
    private var isTimerRunning = false
    
    // MARK: - UI Components
    private let circularProgressView: ActivityTimerProgressView = {
        let view = ActivityTimerProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = .monospacedDigitalFont(ofSize: 48, weight: .medium)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemBrown
        button.tintColor = .white
        button.layer.cornerRadius = 12
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        button.tintColor = .systemGray
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Initialization
    init(activity: Activity, duration: Int) {
        self.activity = activity
        self.duration = duration
        self.timeRemaining = duration * 60 // Convert to seconds
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(circularProgressView)
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(timeLabel)
        view.addSubview(actionButton)
        view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            circularProgressView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circularProgressView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            circularProgressView.widthAnchor.constraint(equalToConstant: 280),
            circularProgressView.heightAnchor.constraint(equalToConstant: 280),
            
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: titleLabel.topAnchor, constant: -20),
            iconImageView.widthAnchor.constraint(equalToConstant: 60),
            iconImageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: circularProgressView.topAnchor, constant: -20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            timeLabel.centerXAnchor.constraint(equalTo: circularProgressView.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: circularProgressView.centerYAnchor),
            
            actionButton.topAnchor.constraint(equalTo: circularProgressView.bottomAnchor, constant: 40),
            actionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            actionButton.widthAnchor.constraint(equalToConstant: 200),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            
            cancelButton.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 16),
            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        // Configure initial state
        iconImageView.image = activity.icon
        iconImageView.tintColor = activity.uiColor
        titleLabel.text = activity.title
        actionButton.setTitle("Start", for: .normal)
        updateTimeLabel()
    }
    
    private func updateUI() {
        let progress = Float(timeRemaining) / Float(duration * 60)
        circularProgressView.setProgress(progress, animated: true)
        updateTimeLabel()
        
        actionButton.setTitle(isTimerRunning ? "Pause" : "Start", for: .normal)
    }
    
    private func updateTimeLabel() {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
        isTimerRunning = true
        updateUI()
    }
    
    private func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        updateUI()
    }
    
    private func timerTick() {
        guard timeRemaining > 0 else {
            timerComplete()
            return
        }
        
        timeRemaining -= 1
        updateUI()
    }
    
    private func timerComplete() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        
        // Show completion alert
        let alert = UIAlertController(title: "Activity Complete! 🎉",
                                    message: "Great job completing your \(activity.title.lowercased()) session!",
                                    preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Done", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func actionButtonTapped() {
        if isTimerRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    @objc private func cancelButtonTapped() {
        let alert = UIAlertController(title: "Cancel Activity",
                                    message: "Are you sure you want to cancel this activity?",
                                    preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Yes, Cancel", style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        }
        
        let continueAction = UIAlertAction(title: "Continue Activity", style: .cancel)
        
        alert.addAction(cancelAction)
        alert.addAction(continueAction)
        
        present(alert, animated: true)
    }
}

// MARK: - ActivityTimerProgressView
class ActivityTimerProgressView: UIView {
    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        // Create track layer (background circle)
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = 15
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        layer.addSublayer(trackLayer)
        
        // Create progress layer
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineWidth = 15
        progressLayer.strokeColor = UIColor.systemBrown.cgColor
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 1.0
        layer.addSublayer(progressLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - progressLayer.lineWidth
        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi
        
        let circularPath = UIBezierPath(arcCenter: center,
                                      radius: radius,
                                      startAngle: startAngle,
                                      endAngle: endAngle,
                                      clockwise: true)
        
        trackLayer.path = circularPath.cgPath
        progressLayer.path = circularPath.cgPath
    }
    
    func setProgress(_ progress: Float, animated: Bool = true) {
        let timing = animated ? CAMediaTimingFunction(name: .easeInEaseOut) : nil
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.timingFunction = timing
        animation.duration = animated ? 0.2 : 0
        animation.fromValue = progressLayer.presentation()?.strokeEnd ?? progressLayer.strokeEnd
        animation.toValue = CGFloat(progress)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        progressLayer.add(animation, forKey: "progressAnimation")
        progressLayer.strokeEnd = CGFloat(progress)
    }
}

// MARK: - Font Extension
extension UIFont {
    static func monospacedDigitalFont(ofSize size: CGFloat, weight: Weight) -> UIFont {
        return UIFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
} 