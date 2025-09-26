import Foundation
import ReachuCore
import ReachuDemoKit

@main
struct ProductDemo {
    static func main() async {
        let API_TOKEN = "THVXN06-MGB4D4P-KCPRCKP-RHGT6VJ"
        let BASE_URL = URL(string: "https://graph-ql-dev.reachu.io/graphql")!

        let CURRENCY = "NOK"
        let COUNTRY = "NO"
        let IMAGE_SZ = "large"

        let PRODUCT_ID: Int = 402517

        let sdk = SdkClient(baseUrl: BASE_URL, apiKey: API_TOKEN)
        let products = ProductRepositoryGQL(client: sdk.apolloClient)
        let categoriesRepo = ChannelCategoryRepositoryGQL(client: sdk.apolloClient)

        do {
            Log.section("Product.getByParams (by productId)")
            let (one, _) = try await Log.measure("Product.getByParams") {
                try await products.getByParams(
                    currency: CURRENCY,
                    imageSize: IMAGE_SZ,
                    sku: nil,
                    barcode: nil,
                    productId: PRODUCT_ID,
                    shippingCountryCode: COUNTRY
                )
            }
            Log.json(one, label: "Response (Product.getByParams)")

            var foundSKU: String? = nil
            var foundBarcode: String? = nil
            do {
                let data = try JSONEncoder().encode(one)
                if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    foundSKU = dict["sku"] as? String
                    foundBarcode = dict["barcode"] as? String
                }
            } catch {}

            if let sku = foundSKU, !sku.trimmingCharacters(in: .whitespaces).isEmpty {
                Log.section("Product.getBySkus (by sku)")
                let (bySku, _) = try await Log.measure("Product.getBySkus") {
                    try await products.getBySkus(
                        sku: sku,
                        productId: nil,
                        currency: CURRENCY,
                        imageSize: IMAGE_SZ,
                        shippingCountryCode: COUNTRY
                    )
                }
                Log.json(bySku, label: "Response (Product.getBySkus)")
            } else {
                Log.section("Product.getBySkus (skipped)")
                Log.warn("No SKU found on product \(PRODUCT_ID).")
            }

            if let barcode = foundBarcode, !barcode.trimmingCharacters(in: .whitespaces).isEmpty {
                Log.section("Product.getByBarcodes (by barcode)")
                let (byBarcode, _) = try await Log.measure("Product.getByBarcodes") {
                    try await products.getByBarcodes(
                        barcode: barcode,
                        productId: nil,
                        currency: CURRENCY,
                        imageSize: IMAGE_SZ,
                        shippingCountryCode: COUNTRY
                    )
                }
                Log.json(byBarcode, label: "Response (Product.getByBarcodes)")
            } else {
                Log.section("Product.getByBarcodes (skipped)")
                Log.warn("No barcode found on product \(PRODUCT_ID).")
            }

            Log.section("Product.getByIds")
            let (byIds, _) = try await Log.measure("Product.getByIds") {
                try await products.getByIds(
                    productIds: [PRODUCT_ID],
                    currency: CURRENCY,
                    imageSize: IMAGE_SZ,
                    useCache: true,
                    shippingCountryCode: COUNTRY
                )
            }
            Log.json(byIds, label: "Response (Product.getByIds)")

            Log.section("Product.get (filtered, using productIds)")
            let (generic, _) = try await Log.measure("Product.get") {
                try await products.get(
                    currency: CURRENCY,
                    imageSize: IMAGE_SZ,
                    barcodeList: nil,
                    categoryIds: nil,
                    productIds: [PRODUCT_ID],
                    skuList: nil,
                    useCache: true,
                    shippingCountryCode: COUNTRY
                )
            }
            Log.json(generic, label: "Response (Product.get)")

            let (cats, _) = try await Log.measure("Category.get") {
                try await categoriesRepo.get()
            }

            if let firstCat = cats.first {
                var catId: Int? = nil
                do {
                    let data = try JSONEncoder().encode(firstCat)
                    if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        catId = (dict["id"] as? Int) ?? (dict["category_id"] as? Int)
                    }
                } catch { /* ignore */  }

                if let categoryId = catId, categoryId > 0 {
                    Log.section("Product.getByCategoryId (\(categoryId))")
                    let (byCat, _) = try await Log.measure("Product.getByCategoryId") {
                        try await products.getByCategoryId(
                            categoryId: categoryId,
                            currency: CURRENCY,
                            imageSize: IMAGE_SZ,
                            shippingCountryCode: COUNTRY
                        )
                    }
                    Log.json(byCat, label: "Response (Product.getByCategoryId)")

                    let catIds: [Int] = cats.prefix(3).compactMap {
                        if let d = try? JSONSerialization.jsonObject(
                            with: JSONEncoder().encode($0)
                        ) as? [String: Any] {
                            return (d["id"] as? Int) ?? (d["category_id"] as? Int)
                        }
                        return nil
                    }
                    if !catIds.isEmpty {
                        Log.section("Product.getByCategoryIds \(catIds)")
                        let (byCats, _) = try await Log.measure("Product.getByCategoryIds") {
                            try await products.getByCategoryIds(
                                categoryIds: catIds,
                                currency: CURRENCY,
                                imageSize: IMAGE_SZ,
                                shippingCountryCode: COUNTRY
                            )
                        }
                        Log.json(byCats, label: "Response (Product.getByCategoryIds)")
                    } else {
                        Log.section("Product.getByCategoryIds (skipped)")
                        Log.warn("No valid category ids extracted.")
                    }
                } else {
                    Log.section("Product.getByCategoryId (skipped)")
                    Log.warn("Could not extract a categoryId from first category.")
                }
            } else {
                Log.section("Category.get (empty)")
                Log.warn("No categories returned.")
            }

            Log.section("Done")
            Log.success("Product demo finished successfully.")

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
