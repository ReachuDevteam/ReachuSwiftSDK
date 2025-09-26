import Foundation

public final class ProductRepositoryGQL: ProductRepository {
    private let client: GraphQLHTTPClient
    public init(client: GraphQLHTTPClient) { self.client = client }

    private func requirePositiveIds(_ ids: [Int], _ field: String) throws {
        if ids.isEmpty {
            throw ValidationException("\(field) cannot be empty", details: ["field": field])
        }
        if ids.contains(where: { $0 <= 0 }) {
            throw ValidationException(
                "\(field) must contain positive IDs only", details: ["field": field])
        }
    }
    private func requireNonEmptyStrings(_ values: [String], _ field: String) throws {
        if values.contains(where: { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            throw ValidationException(
                "\(field) cannot contain empty strings", details: ["field": field])
        }
    }
    private func validateCommonFilters(
        currency: String?, imageSize: String?, shippingCountryCode: String?
    ) throws {
        if let c = currency { try Validation.requireCurrency(c) }
        if let s = shippingCountryCode { try Validation.requireCountry(s) }
        if let i = imageSize, i.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationException("imageSize cannot be empty", details: ["field": "imageSize"])
        }
    }

    public func get(
        currency: String?,
        imageSize: String? = "large",
        barcodeList: [String]?,
        categoryIds: [Int]?,
        productIds: [Int]?,
        skuList: [String]?,
        useCache: Bool = true,
        shippingCountryCode: String?
    ) async throws -> [ProductDto] {
        try validateCommonFilters(
            currency: currency, imageSize: imageSize, shippingCountryCode: shippingCountryCode)
        if let ids = categoryIds { try requirePositiveIds(ids, "categoryIds") }
        if let ids = productIds { try requirePositiveIds(ids, "productIds") }
        if let list = skuList { try requireNonEmptyStrings(list, "skuList") }
        if let list = barcodeList { try requireNonEmptyStrings(list, "barcodeList") }

        let vars: [String: Any] = [
            "currency": currency as Any,
            "imageSize": imageSize as Any,
            "barcodeList": barcodeList ?? [],
            "categoryIds": categoryIds ?? [],
            "productIds": productIds ?? [],
            "skuList": skuList ?? [],
            "useCache": useCache,
            "shippingCountryCode": shippingCountryCode as Any,
        ].compactMapValues { $0 }

        let res = try await client.runQuerySafe(
            query: ChannelGraphQL.GET_PRODUCTS_CHANNEL_QUERY,
            variables: vars
        )
        guard let list: [Any] = GraphQLPick.pickPath(res.data, path: ["Channel", "Products"]) else {
            throw SdkException("Empty response in Product.get", code: "EMPTY_RESPONSE")
        }
        let data = try JSONSerialization.data(withJSONObject: list, options: [])
        return try JSONDecoder().decode([ProductDto].self, from: data)
    }

    public func getByCategoryId(
        categoryId: Int,
        currency: String?,
        imageSize: String = "large",
        shippingCountryCode: String?
    ) async throws -> [ProductDto] {
        guard categoryId > 0 else {
            throw ValidationException("categoryId must be > 0", details: ["field": "categoryId"])
        }
        try validateCommonFilters(
            currency: currency, imageSize: imageSize, shippingCountryCode: shippingCountryCode)

        let res = try await client.runQuerySafe(
            query: ChannelGraphQL.GET_PRODUCTS_BY_CATEGORY_CHANNEL_QUERY,
            variables: [
                "categoryId": categoryId,
                "currency": currency as Any,
                "imageSize": imageSize,
                "shippingCountryCode": shippingCountryCode as Any,
            ].compactMapValues { $0 }
        )
        guard
            let list: [Any] = GraphQLPick.pickPath(
                res.data, path: ["Channel", "GetProductsByCategory"])
        else {
            throw SdkException("Empty response in Product.getByCategoryId", code: "EMPTY_RESPONSE")
        }
        let data = try JSONSerialization.data(withJSONObject: list, options: [])
        return try JSONDecoder().decode([ProductDto].self, from: data)
    }

    public func getByCategoryIds(
        categoryIds: [Int],
        currency: String?,
        imageSize: String = "large",
        shippingCountryCode: String?
    ) async throws -> [ProductDto] {
        try requirePositiveIds(categoryIds, "categoryIds")
        try validateCommonFilters(
            currency: currency, imageSize: imageSize, shippingCountryCode: shippingCountryCode)

        let res = try await client.runQuerySafe(
            query: ChannelGraphQL.GET_PRODUCTS_BY_CATEGORIES_CHANNEL_QUERY,
            variables: [
                "categoryIds": categoryIds,
                "currency": currency as Any,
                "imageSize": imageSize,
                "shippingCountryCode": shippingCountryCode as Any,
            ].compactMapValues { $0 }
        )
        guard
            let list: [Any] = GraphQLPick.pickPath(
                res.data, path: ["Channel", "GetProductsByCategories"])
        else {
            throw SdkException("Empty response in Product.getByCategoryIds", code: "EMPTY_RESPONSE")
        }
        let data = try JSONSerialization.data(withJSONObject: list, options: [])
        return try JSONDecoder().decode([ProductDto].self, from: data)
    }

