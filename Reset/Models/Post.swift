//
//  Post.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/12/24.
//

import UIKit

// Post Model
struct Post {
    let postID: String        // Unique identifier for the post
    let userID: String        // ID of the user who created the post
    var profileImage: UIImage // Profile image of the user
    var username: String      // Username of the user
    var image: UIImage        // Image associated with the post
    var likeCount: Int        // Number of likes
    var commentCount: Int     // Number of comments
    let caption: String       // Caption for the post
    var isCaptionExpanded: Bool = false // Flag to check if caption is expanded
    let timestamp: Date       // Timestamp when the post was created
}

