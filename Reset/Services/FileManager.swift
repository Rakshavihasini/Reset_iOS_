import UIKit

class FileManagerHelper {
    
    static let fileManager = FileManager.default
    static let directory: URL = {
        // Get the URL for the app's Documents directory
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent("PostImages")
    }()
    
    // Ensure the directory exists
    static func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
    }
    
    // Save image to disk
    static func saveImageToDisk(_ image: UIImage) -> String? {
        createDirectoryIfNeeded()
        
        // Generate a unique file name
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = directory.appendingPathComponent(fileName)
        
        // Convert image to data
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            do {
                try imageData.write(to: fileURL)
                return fileURL.path // Return the path of the saved image
            } catch {
                print("Error saving image: \(error)")
            }
        }
        return nil
    }
    
    // Load image from disk
    static func loadImageFromDisk(imagePath: String) -> UIImage? {
        let fileURL = URL(fileURLWithPath: imagePath)
        
        if let imageData = try? Data(contentsOf: fileURL) {
            return UIImage(data: imageData)
        }
        return nil
    }
}
