import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct CategoryDemo {
    static func main() async {
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        let sdk = SdkClient(baseUrl: BASE_URL, apiKey: API_TOKEN)

        let categoriesRepo = ChannelCategoryRepositoryGQL(client: sdk.apolloClient)

        do {
            Log.section("Category.get")
            let (cats, _) = try await Log.measure("Category.get") {
                try await categoriesRepo.get()
            }
            Log.json(cats, label: "Response (Category.get)")

            Log.section("Summary")
            Log.info("Total categories: \(cats.count)")
            if let first = cats.first, let data = try? JSONEncoder().encode(first),
                let str = String(data: data, encoding: .utf8)
            {
                Log.info("First category sample:\n\(str)")
            }

            Log.section("Done")
            Log.success("Category demo finished successfully.")

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
