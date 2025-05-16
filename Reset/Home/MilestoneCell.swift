//
//  MilestoneCell.swift
//  Reset
//
//  Created by Prasanjit Panda on 08/01/25.
//


//
//  MilestoneCell.swift
//  Reset
//
//  Created by Raksha on 04/01/25.
//

import UIKit



class MilestoneCell: UICollectionViewCell {
    
    @IBOutlet weak var badgeIconLabel: UIImageView!
    
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var daysLabel: UILabel!
    
    

       
    override func layoutSubviews() {
       super.layoutSubviews()
       layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: 20).cgPath
    }
    override func awakeFromNib() {
           super.awakeFromNib()
        setupCardAppearance()
        
        
                
           
       }
    
    private func setupCardAppearance() {
        // Setup cell appearance
        backgroundColor = .clear // Important for shadow visibility
        contentView.layer.cornerRadius = 25
        contentView.layer.masksToBounds = true
        
        // Add shadow to the cell's layer
        layer.cornerRadius = 25
        layer.shadowColor = UIColor.systemGray5.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 8
        layer.masksToBounds = false
        
        // Add subtle border for better depth perception
        contentView.layer.borderWidth = 0.2
        contentView.layer.borderColor = UIColor.systemGray5.cgColor
        
        // Optimize shadow rendering
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
    }
    
    
           
   
    
    
    func configure(title: String, days: String, iconName: String) {
        titleLabel.text = title
        daysLabel.text = days
        badgeIconLabel.image = UIImage(systemName: "medal.fill")?.withRenderingMode(.alwaysTemplate)
        
        
        // Assign colors based on the title
        switch title {
        case "Bronze":
            contentView.backgroundColor = UIColor(red: 190/255, green: 100/255, blue: 40/255, alpha: 0.2) // Darker bronze background
            badgeIconLabel.tintColor = UIColor(red: 198/255, green: 145/255, blue: 85/255, alpha: 1) // Richer bronze icon
        case "Silver":
            contentView.backgroundColor = UIColor(red: 140/255, green: 140/255, blue: 140/255, alpha: 0.2) // Darker silver background
            badgeIconLabel.tintColor = UIColor(red: 149/255, green: 149/255, blue: 149/255, alpha: 1) // Richer silver icon
        case "Gold":
            contentView.backgroundColor = UIColor(red: 195/255, green: 155/255, blue: 0/255, alpha: 0.2) // Darker gold background
            badgeIconLabel.tintColor = UIColor(red: 235/255, green: 193/255, blue: 45/255, alpha: 1) // Shiny gold icon
        case "Crystal":
            contentView.backgroundColor = UIColor(red: 160/255, green: 110/255, blue: 195/255, alpha: 0.2) // Darker crystal background
            badgeIconLabel.tintColor = UIColor(red: 184/255, green: 133/255, blue: 235/255, alpha: 1) // Richer crystal icon
        case "Ruby":
            contentView.backgroundColor = UIColor(red: 195/255, green: 35/255, blue: 5/255, alpha: 0.2) // Darker ruby background
            badgeIconLabel.tintColor = UIColor(red: 235/255, green: 45/255, blue: 5/255, alpha: 1) // Richer ruby icon
        case "Emerald":
            contentView.backgroundColor = UIColor(red: 50/255, green: 140/255, blue: 70/255, alpha: 0.2) // Darker emerald background
            badgeIconLabel.tintColor = UIColor(red: 60/255, green: 180/255, blue: 100/255, alpha: 1) // Richer emerald icon
        default:
            contentView.backgroundColor = .systemBackground
            badgeIconLabel.tintColor = .systemGray
        }

    }
    
}