//
//  CompaniesTableVC.swift
//  StocksApp
//
//  Created by Екатерина on 27.01.2019.
//  Copyright © 2019 Wineapp. All rights reserved.
//

import UIKit

struct Company: Decodable {
    let companyName: String
    let symbol: String
    let change: Double
}

class CompaniesTableVC: UITableViewController {

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var companyNames: [Company] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.center = self.tableView.center
        
        self.requestCompanyList()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.companyNames.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "companyIdentifier", for: indexPath)
        let company = self.companyNames[indexPath.row]
        let priceChange = company.change

        cell.textLabel?.text = company.companyName
        cell.detailTextLabel?.text = "\(priceChange) $"
        if priceChange > 0 {
            cell.detailTextLabel?.textColor = UIColor.green
        } else if priceChange < 0 {
            cell.detailTextLabel?.textColor = UIColor.red
        } else {
            cell.detailTextLabel?.textColor = UIColor.black
        }
        
        return cell
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "getStockInfo" {
            let tabVC = segue.destination as! UITabBarController
            let indexPath = self.tableView.indexPathForSelectedRow
            let company = self.companyNames[(indexPath?.row)!]
            for vc in tabVC.customizableViewControllers! {
                if let infoVC = vc as? StockInfoVC {
                    infoVC.companyName = company.symbol
                } else if let newsVC = vc as? NewsTableVC {
                    newsVC.companyName = company.symbol
                }
            }
        }
    }
    
    // MARK: - Private methods
    
    private func requestCompanyList() {
        self.activityIndicator.startAnimating()
        
        let url = URL(string: "https://api.iextrading.com/1.0/stock/market/list/infocus")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
                else {
                    self.showErrorAlert(title: "Network error", message: "Please, check your internet connection", completion: self.requestCompanyList)
                    return
            }
            
            self.parseCompanyList(data: data)
        }
        
        dataTask.resume()
    }
    
    private func parseCompanyList(data: Data) {
        do {
            self.companyNames = try JSONDecoder().decode([Company].self, from: data)
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
                self.tableView.tableFooterView = UIView()
            }
        } catch {
            self.showErrorAlert(title: "Error", message: "Something went wrong. Please, try again later.", completion: self.requestCompanyList)
        }
    }
    
    private func showErrorAlert(title: String, message: String, completion:@escaping ()->()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "Retry", style: .default) { _ in
            completion()
        }
        let cancelAction  = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(retryAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }

}
