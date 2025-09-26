import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct MarketDemo {
    static func main() async {
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        let sdk = SdkClient(baseUrl: BASE_URL, apiKey: API_TOKEN)

        do {
            Log.section("GetAvailableMarkets")
            let (markets, _) = try await Log.measure("GetAvailableMarkets") {
                try await sdk.market.getAvailable()
            }
            Log.json(markets, label: "Response (GetAvailableMarkets)")

            Log.section("Summary")
            Log.info("Total markets: \(markets.count)")
            if let first = markets.first {
                let data = try JSONEncoder().encode(first)
                if let str = String(data: data, encoding: .utf8) {
                    Log.info("First market sample:\n\(str)")
                }
            }

            Log.section("Done")
            Log.success("Market demo finished successfully.")

        } catch {
            Log.section("Error")
            if let e = error as? SdkException {
                Log.error(e.description)
            } else {
                Log.error(error.localizedDescription)
            }
        }
    }
}
