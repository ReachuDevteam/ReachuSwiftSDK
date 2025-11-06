import XCTest
@testable import ReachuCore
@testable import ReachuUI

@MainActor
final class ComponentTests: XCTestCase {
    
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
    }
    
    // MARK: - RProductBanner Tests
    
    func testRProductBannerInitialization() {
        let banner = RProductBanner()
        XCTAssertNotNil(banner)
    }
    
    func testRProductBannerWithComponentId() {
        let banner = RProductBanner(componentId: "test-banner")
        XCTAssertNotNil(banner)
    }
    
    // MARK: - RProductCarousel Tests
    
    func testRProductCarouselInitialization() {
        let carousel = RProductCarousel()
        XCTAssertNotNil(carousel)
    }
    
    func testRProductCarouselWithLayout() {
        let carouselFull = RProductCarousel(layout: "full")
        XCTAssertNotNil(carouselFull)
        
        let carouselCompact = RProductCarousel(layout: "compact")
        XCTAssertNotNil(carouselCompact)
        
        let carouselHorizontal = RProductCarousel(layout: "horizontal")
        XCTAssertNotNil(carouselHorizontal)
    }
    
    func testRProductCarouselWithComponentId() {
        let carousel = RProductCarousel(componentId: "test-carousel")
        XCTAssertNotNil(carousel)
    }
    
    // MARK: - RProductStore Tests
    
    func testRProductStoreInitialization() {
        let store = RProductStore()
        XCTAssertNotNil(store)
    }
    
    func testRProductStoreWithMode() {
        let storeAll = RProductStore(mode: "all")
        XCTAssertNotNil(storeAll)
        
        let storeFiltered = RProductStore(mode: "filtered")
        XCTAssertNotNil(storeFiltered)
    }
    
    func testRProductStoreWithComponentId() {
        let store = RProductStore(componentId: "test-store")
        XCTAssertNotNil(store)
    }
    
    // MARK: - RProductSpotlight Tests
    
    func testRProductSpotlightInitialization() {
        let spotlight = RProductSpotlight()
        XCTAssertNotNil(spotlight)
    }
    
    func testRProductSpotlightWithVariant() {
        let spotlightHero = RProductSpotlight(variant: .hero)
        XCTAssertNotNil(spotlightHero)
        
        let spotlightGrid = RProductSpotlight(variant: .grid)
        XCTAssertNotNil(spotlightGrid)
        
        let spotlightList = RProductSpotlight(variant: .list)
        XCTAssertNotNil(spotlightList)
        
        let spotlightMinimal = RProductSpotlight(variant: .minimal)
        XCTAssertNotNil(spotlightMinimal)
    }
    
    func testRProductSpotlightWithComponentId() {
        let spotlight = RProductSpotlight(componentId: "test-spotlight")
        XCTAssertNotNil(spotlight)
    }
    
    func testRProductSpotlightWithShowAddToCartButton() {
        let spotlightWithButton = RProductSpotlight(showAddToCartButton: true)
        XCTAssertNotNil(spotlightWithButton)
        
        let spotlightWithoutButton = RProductSpotlight(showAddToCartButton: false)
        XCTAssertNotNil(spotlightWithoutButton)
    }
    
    // MARK: - RProductSlider Tests
    
    func testRProductSliderInitialization() {
        let slider = RProductSlider(
            title: "Test Products",
            products: []
        )
        XCTAssertNotNil(slider)
    }
    
    func testRProductSliderWithCategory() {
        let slider = RProductSlider(
            title: "Category Products",
            categoryId: 123
        )
        XCTAssertNotNil(slider)
    }
    
    func testRProductSliderLayouts() {
        let compact = RProductSlider.compact(title: "Compact")
        XCTAssertNotNil(compact)
        
        let cards = RProductSlider.cards(title: "Cards")
        XCTAssertNotNil(cards)
        
        let featured = RProductSlider.featured(title: "Featured")
        XCTAssertNotNil(featured)
        
        let detailed = RProductSlider.detailed(title: "Detailed")
        XCTAssertNotNil(detailed)
        
        let showcase = RProductSlider.showcase(title: "Showcase")
        XCTAssertNotNil(showcase)
        
        let micro = RProductSlider.micro(title: "Micro")
        XCTAssertNotNil(micro)
    }
}

// MARK: - ViewModel Tests

@MainActor
final class ViewModelTests: XCTestCase {
    
    func testRProductCarouselViewModelInitialState() {
        let viewModel = RProductCarouselViewModel()
        XCTAssertEqual(viewModel.products.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isMarketUnavailable)
        XCTAssertEqual(viewModel.currentIndex, 0)
    }
    
    func testRProductStoreViewModelInitialState() {
        let viewModel = RProductStoreViewModel()
        XCTAssertEqual(viewModel.products.count, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isMarketUnavailable)
    }
    
    func testRProductSpotlightViewModelInitialState() {
        let viewModel = RProductSpotlightViewModel()
        XCTAssertNil(viewModel.product)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isMarketUnavailable)
    }
}

// MARK: - Error Handling Tests

@MainActor
final class ErrorHandlingTests: XCTestCase {
    
    func testProductServiceErrorDescriptions() {
        let invalidConfig = ProductServiceError.invalidConfiguration("Test message")
        XCTAssertNotNil(invalidConfig.errorDescription)
        XCTAssertTrue(invalidConfig.errorDescription?.contains("Invalid configuration") ?? false)
        
        let invalidId = ProductServiceError.invalidProductId("invalid")
        XCTAssertNotNil(invalidId.errorDescription)
        XCTAssertTrue(invalidId.errorDescription?.contains("Invalid product ID") ?? false)
        
        let notFound = ProductServiceError.productNotFound(123)
        XCTAssertNotNil(notFound.errorDescription)
        XCTAssertTrue(notFound.errorDescription?.contains("Product not found") ?? false)
    }
}

