//
//  alpaca.swift
//  FirstApp
//
//  Created by Matthew Yeager on 7/24/25.
//

import Foundation


import SwiftUI

class AlpacaAPI: ObservableObject {
    @Published var portfolioValue: Double?
    @Published var latestPrice: Double?
    @Published var positions: [Position] = []

    private let apiKey = "enter your api"
    private let apiSecret = "enter your api"
    private let paperBaseURL = "https://paper-api.alpaca.markets"
    private let dataBaseURL = "https://data.alpaca.markets"

    func fetchAccountValue() {
        guard let url = URL(string: "\(paperBaseURL)/v2/account") else { return }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let valueString = json["portfolio_value"] as? String,
                  let value = Double(valueString) else { return }

            DispatchQueue.main.async {
                self.portfolioValue = value  // you can rename this var to portfolioValue for clarity
            }
        }.resume()
    }
        
    
    struct Position: Identifiable, Codable {
        let id = UUID()
        let symbol: String
        let qty: String
        let marketValue: String
        let currentPrice: String
        let avgEntryPrice: String
        
        enum CodingKeys: String, CodingKey {
            case symbol, qty
            case marketValue = "market_value"
            case avgEntryPrice = "avg_entry_price"
            case currentPrice = "current_price"
        }
    }
        
        func fetchPositions() {
                guard let url = URL(string: "\(paperBaseURL)/v2/positions") else { return }
                var request = URLRequest(url: url)
                request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
                request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")

                URLSession.shared.dataTask(with: request) { data, _, _ in
                    guard let data = data else { return }
                    do {
                        let decoder = JSONDecoder()
                        let positionsResponse = try decoder.decode([Position].self, from: data)
                        DispatchQueue.main.async {
                            self.positions = positionsResponse
                        }
                    } catch {
                        print("Failed to decode positions: \(error)")
                    }
                }.resume()
            }

    func placeOrder(ticker: String, qty: String, side: String) {
        guard let url = URL(string: "\(paperBaseURL)/v2/orders") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "APCA-API-KEY-ID")
        request.setValue(apiSecret, forHTTPHeaderField: "APCA-API-SECRET-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let orderData: [String: Any] = [
            "symbol": ticker,
            "qty": qty,
            "side": side,
            "type": "market",
            "time_in_force": "gtc"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: orderData, options: [])
        } catch {
            print("Failed to encode order: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Order failed: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Order response code: \(httpResponse.statusCode)")
            }

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) {
                print("Order response: \(json)")
            }
        }.resume()
    }
    
}
