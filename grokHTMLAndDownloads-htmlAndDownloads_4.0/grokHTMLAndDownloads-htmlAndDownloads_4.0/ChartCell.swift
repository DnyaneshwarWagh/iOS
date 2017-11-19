//
//  ChartCell.swift
//  grokHTMLAndDownloads-htmlAndDownloads_4.0
//
//  Created by M4st3rZeus on 18/11/17.
//  Copyright © 2017 M4st3rZeus. All rights reserved.
//

import UIKit

class ChartCell: UITableViewCell {

    @IBOutlet weak var titleLabel   : UILabel!
    @IBOutlet weak var progressBar  : UIProgressView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        titleLabel.text         = ""
        progressBar.progress    = 0
        progressBar.isHidden    = true
        accessoryType           = .none
    }

}
