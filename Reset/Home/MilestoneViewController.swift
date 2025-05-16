//
//  ViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/01/25.
//


//
//  ViewController.swift
//  Reset
//
//  Created by Prasanjit Panda on 27/11/24.
//

import UIKit



class MilestoneViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var days: Int = 0

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var daysToMilestoneLabel: UILabel!
    @IBOutlet weak var headerMedalIcon: UIImageView!
    
    var currentLeague: String = "Bronze"
    
    let milestones: [(title: String, days: String, iconName: String)] = [
            (title: "Bronze", days: "30 Days Sober", iconName: "medal.fill"),
            (title: "Silver", days: "60 Days Sober", iconName: "medal.fill"),
            (title: "Gold", days: "100 Days Sober", iconName: "medal.fill"),
            (title: "Crystal", days: "150 Days Sober", iconName: "medal.fill"),
            (title: "Ruby", days: "250 Days Sober", iconName: "medal.fill"),
            (title: "Emerald", days: "500 Days Sober", iconName: "medal.fill")
            
        ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        configureHeaderMedalIcon()
        
        daysToMilestoneLabel.text = "\(30 - days) days to next milestone"
        
        // Do any additional setup after loading the view.
    }
    
    func configureHeaderMedalIcon() {
            // Set the medal icon
            headerMedalIcon.image = UIImage(systemName: "medal.fill")?.withRenderingMode(.alwaysTemplate)
            
            // Set the color based on the current league
            switch currentLeague {
            case "Bronze":
                headerMedalIcon.tintColor = UIColor(red: 198/255, green: 145/255, blue: 85/255, alpha: 1) // Richer bronze icon
            case "Silver":
                headerMedalIcon.tintColor = UIColor(red: 192/255, green: 192/255, blue: 192/255, alpha: 1) // Silver color
            case "Gold":
                headerMedalIcon.tintColor = UIColor(red: 255/255, green: 215/255, blue: 0/255, alpha: 1) // Gold color
            case "Crystal":
                headerMedalIcon.tintColor = UIColor(red: 204/255, green: 153/255, blue: 255/255, alpha: 1) // Light purple
            case "Ruby":
                headerMedalIcon.tintColor = UIColor(red: 255/255, green: 55/255, blue: 11/255, alpha: 1)  // Ruby Red
            case "Emerald":
                headerMedalIcon.tintColor = UIColor(red: 80/255, green: 200/255, blue: 120/255, alpha: 1) // Emerald Green
            default:
                headerMedalIcon.tintColor = .systemGray // Fallback color
            }
        
        }
    
    
    
    
    
    
    
    
    @objc func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return milestones.count
        }
        
    @objc(collectionView:cellForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Dequeue the MilestoneCell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MilestoneCell", for: indexPath) as! MilestoneCell
        
        // Access the Milestone object at the current index
        let milestone = milestones[indexPath.row]
        
        // Configure the cell using the milestone data
        cell.configure(title: milestone.title, days: milestone.days, iconName: milestone.iconName)
        
        // Return the configured cell
        return cell
        }

}

extension MilestoneViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40
        return CGSize(width: width, height: 100) // Increased height
    }
        
        // Vertical spacing between cells
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 16 // Adjust this value for more/less spacing
        }
        
        // Section padding
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        }
    
    
    
        
   
    
    // This method sets the size for each item in the collection view
    
    
    // This method sets the minimum spacing between rows
    
    }
    
    // This method sets the minimum spacing between items in the same row
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0 // No spacing between items in the same row
    }
    
    // This method sets the section insets (padding around the section)
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20) // Padding around the section
    }
