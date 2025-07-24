import SwiftUI

struct ContentView: View {
    @StateObject private var api = AlpacaAPI()
    @State private var orderTicker: String = ""
    @State private var orderQty: String = "1"
    @State private var orderSide: String = "buy" // or "sell"

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("📈 Your Portfolio")
                    .font(.largeTitle)
                    .bold()

                VStack(spacing: 10) {
                    Text("💰 Account Value")
                        .font(.headline)

                    if let value = api.portfolioValue {
                        Text("$\(String(format: "%.2f", value))")
                            .font(.title)
                            .bold()
                    } else {
                        ProgressView("Loading account value...")
                    }
                }

                Divider()

                Text(" Trade")
                    .font(.headline)

                TextField("Enter ticker", text: $orderTicker)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)

                TextField("Quantity", text: $orderQty)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack(spacing: 20) {
                    Button(action: {
                        orderSide = "buy"
                        api.placeOrder(ticker: orderTicker.uppercased(), qty: orderQty, side: orderSide)
                    }) {
                        Label("Buy", systemImage: "arrow.up.circle.fill")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        orderSide = "sell"
                        api.placeOrder(ticker: orderTicker.uppercased(), qty: orderQty, side: orderSide)
                    }) {
                        Label("Sell", systemImage: "arrow.down.circle.fill")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }

                Text("📋 Positions")
                    .font(.headline)

                if api.positions.isEmpty {
                    Text("No open positions")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(api.positions) { position in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(position.symbol)
                                .font(.headline)
                            HStack {
                                Text("Qty: \(position.qty)")
                                Spacer()
                                Text("Avg Price: $\(position.avgEntryPrice)")
                                Spacer()
                                Text("Market Value: $\(position.marketValue)")
                                Text("Current Price: $\(position.currentPrice)")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer()

                Button(action: {
                    api.fetchAccountValue()
                    api.fetchPositions()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise.circle.fill")
                        Text("Refresh Data")
                            .bold()
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                api.fetchAccountValue()
                api.fetchPositions()
            }
            .navigationBarHidden(true)
        }
    }
}