    public func getByParams(
        currency: String?,
        imageSize: String = "large",
        sku: String?,
        barcode: String?,
        productId: Int?,
        shippingCountryCode: String?
    ) async throws -> ProductDto {
        try validateCommonFilters(
            currency: currency, imageSize: imageSize, shippingCountryCode: shippingCountryCode)
        if let pid = productId, pid <= 0 {
            throw ValidationException("productId must be > 0", details: ["field": "productId"])
        }
        if let s = sku, s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationException("sku cannot be empty", details: ["field": "sku"])
        }
        if let b = barcode, b.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationException("barcode cannot be empty", details: ["field": "barcode"])
        }

        let res = try await client.runQuerySafe(
            query: ChannelGraphQL.GET_PRODUCT_CHANNEL_QUERY,
            variables: [
                "currency": currency as Any,
                "imageSize": imageSize,
                "sku": sku as Any,
                "barcode": barcode as Any,
                "productId": productId as Any,
                "shippingCountryCode": shippingCountryCode as Any,
            ].compactMapValues { $0 }
        )
        guard
            let obj: [String: Any] = GraphQLPick.pickPath(
                res.data, path: ["Channel", "GetProduct"])
        else {
            throw SdkException("Empty response in Product.getByParams", code: "EMPTY_RESPONSE")
        }
        return try GraphQLPick.decodeJSON(obj, as: ProductDto.self)
    }

    public func getByIds(
        productIds: [Int],
        currency: String?,
        imageSize: String = "large",
        useCache: Bool = true,
        shippingCountryCode: String?
    ) async throws -> [ProductDto] {
        try requirePositiveIds(productIds, "productIds")
        try validateCommonFilters(
            currency: currency, imageSize: imageSize, shippingCountryCode: shippingCountryCode)

        let res = try await client.runQuerySafe(
            query: ChannelGraphQL.GET_PRODUCTS_BY_IDS_CHANNEL_QUERY,
            variables: [
                "productIds": productIds,
                "currency": currency as Any,
                "imageSize": imageSize,
                "useCache": useCache,
                "shippingCountryCode": shippingCountryCode as Any,
            ].compactMapValues { $0 }
        )
        guard
            let list: [Any] = GraphQLPick.pickPath(res.data, path: ["Channel", "GetProductsByIds"])
        else {
            throw SdkException("Empty response in Product.getByIds", code: "EMPTY_RESPONSE")
        }
        let data = try JSONSerialization.data(withJSONObject: list, options: [])
        return try JSONDecoder().decode([ProductDto].self, from: data)
    }

    public func getBySkus(
        sku: String,
        productId: Int?,
        currency: String?,
        imageSize: String = "large",
        shippingCountryCode: String?
    ) async throws -> [ProductDto] {
        try Validation.requireNonEmpty(sku, field: "sku")
        if let pid = productId, pid <= 0 {
            throw ValidationException("productId must be > 0", details: ["field": "productId"])
        }
        try validateCommonFilters(
            currency: currency, imageSize: imageSize, shippingCountryCode: shippingCountryCode)

        let res = try await client.runQuerySafe(
            query: ChannelGraphQL.GET_PRODUCT_BY_SKUS_CHANNEL_QUERY,
            variables: [
                "sku": sku,
                "productId": productId as Any,
                "currency": currency as Any,
                "imageSize": imageSize,
                "shippingCountryCode": shippingCountryCode as Any,
            ].compactMapValues { $0 }
        )
        guard
            let list: [Any] = GraphQLPick.pickPath(res.data, path: ["Channel", "GetProductBySKUs"])
        else {
            throw SdkException("Empty response in Product.getBySkus", code: "EMPTY_RESPONSE")
        }
        let data = try JSONSerialization.data(withJSONObject: list, options: [])
        return try JSONDecoder().decode([ProductDto].self, from: data)
    }

    public func getByBarcodes(
        barcode: String,
        productId: Int?,
        currency: String?,
        imageSize: String = "large",
        shippingCountryCode: String?
    ) async throws -> [ProductDto] {
        try Validation.requireNonEmpty(barcode, field: "barcode")
        if let pid = productId, pid <= 0 {
            throw ValidationException("productId must be > 0", details: ["field": "productId"])
        }
        try validateCommonFilters(
            currency: currency, imageSize: imageSize, shippingCountryCode: shippingCountryCode)

        let res = try await client.runQuerySafe(
            query: ChannelGraphQL.GET_PRODUCT_BY_BARCODES_CHANNEL_QUERY,
            variables: [
                "barcode": barcode,
                "productId": productId as Any,
                "currency": currency as Any,
                "imageSize": imageSize,
                "shippingCountryCode": shippingCountryCode as Any,
            ].compactMapValues { $0 }
        )
        guard
            let list: [Any] = GraphQLPick.pickPath(
                res.data, path: ["Channel", "GetProductByBarcodes"])
        else {
            throw SdkException("Empty response in Product.getByBarcodes", code: "EMPTY_RESPONSE")
        }
        let data = try JSONSerialization.data(withJSONObject: list, options: [])
        return try JSONDecoder().decode([ProductDto].self, from: data)
    }
}
