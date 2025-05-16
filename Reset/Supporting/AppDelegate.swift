//
//  AppDelegate.swift
//  Reset
//
//  Created by Prasanjit Panda on 03/01/25.
//

import UIKit
import FirebaseCore
import SendbirdChatSDK
import SendbirdUIKit
import FirebaseAuth
import FirebaseFirestore
import BackgroundTasks
import WidgetKit
import FirebaseMessaging
import UserNotifications
import FirebaseAnalytics
import SendBirdCalls
import Alamofire

@main
class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        if #available(iOS 18.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]){
                granted, error in
                print("Permission Granted")
            }
            UNUserNotificationCenter.current().delegate = self
            
        } else {
            // For iOS versions less than 18.0
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]){
                granted, error in
                print("Permission granted: \(granted)")
                if let error = error {
                    print("Permission error: \(error.localizedDescription)")
                }
            }
            UNUserNotificationCenter.current().delegate = self
        }
        application.registerForRemoteNotifications()
        
        let APP_ID = "C8740F48-E4F1-43A3-B601-FB513F1DD89F"
        
        
        // Initialize SendbirdUI
        SendbirdUI.initialize(applicationId: APP_ID) { error in
            if let error = error {
                print("Sendbird UI initialization failed: \(error.localizedDescription)")
            } else {
                print("SENDBIRD UI INITIALIZED SUCCESSFULLY")
            }
        }
        
        // Initialize SendbirdCalls
        SendBirdCall.configure(appId: APP_ID)
        print("SENDBIRD CALLS CONFIGURED")
        
        // Only perform authenticated operations if a user is logged in
        if Auth.auth().currentUser != nil {
            // Setup the user after all SDKs are initialized
            setupSendbirdUser()
            syncUrgesWithFirebase()
            updateSoberStreak()
        } else {
            print("No user logged in. Skipping authenticated operations.")
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([[.banner,.list,.sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void){
        let userInfo = response.notification.request.content.userInfo
        NotificationCenter.default.post(name: NSNotification.Name("PushNotification"), object: nil,userInfo: userInfo)
        completionHandler()
    }
    
    func updateSoberStreak() {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No logged-in user. Cannot update sober streak.")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error)")
                return
            }
            
            guard let document = document, document.exists else {
                print("User document does not exist.")
                return
            }
            
            guard let soberSinceTimestamp = document.data()?["soberSince"] as? Timestamp else {
                print("soberSince field is missing or invalid.")
                return
            }
            
            let soberSinceDate = soberSinceTimestamp.dateValue()
            let soberStreak = self.calculateStreak(soberSinceDate: soberSinceDate)
            
            // Update the streak in Firebase and in the app
            userRef.updateData(["soberStreak": soberStreak]) { error in
                if let error = error {
                    print("Error updating soberStreak: \(error)")
                } else {
                    print("Sober streak updated successfully: \(soberStreak)")
                }
            }
        }
    }

    // Helper function to calculate the streak
    func calculateStreak(soberSinceDate: Date) -> Int {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfSoberDate = calendar.startOfDay(for: soberSinceDate)
        
        let components = calendar.dateComponents([.day], from: startOfSoberDate, to: startOfToday)
        return components.day ?? 0
    }
    @objc func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase TOKEN: \(String(describing: fcmToken))")
        
        guard let token = fcmToken else { return }
        guard let currentUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let userId = currentUser.uid
        
        // Save the token to Firestore
        db.collection("users").document(userId).setData([
            "fcmToken": token,
            "lastTokenUpdate": FieldValue.serverTimestamp()
        ], merge: true) { error in
            if let error = error {
                print("Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token successfully saved to Firestore")
            }
        }
        
        // Save token locally if needed
        UserDefaults.standard.set(token, forKey: "fcmToken")
    }
    
    private func setupSendbirdUser() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user.")
            return
        }

        let userID = currentUser.uid
        let db = Firestore.firestore()

        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch user data: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("User document does not exist or has no data.")
                return
            }
            
            // Safely extract user data with fallbacks
            if let username = data["username"] as? String,
               let imageUrl = data["imageURL"] as? String {
                self.checkSendbirdUserExists(userId: userID, nickname: username, profileUrl: imageUrl)
            } else {
                print("Required user data missing. Cannot setup Sendbird user.")
            }
        }
    }

    private func createSendbirdUser(userId: String, nickname: String, profileUrl: String) {
        let sendbirdApiToken = "2d6d337efdf18e783c85626b4ef477d517fd6b72" // Securely store this!
        let sendbirdAppId = "C8740F48-E4F1-43A3-B601-FB513F1DD89F"
        let url = "https://api-\(sendbirdAppId).sendbird.com/v3/users/\(userId)"

        let parameters: [String: Any] = [
            "user_id": userId,
            "nickname": nickname,
            "profile_url": profileUrl,
            "issue_access_token": true
        ]

        let headers: HTTPHeaders = [
            "Api-Token": sendbirdApiToken,
            "Content-Type": "application/json"
        ]

        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any],
                   let accessToken = json["access_token"] as? String {
                    print("Sendbird user created successfully. Access token: \(accessToken)")
                    self.storeAccessTokenInFirestore(userId: userId, accessToken: accessToken)
                    self.setupSendbirdCall(sendbirdAccessToken: accessToken, userID: userId)
                    let sendbirdUser = SBUUser(userId: userId, nickname: nickname, profileURL: profileUrl)
                    SBUGlobals.currentUser = sendbirdUser
                    print("Sendbird user set: \(userId) with nickname: \(nickname)")

                } else {
                    print("Failed to parse Sendbird API response.")
                    if let data = response.data, let string = String(data: data, encoding: .utf8) {
                        print("Response Data: \(string)")
                    }
                }
            case .failure(let error):
                print("Sendbird API request failed: \(error.localizedDescription)")
                if let data = response.data, let string = String(data: data, encoding: .utf8) {
                    print("Response Data: \(string)")
                }
            }
        }
    }
    
    private func checkSendbirdUserExists(userId: String, nickname: String, profileUrl: String) {
        let sendbirdApiToken = "2d6d337efdf18e783c85626b4ef477d517fd6b72" // Securely store this!
        let sendbirdAppId = "C8740F48-E4F1-43A3-B601-FB513F1DD89F"
        let url = "https://api-\(sendbirdAppId).sendbird.com/v3/users/\(userId)"

        let headers: HTTPHeaders = [
            "Api-Token": sendbirdApiToken,
            "Content-Type": "application/json"
        ]

        AF.request(url, method: .get, headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                if let json = value as? [String: Any], json["user_id"] as? String == userId {
                    // User already exists in Sendbird, just authenticate
                    self.fetchSendbirdAccessToken(userId: userId, nickname: nickname, profileUrl: profileUrl)
                } else {
                    // User does not exist, create the user
                    self.createSendbirdUser(userId: userId, nickname: nickname, profileUrl: profileUrl)
                }
            case .failure(let error):
                if let statusCode = response.response?.statusCode, statusCode == 400002 {
                    // User does not exist, create the user
                    self.createSendbirdUser(userId: userId, nickname: nickname, profileUrl: profileUrl)
                } else {
                    print("Sendbird API request failed: \(error.localizedDescription)")
                    if let data = response.data, let string = String(data: data, encoding: .utf8) {
                        print("Response Data: \(string)")
                    }
                }
            }
        }
    }

    private func fetchSendbirdAccessToken(userId: String, nickname: String, profileUrl: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Failed to fetch Sendbird access token from Firestore: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data(), let sendbirdAccessToken = data["sendbirdAccessToken"] as? String else {
                print(snapshot?.data()!)
                print("Sendbird access token not found in Firestore.")
                return
            }

            self.setupSendbirdCall(sendbirdAccessToken: sendbirdAccessToken, userID: userId)
            let sendbirdUser = SBUUser(userId: userId, nickname: nickname, profileURL: profileUrl)
            SBUGlobals.currentUser = sendbirdUser
            print("Sendbird user set: \(userId) with nickname: \(nickname)")
        }
    }

    private func storeAccessTokenInFirestore(userId: String, accessToken: String) {
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData(["sendbirdAccessToken": accessToken]) { error in
            if let error = error {
                print("Failed to store Sendbird access token in Firestore: \(error.localizedDescription)")
            } else {
                print("Sendbird access token stored in Firestore.")
            }
        }
    }

    private func setupSendbirdCall(sendbirdAccessToken: String, userID: String){
        let params = AuthenticateParams(userId: userID, accessToken: sendbirdAccessToken)
        SendBirdCall.authenticate(with: params) { (user, error) in
            guard let user = user, error == nil else {
                print("Sendbird Call authentication failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            print("Sendbird Call authenticated successfully.")
            // ... proceed with Sendbird Call setup
        }
    }
    
    
    
    func syncUrgesWithFirebase() {
        guard let currentUser = Auth.auth().currentUser else {
            print("No logged-in user. Cannot sync urges.")
            return
        }
        
        let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges")
        guard let sharedDefaults = sharedDefaults else {
            print("Could not access shared UserDefaults. Cannot sync urges.")
            return
        }
        
        let timestamps = sharedDefaults.array(forKey: "urgeTimestamps") as? [Date] ?? []

        guard !timestamps.isEmpty else {
            print("No new urges to sync")
            return
        }

        let db = Firestore.firestore()
        let userId = currentUser.uid
        let urgesRef = db.collection("users").document(userId).collection("urges")

        let batch = db.batch()
        for timestamp in timestamps {
            let docRef = urgesRef.document("\(timestamp.timeIntervalSince1970)")
            batch.setData([
                "timestamp": Timestamp(date: timestamp),
                "reason": "",  // Initially empty reason
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: docRef, merge: true) // Use `merge: true` in case reason is updated later
        }

        batch.commit { error in
            if let error = error {
                print("Error syncing urges: \(error.localizedDescription)")
            } else {
                print("Urges synced successfully!")

                // Set the last synced timestamp before clearing data
                sharedDefaults.set(Date(), forKey: "lastSynced")
                sharedDefaults.synchronize()

                // Notify Widget to refresh with the last synced timestamp
                WidgetCenter.shared.reloadAllTimelines()

                // Clear the data after a longer delay to ensure widget has time to read it
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    sharedDefaults.removeObject(forKey: "urgeTimestamps")
                    sharedDefaults.synchronize()
                }
            }
        }
    }
    
    


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

