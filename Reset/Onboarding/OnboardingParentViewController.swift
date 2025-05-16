import UIKit

class OnboardingParentViewController: UIPageViewController {
    
    private let onboardingData = [
        ("Reset", "Your digital sobriety companion", "onboarding1", ""),
        ("Track your progress", "See how your journey is going", "track", ""),
        ("Reset", "Restart your journey anytime", "reseton", ""),
        ("Create your support group", "Share your journey get advice", "support", "Get Started")
    ]
    
    private lazy var pages: [OnboardingViewController] = {
        return onboardingData.enumerated().map { index, data in
            let vc = OnboardingViewController(
                title: data.0,
                subTitle: data.1,
                image: data.2,
                buttonTitle: index == onboardingData.count - 1 ? "Get Started" : ""
            )
            vc.pageIndex = index
            vc.delegate = self
            return vc
        }
    }()
    
    private lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.numberOfPages = onboardingData.count
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .black
        pageControl.pageIndicatorTintColor = .gray
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()
    
    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        dataSource = self
        delegate = self
        
        if let firstPage = pages.first {
            setViewControllers([firstPage], direction: .forward, animated: true)
        }
        
        view.addSubview(pageControl)
        view.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    @objc private func skipTapped() {
        finishOnboarding()
    }
    
    private func finishOnboarding() {
        let loginViewController = LoginController()
        let navigationController = UINavigationController(rootViewController: loginViewController)
        UIApplication.shared.windows.first?.rootViewController = navigationController
        UIApplication.shared.windows.first?.makeKeyAndVisible()
        UserDefaults.standard.set(true, forKey: "enteredLoginFlow")
    }
    
    func goToNextPage() {
        guard let currentVC = viewControllers?.first as? OnboardingViewController,
              currentVC.pageIndex < pages.count - 1 else {
            finishOnboarding()
            return
        }
        
        let nextVC = pages[currentVC.pageIndex + 1]
        setViewControllers([nextVC], direction: .forward, animated: true)
        pageControl.currentPage = currentVC.pageIndex + 1
    }
}

// MARK: - UIPageViewControllerDataSource
extension OnboardingParentViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? OnboardingViewController,
              currentVC.pageIndex > 0 else {
            return nil
        }
        return pages[currentVC.pageIndex - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? OnboardingViewController,
              currentVC.pageIndex < pages.count - 1 else {
            return nil
        }
        return pages[currentVC.pageIndex + 1]
    }
}

// MARK: - UIPageViewControllerDelegate
extension OnboardingParentViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed,
              let currentVC = pageViewController.viewControllers?.first as? OnboardingViewController else {
            return
        }
        pageControl.currentPage = currentVC.pageIndex
    }
}

// MARK: - OnboardingViewControllerDelegate
extension OnboardingParentViewController: OnboardingViewControllerDelegate {
    func didTapNextButton(at index: Int) {
        if index == pages.count - 1 {
            finishOnboarding()
        } else {
            goToNextPage()
        }
    }
}
