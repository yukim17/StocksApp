//
//  ViewController.swift
//  StocksApp
//
//  Created by Екатерина on 26.01.2019.
//  Copyright © 2019 Wineapp. All rights reserved.
//

import UIKit

class StockInfoVC: UIViewController {
    
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var symbolLable: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var companyName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.requestQuoteUpdate()
        
    }
    
    //MARK: - Private Methods
    
    private func requestQuote(for symbol: String) {
        let url = URL(string: "https://api.iextrading.com/1.0/stock/\(symbol)/quote")!
        let imageUrl = URL(string: "https://storage.googleapis.com/iex/api/logos/\(symbol).png")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                self.showErrorAlert(title: "Network error", message: "Please, check your internet connection", completion: self.requestQuoteUpdate)
                return
            }
            self.parseQuote(data: data)
        }
        
        let imageTask = URLSession.shared.dataTask(with: imageUrl) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
                else {
                    self.showErrorAlert(title: "Network error", message: "Please, check your internet connection", completion: self.requestQuoteUpdate)
                    return
            }
            
            DispatchQueue.main.async {
                self.companyLogo.image = UIImage(data: data)
            }
        }
        
        dataTask.resume()
        imageTask.resume()
    }
    
    private func parseQuote(data : Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String : Any],
                let companyName = json["companyName"] as? String,
                let symbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
                print("Invalid json format")
                return
            }
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName,
                                      symbol: symbol,
                                      price: price,
                                      priceChange: priceChange)
            }
        } catch {
            self.showErrorAlert(title: "Error", message: "Something went wrong. Please, try again later.", completion: self.requestQuoteUpdate)
        }
    }
    
    
    private func displayStockInfo(companyName : String, symbol : String, price : Double, priceChange : Double) {
        self.activityIndicator.stopAnimating()
        self.companyNameLabel.text = companyName
        self.symbolLable.text = symbol
        self.priceLabel.text = "\(price) $"
        self.priceChangeLabel.text = "\(priceChange) $"
        
        if priceChange > 0 {
            self.priceChangeLabel.textColor = UIColor.green
        } else if priceChange < 0 {
            self.priceChangeLabel.textColor = UIColor.red
        } else {
            self.priceChangeLabel.textColor = UIColor.black
        }
    }
    
    private func requestQuoteUpdate() {
        self.activityIndicator.startAnimating()
        self.companyNameLabel.text = "-"
        self.symbolLable.text = "-"
        self.priceLabel.text = "-"
        self.priceChangeLabel.text = "-"
        self.priceChangeLabel.textColor = UIColor.black
        self.companyLogo.image = nil
        
        self.requestQuote(for: self.companyName!)
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
