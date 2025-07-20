import SwiftUI

@main
struct StockPortfolioApp: App {
    var body: some Scene {
        WindowGroup {
            PortfolioView()
        }
    }
}

// MARK: - Model
struct Stock: Identifiable, Codable {
    var id: UUID = UUID()
    var symbol: String
    var shares: Double
    var purchasePrice: Double
}

// MARK: - ViewModel
class PortfolioViewModel: ObservableObject {
    @Published var stocks: [Stock] = [] {
        didSet { save() }
    }
    @Published var cashBalance: Double = 0 {
        didSet { save() }
    }

    var portfolioValue: Double {
        let stockValue = stocks.reduce(0) { $0 + ($1.shares * $1.purchasePrice) }
        return cashBalance + stockValue
    }

    init() {
        load()
    }

    func setStartingBalance(_ amount: Double) {
        if stocks.isEmpty {
            cashBalance = amount
        }
    }

    func addStock(symbol: String, shares: Double, price: Double) -> Bool {
        let cost = shares * price
        guard cost <= cashBalance else { return false }
        let stock = Stock(symbol: symbol.uppercased(), shares: shares, purchasePrice: price)
        stocks.append(stock)
        cashBalance -= cost
        return true
    }

    func sellStock(stock: Stock, sharesToSell: Double) {
        guard let index = stocks.firstIndex(where: { $0.id == stock.id }) else { return }
        let availableShares = stocks[index].shares
        let actualSharesToSell = min(availableShares, sharesToSell)
        let saleValue = actualSharesToSell * stocks[index].purchasePrice

        if actualSharesToSell >= stocks[index].shares {
            cashBalance += saleValue
            stocks.remove(at: index)
        } else {
            stocks[index].shares -= actualSharesToSell
            cashBalance += saleValue
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(stocks) {
            UserDefaults.standard.set(encoded, forKey: "portfolio")
        }
        UserDefaults.standard.set(cashBalance, forKey: "cashBalance")
    }

    func load() {
        if let saved = UserDefaults.standard.data(forKey: "portfolio"),
           let decoded = try? JSONDecoder().decode([Stock].self, from: saved) {
            stocks = decoded
        }
        if UserDefaults.standard.object(forKey: "cashBalance") != nil{
            cashBalance = UserDefaults.standard.double(forKey: "cashBalance")
        }
    }
}

// MARK: - View
struct PortfolioView: View {
    @StateObject private var viewModel = PortfolioViewModel()
    @State private var symbol = ""
    @State private var shares = ""
    @State private var purchasePrice = ""
    @State private var startingBalance = ""
    @State private var sellShares = ""
    @State private var alertMessage: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    Image("Logo")
                        .resizable()
                        .frame(width: 170, height: 60)
                        .padding()
                    
                    // Header
                    VStack(spacing: 5) {
                        Text("Portfolio Value: $\(viewModel.portfolioValue, specifier: "%.2f")")
                            .font(.title)
                            .bold()
                        Text("Cash: $\(viewModel.cashBalance, specifier: "%.2f")")
                            .foregroundColor(.secondary)
                    }

                    // Starting Balance
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Set Starting Balance")
                            .font(.headline)
                        HStack {
                            TextField("Amount", text: $startingBalance)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Set") {
                                if let amount = Double(startingBalance) {
                                    viewModel.setStartingBalance(amount)
                                    startingBalance = ""
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()

                    Divider()

                    // BUY SECTION
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Buy Stock")
                            .font(.headline)

                        TextField("Symbol (e.g., AAPL)", text: $symbol)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Shares", text: $shares)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Purchase Price", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Button(action: {
                            guard let sharesVal = Double(shares),
                                  let priceVal = Double(purchasePrice),
                                  !symbol.isEmpty else {
                                alertMessage = "Please enter all fields correctly."
                                return
                            }

                            let success = viewModel.addStock(symbol: symbol, shares: sharesVal, price: priceVal)
                            if success {
                                symbol = ""
                                shares = ""
                                purchasePrice = ""
                            } else {
                                alertMessage = "Not enough cash to complete purchase."
                            }
                        }) {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Buy")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding()

                    Divider()

                    // POSITIONS
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Stocks")
                            .font(.headline)

                        if viewModel.stocks.isEmpty {
                            Text("No holdings yet.")
                                .foregroundColor(.gray)
                        } else {
                            ForEach(viewModel.stocks) { stock in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(stock.symbol)
                                            .font(.headline)
                                        Spacer()
                                        Text("\(stock.shares, specifier: "%.2f") shares @ $\(stock.purchasePrice, specifier: "%.2f")")
                                    }

                                    HStack {
                                        TextField("Shares to sell", text: $sellShares)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .frame(width: 120)

                                        Button("Sell") {
                                            if let sellQty = Double(sellShares) {
                                                viewModel.sellStock(stock: stock, sharesToSell: sellQty)
                                                sellShares = ""
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 5)
                                        .background(Color.red)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()

                }
                .padding()
                .alert(item: $alertMessage) { message in
                    Alert(title: Text("Error"), message: Text(message), dismissButton: .default(Text("OK")))
                }
            }
            .navigationTitle("My Portfolio")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Enable string as Alert item
extension String: Identifiable {
    public var id: String { self }
}
