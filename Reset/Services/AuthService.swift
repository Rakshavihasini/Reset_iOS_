//
//  AuthService.swift
//  Reset
//
//  Created by Prasanjit Panda on 04/01/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import WidgetKit

class AuthService {
    
    let userPosts:[Post] = []
    public static let shared = AuthService()
    
    private init() {}

    public func registerUser(with userRequest: RegiserUserRequest, completion: @escaping (Bool, Error?)->Void) {
        let username = userRequest.username
        let email = userRequest.email
        let password = userRequest.password
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let resultUser = result?.user else {
                completion(false, nil)
                return
            }
            
            let currentTimestamp = Timestamp(date: Date())
            
            let db = Firestore.firestore()
            db.collection("users")
                .document(resultUser.uid)
                .setData([
                    "username": username,
                    "email": email,
                    "soberSince": currentTimestamp,
                    "dateOfRegistration": currentTimestamp,
                    "soberStreak": 0,
                    "numberOfResets": 0,
                    "imageURL": "https://firebasestorage.googleapis.com/v0/b/ios-projects-f25c0.firebasestorage.app/o/images%2Fdefault-user-img.png?alt=media&token=b2234c5f-086b-4041-a6f6-efbd0b1106e0",
                    "averageSpend": 0,
                    "drinksPerWeek":0
                ]) { error in
                    if let error = error {
                        completion(false, error)
                        return
                    }
                    
                    completion(true, nil)
                }
        }
    }
    
    
    
    public func signIn(with userRequest: LoginUserRequest, completion: @escaping (Error?)->Void) {
        Auth.auth().signIn(
            withEmail: userRequest.email,
            password: userRequest.password
        ) { result, error in
            if let error = error {
                completion(error)
                return
            } else {
                // Get the ID token after successful sign-in
                result?.user.getIDToken { token, tokenError in
                    if let token = token {
                        print("Firebase ID Token: \(token)")
                        // You can store this token somewhere if needed
                        // UserDefaults.standard.set(token, forKey: "firebaseIdToken")
                    } else if let tokenError = tokenError {
                        print("Error fetching token: \(tokenError.localizedDescription)")
                    }
                    
                    // Still complete the original sign-in process
                    completion(nil)
                }
            }
        }
    }
    
    public func signOut(completion: @escaping (Error?)->Void) {
        do {
            // Clear all UserDefaults data
            clearAllUserDefaults()
            
            // Sign out from Firebase
            try Auth.auth().signOut()
            completion(nil)
        } catch let error {
            completion(error)
        }
    }
    
    // Helper method to clear all UserDefaults data
    private func clearAllUserDefaults() {
        // Clear standard UserDefaults
        let standardDefaults = UserDefaults.standard
        if let bundleID = Bundle.main.bundleIdentifier {
            standardDefaults.removePersistentDomain(forName: bundleID)
        }
        standardDefaults.synchronize()
        
        // Clear shared UserDefaults for widget
        if let sharedDefaults = UserDefaults(suiteName: "group.com.reset.urges") {
            sharedDefaults.removeObject(forKey: "urgeTimestamps")
            sharedDefaults.removeObject(forKey: "lastSynced")
            sharedDefaults.synchronize()
            
            // Refresh widget to reflect the cleared data
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        print("All UserDefaults data cleared")
    }
    
    public func forgotPassword(with email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            completion(error)
        }
    }
    
    public func fetchUser(completion: @escaping (User?, Error?) -> Void) {
        
        print("Fetching User")
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users")
            .document(userUID)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists,
                      let snapshotData = snapshot.data() else {
                    completion(nil, NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid or missing user data"]))
                    return
                }
                
                // Print the snapshot data for debugging
//                print("Snapshot Data: \(snapshotData)")
                
                // Proceed with the rest of the code
                guard let username = snapshotData["username"] as? String,
                      let imageURL = snapshotData["imageURL"] as? String,
                      let dateOfRegistrationTimestamp = snapshotData["dateOfRegistration"] as? Timestamp,
                      let soberSinceTimestamp = snapshotData["soberSince"] as? Timestamp,
                      let numberOfResets = snapshotData["numberOfResets"] as? Double,
                      let soberStreak = snapshotData["soberStreak"] as? Double,
                      let averageSpend = snapshotData["averageSpend"] as? Double,
                      let drinksPerWeek = snapshotData["drinksPerWeek"] as? Double,
                      let email = snapshotData["email"] as? String else {
                    completion(nil, NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid or missing user data"]))
                    return
                }
                
                // Convert Timestamps to Dates
                let dateOfRegistration = dateOfRegistrationTimestamp.dateValue()
                let soberSince = soberSinceTimestamp.dateValue()
                
                // Create the User object
                let user = User(username: username,
                                email: email,
                                userUID: userUID,
                                imageURL: imageURL,
                                dateOfRegistration: dateOfRegistration,
                                soberSince: soberSince,
                                numberOfResets: numberOfResets,
                                soberStreak: soberStreak,
                                averageSpend: averageSpend,
                                drinksPerWeek: drinksPerWeek)
                print("AUTH SERVICE \n \(user)")
                completion(user, nil)
            }
    }

    
    public func fetchUserByID(userID: String, completion: @escaping (User?, Error?) -> Void) {
        let db = Firestore.firestore()
        
        db.collection("users").document(userID).getDocument { snapshot, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists,
                  let snapshotData = snapshot.data(),
                  let username = snapshotData["username"] as? String,
                  let imageURL = snapshotData["imageURL"] as? String,
                  let dateOfRegistrationTimestamp = snapshotData["dateOfRegistration"] as? Timestamp,
                  let soberSinceTimestamp = snapshotData["soberSince"] as? Timestamp,
                  let numberOfResets = snapshotData["numberOfResets"] as? Double,
                  let soberStreak = snapshotData["soberStreak"] as? Double,
                  let averageSpend = snapshotData["averageSpend"] as? Double,
                  let drinksPerWeek = snapshotData["drinksPerWeek"] as? Double,
                  let email = snapshotData["email"] as? String else {
                completion(nil, NSError(domain: "DataError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid or missing user data user by ID"]))
                return
            }
            
            // Convert Timestamps to Dates
            let dateOfRegistration = dateOfRegistrationTimestamp.dateValue()
            let soberSince = soberSinceTimestamp.dateValue()
            
            // Create the User object
            let user = User(username: username,
                            email: email,
                            userUID: userID,
                            imageURL: imageURL,
                            dateOfRegistration: dateOfRegistration,
                            soberSince: soberSince,
                            numberOfResets: numberOfResets,
                            soberStreak: soberStreak,
                            averageSpend: averageSpend,
                            drinksPerWeek: drinksPerWeek)
            
            completion(user, nil)
        }
    }

    

    // Fetch posts by user ID
    public func fetchPostsByUserID(userID: String, completion: @escaping (Result<[Post], Error>) -> Void) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        
        db.collection("posts")
            .whereField("userID", isEqualTo: userID)  // Query posts by userID
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))  // Return the error
                    return
                }
                
                var posts: [Post] = []  // Array to hold the fetched posts
                let group = DispatchGroup() // Group to handle async image fetching
                
                for document in querySnapshot!.documents {
                    let data = document.data()
//                    print("Post data:", data)
                    
                    guard let postID = document.documentID as String?,
                          let userID = data["userID"] as? String,
                          let caption = data["caption"] as? String,
                          let likeCount = data["likes"] as? Int,
                          let commentCount = data["comments"] as? Int,
                          let imageUrl = data["imageUrl"] as? String,
                          let profileImageUrl = data["profileImageUrl"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        continue // Skip if any required field is missing
                    }
                    
                    // Default placeholders
                    let defaultProfileImage = UIImage(systemName: "person.circle")!
                    let defaultPostImage = UIImage(systemName: "photo")!
                    
                    // Initialize post with placeholders
                    var post = Post(
                        postID: postID,
                        userID: userID,
                        profileImage: defaultProfileImage,
                        username: "Unknown User", // Placeholder for username
                        image: defaultPostImage,
                        likeCount: likeCount,
                        commentCount: commentCount,
                        caption: caption,
                        timestamp: timestamp.dateValue()
                    )
                    
                    // Fetch profile image
                    group.enter()
                    self.fetchImage(from: profileImageUrl, storage: storage) { result in
                        if case .success(let image) = result {
                            post.profileImage = image
                        }
                        group.leave()
                    }
                    
                    // Fetch post image
                    group.enter()
                    self.fetchImage(from: imageUrl, storage: storage) { result in
                        if case .success(let image) = result {
                            post.image = image
                        }
                        group.leave()
                    }
                    
                    // After all async tasks for this post are done, append it to the array
                    group.enter()  // Track completion of this post's processing
                    group.notify(queue: .main) {  // This block will run after profile & post images are fetched
                        posts.append(post)
                        group.leave()  // Mark this post's processing as complete
                    }
                }
                
                // Wait for all posts and their image fetches to complete
                group.notify(queue: .main) {
//                    print("Final posts array:", posts)
                    completion(.success(posts))
                }
            }
    }


    // Helper function to fetch an image from a Firebase Storage URL
    public func fetchImage(from url: String, storage: Storage, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let storageRef = storage.reference(forURL: url)
        storageRef.getData(maxSize: 2 * 1024 * 1024) { data, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            if let data = data, let image = UIImage(data: data) {
                print("image fetch successful")
                completion(.success(image))
            } else {
                completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: nil)))
            }
        }
    }
    




}

extension AuthService {

    // Update averageSpend field in Firestore
    public func updateAverageSpend(to value: Double, completion: @escaping (Error?) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userUID)
            .updateData(["averageSpend": value]) { error in
                completion(error)
            }
    }

    // Update drinksPerWeek field in Firestore
    public func updateDrinksPerWeek(to value: Int, completion: @escaping (Error?) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userUID)
            .updateData(["drinksPerWeek": value]) { error in
                completion(error)
            }
    }

    // Update soberSince field in Firestore
    public func updateSoberSince(to date: Date, completion: @escaping (Error?) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userUID)
            .updateData(["soberSince": date]) { error in
                completion(error)
            }
    }

    // Update numberOfResets field in Firestore
    public func updateNumberOfResets(to value: Int, completion: @escaping (Error?) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userUID)
            .updateData(["numberOfResets": value]) { error in
                completion(error)
            }
    }

    // Update soberStreak field in Firestore
    public func updateSoberStreak(to value: Int, completion: @escaping (Error?) -> Void) {
        guard let userUID = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"]))
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userUID)
            .updateData(["soberStreak": value]) { error in
                completion(error)
            }
    }
}

