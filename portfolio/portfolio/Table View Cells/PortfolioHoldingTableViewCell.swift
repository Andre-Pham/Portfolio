//
//  PortfolioHoldingTableViewCell.swift
//  portfolio
//
//  Created by Andre Pham on 20/4/21.
//

import UIKit

class PortfolioHoldingTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tickerLabel: UILabel!
    @IBOutlet weak var sharesLabel: UILabel!
    @IBOutlet weak var returnInDollarsAndPercentage: UILabel!
    @IBOutlet weak var equityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
