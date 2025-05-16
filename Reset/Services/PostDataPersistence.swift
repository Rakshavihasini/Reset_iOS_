////
////  PostDataPersistence.swift
////  Reset
////
////  Created by Prasanjit Panda on 15/12/24.
////
//
//import Foundation
//import UIKit
//
//class PostDataPersistence {
//    private let postsKey = "mockPostsKey"
//    
//    static let shared = PostDataPersistence()
//    private init() {}
//    
//    func savePosts(_ posts: [Post]) {
//        let encoder = JSONEncoder()
//        if let encodedPosts = try? encoder.encode(posts) {
//            UserDefaults.standard.set(encodedPosts, forKey: postsKey)
//        }
//    }
//    
//    func loadPosts() -> [Post] {
//        let decoder = JSONDecoder()
//        if let savedData = UserDefaults.standard.data(forKey: postsKey),
//           let decodedPosts = try? decoder.decode([Post].self, from: savedData) {
//            return decodedPosts
//        }
//        return [] // Return an empty array if no data is found
//    }
//    
//    // Save an image to disk and return the file path
//    func saveImageToDisk(_ image: UIImage) -> String? {
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return nil }
//        let fileName = UUID().uuidString + ".jpg"
//        let filePath = getDocumentsDirectory().appendingPathComponent(fileName)
//        try? imageData.write(to: filePath)
//        return filePath.path
//    }
//    
//    // Load an image from disk
//    func loadImageFromDisk(_ filePath: String) -> UIImage? {
//        let fileURL = URL(fileURLWithPath: filePath)
//        return UIImage(contentsOfFile: fileURL.path)
//    }
//    
//    // Get the app's documents directory
//    private func getDocumentsDirectory() -> URL {
//        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//    }
//    
//    func addComment(toPostWithID postID: UUID, comment: Comment) {
//            var posts = loadPosts()
//            if let index = posts.firstIndex(where: { $0.id == postID }) {
//                posts[index].comments.append(comment)
//                posts[index].commentsCount += 1
//                savePosts(posts)
//            }
//    }
//}
