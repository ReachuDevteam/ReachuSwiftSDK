import XCTest
@testable import ReachuUI

final class ReachuUITests: XCTestCase {
    
    func testRProductCardVariants() throws {
        // Test that all variants are defined
        let gridVariant = RProductCard.Variant.grid
        let listVariant = RProductCard.Variant.list
        let heroVariant = RProductCard.Variant.hero
        let minimalVariant = RProductCard.Variant.minimal
        
        // These should not crash
        XCTAssertNotNil(gridVariant)
        XCTAssertNotNil(listVariant)
        XCTAssertNotNil(heroVariant)
        XCTAssertNotNil(minimalVariant)
    }
}
