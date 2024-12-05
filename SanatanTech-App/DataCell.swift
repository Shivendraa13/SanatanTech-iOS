//
//  DataCell.swift
//  SanatanTech-App
//
//  Created by Preyash on 05/12/24.
//

import UIKit

class DataCell: UITableViewCell {

    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var stepCountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
