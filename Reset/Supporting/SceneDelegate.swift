//
//  SceneDelegate.swift
//  Reset
//
//  Created by Prasanjit Panda on 03/01/25.
//
import UIKit
import Firebase
import FirebaseAuth
import BackgroundTasks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        setupWindow(with: scene)
        checkAuthentication()
    }
    
    private func setupWindow(with scene: UIScene) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
    }
    
    public func checkAuthentication() {
        if Auth.auth().currentUser == nil {
            // No authenticated user
            if UserDefaults.standard.bool(forKey: "enteredLoginFlow") {
                // User previously entered login flow but didn't complete it
                // Send directly to login screen
                let loginViewController = LoginController()
                let nav = UINavigationController(rootViewController: loginViewController)
                window?.rootViewController = nav
            } else {
                // First time or properly exited user - show full onboarding
                let viewController = OnboardingParentViewController()
                let nav = UINavigationController(rootViewController: viewController)
                window?.rootViewController = nav
            }
        } else {
            // User is authenticated, show main app
            let vc = createTabBarController()
            window?.rootViewController = vc
        }
        window?.makeKeyAndVisible()
    }
    
    private func goToController(with viewController: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            let nav = UINavigationController(rootViewController: viewController)
            nav.modalPresentationStyle = .fullScreen
            self?.window?.rootViewController = nav
        }
    }
    
    private func goToControllerTab(with viewController: UIViewController) {
        DispatchQueue.main.async { [weak self] in
            self?.window?.rootViewController = viewController
        }
    }
    
    func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()
        
        // TestViewController
        let testVC = TestViewController()
        testVC.tabBarItem = UITabBarItem(title: "Home",
                                        image: UIImage(systemName: "house.fill"),
                                        tag: 0)

        // Activities View Controller
        let activitiesVC = ActivitiesViewController()
        activitiesVC.tabBarItem = UITabBarItem(title: "Activities",
                                              image: UIImage(systemName: "brain.head.profile"),
                                              tag: 1)
        
        // Community/Spaces View Controller
        let spaceVC = SBSpaceViewController()
        spaceVC.tabBarItem = UITabBarItem(title: "Spaces",
                                         image: UIImage(systemName: "person.3.fill"),
                                         tag: 2)
        
        // Chat View Controller
        let chatVC = ChatListViewController()
        chatVC.tabBarItem = UITabBarItem(title: "Messages",
                                        image: UIImage(systemName: "bubble.fill"),
                                        tag: 3)

        // Set view controllers
        tabBarController.viewControllers = [
            testVC,
            activitiesVC,
            spaceVC,
            UINavigationController(rootViewController: chatVC)
        ]

        // Customize TabBar appearance
        if let tabBar = tabBarController.tabBar as? UITabBar {
            tabBar.tintColor = UIColor.systemBrown
            tabBar.unselectedItemTintColor = UIColor.gray
            tabBar.backgroundColor = UIColor.systemGroupedBackground
        }

        // Set selected item text color
        if let items = tabBarController.tabBar.items {
            let selectedAttributes = [NSAttributedString.Key.foregroundColor: UIColor.systemBrown]
            for item in items {
                item.setTitleTextAttributes(selectedAttributes, for: .selected)
            }
        }

        return tabBarController
    }

    // MARK: - UISceneSession Lifecycle
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        checkAuthentication()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}

