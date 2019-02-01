//
//  NewsTableVC.swift
//  StocksApp
//
//  Created by Екатерина on 27.01.2019.
//  Copyright © 2019 Wineapp. All rights reserved.
//

import UIKit

struct News: Decodable {
    let datetime: String
    let headline: String
    let url: String
}

class NewsTableVC: UITableViewController {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var companyName : String?
    var companyNews : [News] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.hidesWhenStopped = true
        self.activityIndicator.center = self.tableView.center
        
        self.requestCompanyNews()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.companyNews.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "newsIdentifier", for: indexPath)
        let news = self.companyNews[indexPath.row]
        
        cell.textLabel?.text = news.headline
        cell.detailTextLabel?.text = news.datetime.cropDate()

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let url =  self.companyNews[indexPath.row].url
        UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
        self.tableView.deselectRow(at: indexPath, animated: true)
    }

    
    // MARK: - Private methods
    
    private func requestCompanyNews() {
        self.activityIndicator.startAnimating()
        
        let url = URL(string: "https://api.iextrading.com/1.0/stock/\(self.companyName!)/news/last/10")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
                else {
                    self.showErrorAlert(title: "Network error", message: "Please, check your internet connection", completion: self.requestCompanyNews)
                    return
            }
            
            self.parseNewsList(data: data)
        }
        
        dataTask.resume()
    }
    
    private func parseNewsList(data: Data) {
        do {
            self.companyNews = try JSONDecoder().decode([News].self, from: data)
            print(String(decoding: data, as: UTF8.self))
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.tableView.reloadData()
                self.tableView.tableFooterView = UIView()
            }
        } catch {
            print(error.localizedDescription)
            self.showErrorAlert(title: "Error", message: "Something went wrong. Please, try again later.", completion: self.requestCompanyNews)
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

extension String {
    func cropDate() -> String {
        let isoDateFormatter = ISO8601DateFormatter()
        let date = isoDateFormatter.date(from: self)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
        return dateFormatter.string(from: date!)
    }
}
