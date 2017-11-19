//
//  MasterViewController.swift
//  grokHTMLAndDownloads
//
//  Created by Christina Moulton on 2015-10-12.
//  Copyright © 2015 Teak Mobile Inc. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, UIDocumentInteractionControllerDelegate {
    var dataController = DataController()
    var docController: UIDocumentInteractionController?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dataController.fetchCharts { _ in
            // TODO: handle errors
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return dataController.charts?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let chartCell = cell as? ChartCell {
            if let chart = dataController.charts?[indexPath.row] {
                chartCell.titleLabel.text = "\(chart.number): \(chart.title)"
                
                if self.dataController.isChartDownloaded(chart: chart) {
                    // show disclosure indicator if we already have it
                    chartCell.accessoryType = .checkmark
                }
            }
        }
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        if let chart = dataController.charts?[indexPath.row] {
            dataController.downloadChart(chart: chart) { progress, error in
                // TODO: handle error
                print(progress)
                print(error)
                
                DispatchQueue.main.async {
                    
                    if(progress ?? 0 < 1.0)
                    {
                        if let cell = self.tableView.cellForRow(at: indexPath), let chartCell = cell as? ChartCell, let progressValue = progress {
                            chartCell.progressBar.isHidden = false
                            chartCell.progressBar.progress = Float(progressValue)
                            chartCell.setNeedsDisplay()
                        }
                    }
                    
                    if (progress == 1.0) {
                        if let filename = chart.filename {
                            let paths   = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                            let docs    = paths[0]
                            let pathURL = NSURL(fileURLWithPath: docs, isDirectory: true)
                            let fileURL = NSURL(fileURLWithPath: filename, isDirectory: false, relativeTo: pathURL as URL)
                            
                            self.docController = UIDocumentInteractionController(url: fileURL as URL)
                            self.docController?.delegate = self
                            if let cell = self.tableView.cellForRow(at: indexPath) {
                                self.docController?.presentOptionsMenu(from: cell.frame, in: self.tableView, animated: true)
                                
                                if let chartCell = cell as? ChartCell {
                                    chartCell.progressBar.isHidden = true
                                    chartCell.progressBar.progress = 0
                                    chartCell.accessoryType = .checkmark
                                    chartCell.setNeedsDisplay()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UIDocumentInteractionControllerDelegate
    func documentInteractionController(controller: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
        self.docController   = nil
        if let indexPath    = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated:true)
        }
    }
    
    
}

