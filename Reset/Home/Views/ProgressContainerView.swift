import UIKit
import SwiftUI

// SwiftUI Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let days: Int
    
    // Animation state
    @State private var animatedProgress: Double = 0
    
    // Gradient colors
    private let gradientColors = [
        Color(red: 0.8, green: 0.5, blue: 0.2), // Original orange
        Color(red: 0.9, green: 0.6, blue: 0.2)  // Lighter orange
    ]
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    Color(white: 1),
                    lineWidth: 15
                )
            
            // Progress circle with gradient and shadow
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: 15,
                        lineCap: .round
                    )
                )
                .shadow(color: Color(red: 0.8, green: 0.5, blue: 0.2, opacity: 0.5), radius: 5, x: 0, y: 0)
                .rotationEffect(.degrees(-90))
            
            // Center text
            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(Color(red: 0.8, green: 0.5, blue: 0.2))
                Text("days Sober")
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray)
            }
        }
        .frame(width: 200, height: 200)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { newProgress in
            withAnimation(.easeOut(duration: 1.0)) {
                animatedProgress = newProgress
            }
        }
    }
}

// UIKit Container View
class ProgressContainerView: UIView {
    var progressHostingController: UIHostingController<CircularProgressView>!
    let titleLabel = UILabel()
    let milestoneLabel = UILabel()
    private let buttonsStack = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        self.isUserInteractionEnabled = true
    }
    
    private func setupView() {
        // View setup
        backgroundColor = UIColor(red: 0.98, green: 0.94, blue: 0.90, alpha: 1.0)
        layer.cornerRadius = 25
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 10
        
        // Title
        titleLabel.text = "Bronze league"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        // Milestone text
        milestoneLabel.text = "You are 25 days away from the next milestone"
        milestoneLabel.font = .systemFont(ofSize: 18)
        milestoneLabel.textColor = .darkGray
        milestoneLabel.textAlignment = .center
        milestoneLabel.numberOfLines = 0
        milestoneLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(milestoneLabel)
        
        // Progress View
        let progressView = CircularProgressView(progress: 0, days: 0)
        progressHostingController = UIHostingController(rootView: progressView)
        progressHostingController.view.backgroundColor = .clear
        progressHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(progressHostingController.view)
        
        // Buttons Stack
        buttonsStack.axis = .horizontal
        buttonsStack.distribution = .equalSpacing
        buttonsStack.alignment = .center
        buttonsStack.spacing = 100
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttonsStack)
        
        // Milestone Button
        let milestoneButton = createButton(
            image: UIImage(systemName: "medal.fill"),
            title: "Milestones",
            action: #selector(handleMilestoneButton)
        )
        
        // Reset Button
        let resetButton = createButton(
            image: UIImage(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90"),
            title: "Reset",
            action: #selector(handleResetButton)
        )
        
        buttonsStack.addArrangedSubview(milestoneButton)
        buttonsStack.addArrangedSubview(resetButton)
        
        setupConstraints()
    }
    
    @objc private func handleMilestoneButton() {
       print("MILESTONE")
    }
    
    @objc private func handleResetButton() {
        print("RESET")
    }
    
    private func createButton(image: UIImage?, title: String, action: Selector) -> UIView {
        let container = UIView()
        container.isUserInteractionEnabled = true
        
        let button = UIButton()
        button.setImage(image, for: .normal)
        button.tintColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)
        button.backgroundColor = .white
        button.layer.cornerRadius = 20
        button.isUserInteractionEnabled = true
        button.widthAnchor.constraint(equalToConstant: 40).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        button.addTarget(self, action: action, for: .touchUpInside)
        
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.textAlignment = .center
        
        container.addSubview(button)
        container.addSubview(label)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            label.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 8),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            milestoneLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            milestoneLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            milestoneLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            
            progressHostingController.view.topAnchor.constraint(equalTo: milestoneLabel.bottomAnchor, constant: 20),
            progressHostingController.view.centerXAnchor.constraint(equalTo: centerXAnchor),
            progressHostingController.view.widthAnchor.constraint(equalToConstant: 200),
            progressHostingController.view.heightAnchor.constraint(equalToConstant: 200),
            
            buttonsStack.topAnchor.constraint(equalTo: progressHostingController.view.bottomAnchor, constant: 30),
            buttonsStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            buttonsStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    func updateProgress(_ days: Int, totalDays: Int) {
        let progress = Double(days) / Double(totalDays)
        progressHostingController.rootView = CircularProgressView(progress: progress, days: days)
    }
}
