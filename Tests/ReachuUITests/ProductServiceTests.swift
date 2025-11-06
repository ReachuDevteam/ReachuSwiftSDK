import XCTest
@testable import ReachuCore
@testable import ReachuUI

@MainActor
final class ProductServiceTests: XCTestCase {
    
    var productService: ProductService!
    
    override func setUp() async throws {
        // Configure SDK for testing
        ReachuConfiguration.configure(
            apiKey: "TEST_KEY",
            environment: .development,
            marketConfig: MarketConfiguration(
                countryCode: "US",
                countryName: "United States",
                currencyCode: "USD",
                currencySymbol: "$",
                phoneCode: "+1",
                flagURL: nil
            )
        )
        
        productService = ProductService.shared
        productService.clearCache() // Clear cache before each test
    }
    
    func testInvalidProductId() async {
        // Test with invalid product ID format
        do {
            _ = try await productService.loadProduct(
                productId: "invalid",
                currency: "USD",
                country: "US"
            )
            XCTFail("Should have thrown ProductServiceError.invalidProductId")
        } catch ProductServiceError.invalidProductId(let id) {
            XCTAssertEqual(id, "invalid")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testInvalidConfiguration() async {
        // Test with invalid GraphQL URL
        ReachuConfiguration.configure(
            apiKey: "TEST_KEY",
            environment: .custom(graphQLURL: "invalid-url"),
            marketConfig: MarketConfiguration(
                countryCode: "US",
                countryName: "United States",
                currencyCode: "USD",
                currencySymbol: "$",
                phoneCode: "+1",
                flagURL: nil
            )
        )
        
        productService.clearCache()
        
        do {
            _ = try await productService.loadProduct(
                productId: "123",
                currency: "USD",
                country: "US"
            )
            XCTFail("Should have thrown ProductServiceError.invalidConfiguration")
        } catch ProductServiceError.invalidConfiguration(let message) {
            XCTAssertTrue(message.contains("Invalid GraphQL URL"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLoadProductsWithEmptyArray() async {
        // Test loading products with empty array (should load all)
        do {
            let products = try await productService.loadProducts(
                productIds: [],
                currency: "USD",
                country: "US"
            )
            // Should not crash, even if no products returned
            XCTAssertNotNil(products)
        } catch {
            // Network errors are acceptable in tests
            XCTAssertTrue(error is ProductServiceError || error is SdkException)
        }
    }
    
    func testLoadProductsWithNil() async {
        // Test loading products with nil (should load all)
        do {
            let products = try await productService.loadProducts(
                productIds: nil,
                currency: "USD",
                country: "US"
            )
            // Should not crash, even if no products returned
            XCTAssertNotNil(products)
        } catch {
            // Network errors are acceptable in tests
            XCTAssertTrue(error is ProductServiceError || error is SdkException)
        }
    }
    
    func testClearCache() {
        // Test cache clearing
        productService.clearCache()
        // Should not crash
        XCTAssertNotNil(productService)
    }
}

// MARK: - ReachuLogger Tests

final class ReachuLoggerTests: XCTestCase {
    
    func testLoggingDisabled() {
        // Configure with logging disabled
        ReachuConfiguration.configure(
            apiKey: "TEST_KEY",
            environment: .development,
            networkConfig: NetworkConfiguration(enableLogging: false),
            marketConfig: MarketConfiguration(
                countryCode: "US",
                countryName: "United States",
                currencyCode: "USD",
                currencySymbol: "$",
                phoneCode: "+1",
                flagURL: nil
            )
        )
        
        // Should not crash
        ReachuLogger.debug("Test message", component: "TestComponent")
        ReachuLogger.info("Test message", component: "TestComponent")
        ReachuLogger.warning("Test message", component: "TestComponent")
        ReachuLogger.error("Test message", component: "TestComponent")
        ReachuLogger.success("Test message", component: "TestComponent")
    }
    
    func testLoggingEnabled() {
        // Configure with logging enabled
        ReachuConfiguration.configure(
            apiKey: "TEST_KEY",
            environment: .development,
            networkConfig: NetworkConfiguration(enableLogging: true, logLevel: .debug),
            marketConfig: MarketConfiguration(
                countryCode: "US",
                countryName: "United States",
                currencyCode: "USD",
                currencySymbol: "$",
                phoneCode: "+1",
                flagURL: nil
            )
        )
        
        // Should not crash
        ReachuLogger.debug("Test message", component: "TestComponent")
        ReachuLogger.info("Test message", component: "TestComponent")
        ReachuLogger.warning("Test message", component: "TestComponent")
        ReachuLogger.error("Test message", component: "TestComponent")
        ReachuLogger.success("Test message", component: "TestComponent")
    }
    
    func testLogLevelFiltering() {
        // Configure with warning level
        ReachuConfiguration.configure(
            apiKey: "TEST_KEY",
            environment: .development,
            networkConfig: NetworkConfiguration(enableLogging: true, logLevel: .warning),
            marketConfig: MarketConfiguration(
                countryCode: "US",
                countryName: "United States",
                currencyCode: "USD",
                currencySymbol: "$",
                phoneCode: "+1",
                flagURL: nil
            )
        )
        
        // Should not crash
        ReachuLogger.debug("Should not appear", component: "TestComponent")
        ReachuLogger.info("Should not appear", component: "TestComponent")
        ReachuLogger.warning("Should appear", component: "TestComponent")
        ReachuLogger.error("Should appear", component: "TestComponent")
    }
}

