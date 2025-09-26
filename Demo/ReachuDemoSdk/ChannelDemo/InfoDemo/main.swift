import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct InfoDemo {
    static func main() async {
        // Hardcoded dev creds (adjust if needed)
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        // SDK
        let sdk = SdkClient(baseUrl: BASE_URL, apiKey: API_TOKEN)

        // Repository under test
        let info = ChannelInfoRepositoryGQL(client: sdk.apolloClient)

        do {
            // 1) Channels
            Log.section("Info.getChannels")
            let (channels, _) = try await Log.measure("Info.getChannels") {
                try await info.getChannels()
            }
            Log.json(channels, label: "Response (Info.getChannels)")

            // 2) Purchase Conditions
            Log.section("Info.getPurchaseConditions")
            let (purchaseCond, _) = try await Log.measure("Info.getPurchaseConditions") {
                try await info.getPurchaseConditions()
            }
            Log.json(purchaseCond, label: "Response (Info.getPurchaseConditions)")

            // 3) Terms & Conditions
            Log.section("Info.getTermsAndConditions")
            let (terms, _) = try await Log.measure("Info.getTermsAndConditions") {
                try await info.getTermsAndConditions()
            }
            Log.json(terms, label: "Response (Info.getTermsAndConditions)")

            Log.section("Done")
            Log.success("Channel info demo finished successfully.")
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
