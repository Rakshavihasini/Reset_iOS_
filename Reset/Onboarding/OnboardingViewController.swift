//
//  OnboardingViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/01/25.
//

import UIKit

// MARK: - OnboardingViewControllerDelegate
protocol OnboardingViewControllerDelegate: AnyObject {
    func didTapNextButton(at index: Int)
}

class OnboardingViewController: UIViewController {
    
    let viewTitle: String
    private let viewSubTitle: String
    private let viewImage: String
    private let viewButtonTitle: String
    
    var pageIndex: Int = 0
    weak var delegate: OnboardingViewControllerDelegate?
    
    private lazy var onboardingView: OnboardingView = {
        let view = OnboardingView(
            title: viewTitle,
            subTitle: viewSubTitle,
            image: viewImage,
            buttonTitle: viewButtonTitle
        )
        return view
    }()
    
    init(title: String, subTitle: String, image: String, buttonTitle: String) {
        self.viewTitle = title
        self.viewSubTitle = subTitle
        self.viewImage = image
        self.viewButtonTitle = buttonTitle
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        setupButtonAction()
        
        // Hide button if not the last page
        onboardingView.button.isHidden = (pageIndex != 3)  // Assuming 5 pages total (0-4)
    }
    
    private func setupUI() {
        view.addSubview(onboardingView)
        onboardingView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            onboardingView.topAnchor.constraint(equalTo: view.topAnchor),
            onboardingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            onboardingView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            onboardingView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }
    
    private func setupButtonAction() {
        onboardingView.button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    @objc private func nextButtonTapped() {
        delegate?.didTapNextButton(at: pageIndex)
    }
}
