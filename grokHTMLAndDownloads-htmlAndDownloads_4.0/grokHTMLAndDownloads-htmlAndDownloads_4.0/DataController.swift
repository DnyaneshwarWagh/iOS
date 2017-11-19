//
//  DataController.swift
//  grokHTMLAndDownloads
//
//  Created by Christina Moulton on 2015-10-12.
//  Copyright © 2015 Teak Mobile Inc. All rights reserved.
//

import Foundation
import Alamofire
import HTMLReader

let URLString = "http://charts.noaa.gov/BookletChart/AtlanticCoastBookletCharts.htm"

class DataController {
  var charts: [Chart]?
    
  private func isChartsTable(tableElement: HTMLElement) -> Bool {
    if tableElement.children.count > 0 {
        let firstChild = tableElement.child(at: 0)
        let lowerCaseContent = firstChild.textContent.lowercased()
      if lowerCaseContent.contains("number") && lowerCaseContent.contains("scale") && lowerCaseContent.contains("title") {
        return true
      }
    }
    return false
  }
  
  private func parseHTMLRow(rowElement: HTMLElement) -> Chart? {
    var url: NSURL?
    var number: Int?
    var scale: Int?
    var title: String?
    // first column: URL and number
    if let firstColumn = rowElement.child(at: 1) as? HTMLElement {
      // skip the first row, or any other where the first row doesn't contain a number
        if let urlNode = firstColumn.firstNode(matchingSelector: "a") {
            
        if let urlString = urlNode["href"] {
          url = NSURL(string: urlString)
        }
        // need to make sure it's a number
        
        let textNumber = firstColumn.textContent.trimmingCharacters(in: .whitespacesAndNewlines)

        number = Int(textNumber)
      }
    }
    if (url == nil || number == nil) {
      return nil // can't do anything without a URL, e.g., the header row
    }
    
    if let secondColumn = rowElement.child(at: 3) as? HTMLElement {
        
        let text = secondColumn.textContent.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
        
      scale = Int(text)
    }
    // third column: Name
    if let thirdColumn = rowElement.child(at: 5) as? HTMLElement {
        title = thirdColumn.textContent.trimmingCharacters(in: .newlines).replacingOccurrences(of: "\n", with: "")
    }
    
    if let title = title, let url = url, let number = number, let scale = scale {
      return Chart(title: title, url: url, number: number, scale: scale)
    }
    return nil
  }
  
    func fetchCharts(completionHandler: @escaping (Error?) -> Void) {
    Alamofire.request(URLString, method: .get)
    //Alamofire.request(.GET, URLString)
      .responseString { responseString in
        guard responseString.result.error == nil else {
            completionHandler(responseString.result.error! as Error)
          return

        }
        guard let htmlAsString = responseString.result.value else {
          let error = AFError.responseSerializationFailed(reason: AFError.ResponseSerializationFailureReason.stringSerializationFailed(encoding: .utf8)) //Error.errorWithCode(.StringSerializationFailed, failureReason: "Could not get HTML as String")
            completionHandler(error)
          return
        }
        // TODO checks from Alamofire page, bubble up errors
        let doc = HTMLDocument(string: htmlAsString)
        
        // find the table of charts in the HTML
        let tables = doc.nodes(matchingSelector: "tbody")
        var chartsTable:HTMLElement?
        for table in tables {
            if self.isChartsTable(tableElement: table) {
            chartsTable = table
            break
          }
        }
        // make sure we found the table of charts
        guard let tableContents = chartsTable else {
          // TODO: create error
          let error = AFError.responseSerializationFailed(reason: AFError.ResponseSerializationFailureReason.stringSerializationFailed(encoding: .utf8)) //Error.errorWithCode(.DataSerializationFailed, failureReason: "Could not find charts table in HTML document")
            completionHandler(error)
          return
        }
        
        self.charts = []
        for row in tableContents.children {
          if let rowElement = row as? HTMLElement { // TODO: should be able to combine this with loop above
            if let newChart = self.parseHTMLRow(rowElement: rowElement) {
              self.charts?.append(newChart)
            }
          }
        }
        completionHandler(nil)
      }
  }
  
  func isChartDownloaded(chart: Chart) -> Bool {
    if let path = chart.urlInDocumentsDirectory?.path {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path)
    }
    return false
  }
  
    func downloadChart(chart: Chart, completionHandler: @escaping (Double?, Error?) -> Void) {
    guard isChartDownloaded(chart: chart) == false else {
      completionHandler(1.0, nil) // already have it
      return
    }
    
    
    
    let destination = DownloadRequest.suggestedDownloadDestination(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask) //Alamofire.Request.suggestedDownloadDestination(for: .documentDirectory, in: .userDomainMask)
    
        Alamofire.download(chart.url as URL, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil, to: destination)
    .downloadProgress(queue: DispatchQueue.global(qos: .utility)) { progress in
        print("Progress: \(progress.fractionCompleted)")
        completionHandler(progress.fractionCompleted, nil)
    }
    .responseString { (response) in
            print(response.result.error)
            completionHandler(nil, response.result.error)
        }
  }
}
