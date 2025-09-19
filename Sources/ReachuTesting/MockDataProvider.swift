import Foundation
import ReachuCore

/// Mock data provider for testing and previews
public class MockDataProvider {
    public static let shared = MockDataProvider()
    
    private init() {}
    
    // MARK: - Sample Products
    
    public let sampleProducts: [Product] = [
        Product(
            id: 101,
            title: "Reachu Wireless Headphones",
            brand: "Reachu Audio",
            description: "Experience immersive sound with noise-cancelling technology.",
            tags: "audio, headphones, wireless",
            sku: "RCH-HP-001",
            quantity: 50,
            price: Price(
                amount: 199.99,
                currency_code: "USD",
                amount_incl_taxes: 219.99,
                tax_amount: 20.00,
                tax_rate: 0.10,
                compare_at: 249.99,
                compare_at_incl_taxes: 274.99
            ),
            variants: [
                Variant(
                    id: "v101-black",
                    barcode: "1234567890123",
                    price: Price(amount: 199.99, currency_code: "USD"),
                    quantity: 25,
                    sku: "RCH-HP-001-BLK",
                    title: "Black"
                ),
                Variant(
                    id: "v101-white",
                    barcode: "1234567890124",
                    price: Price(amount: 199.99, currency_code: "USD"),
                    quantity: 25,
                    sku: "RCH-HP-001-WHT",
                    title: "White"
                )
            ],
            barcode: "1234567890123",
            options: [
                Option(id: "opt1", name: "Color", order: 1, values: "Black, White")
            ],
            categories: [
                Category(id: 1, name: "Electronics"),
                Category(id: 5, name: "Audio")
            ],
            images: [
                ProductImage(
                    id: "img101-1",
                    url: "https://via.placeholder.com/400x300/000000/FFFFFF?text=Headphones+Black",
                    order: 1
                ),
                ProductImage(
                    id: "img101-2",
                    url: "https://via.placeholder.com/400x300/FFFFFF/000000?text=Headphones+White",
                    order: 2
                )
            ],
            supplier: "Reachu Tech",
            supplier_id: 1
        ),
        Product(
            id: 102,
            title: "Reachu Smart Watch Series 5",
            brand: "Reachu Wearables",
            description: "Track your fitness and stay connected with the latest smartwatch.",
            tags: "wearable, smartwatch, fitness",
            sku: "RCH-SW-005",
            quantity: 30,
            price: Price(
                amount: 349.99,
                currency_code: "USD",
                amount_incl_taxes: 384.99,
                tax_amount: 35.00,
                tax_rate: 0.10
            ),
            variants: [
                Variant(
                    id: "v102-42mm",
                    barcode: "1234567890125",
                    price: Price(amount: 349.99, currency_code: "USD"),
                    quantity: 15,
                    sku: "RCH-SW-005-42MM",
                    title: "42mm"
                ),
                Variant(
                    id: "v102-44mm",
                    barcode: "1234567890126",
                    price: Price(amount: 349.99, currency_code: "USD"),
                    quantity: 15,
                    sku: "RCH-SW-005-44MM",
                    title: "44mm"
                )
            ],
            barcode: "1234567890125",
            options: [
                Option(id: "opt2", name: "Size", order: 1, values: "42mm, 44mm")
            ],
            categories: [
                Category(id: 1, name: "Electronics"),
                Category(id: 6, name: "Wearables")
            ],
            images: [
                ProductImage(
                    id: "img102-1",
                    url: "https://via.placeholder.com/400x300/FF5733/FFFFFF?text=Smartwatch",
                    order: 1
                )
            ],
            supplier: "Reachu Innovations",
            supplier_id: 2
        ),
        Product(
            id: 103,
            title: "Reachu Minimalist Backpack",
            brand: "Reachu Gear",
            description: "Stylish and durable backpack for daily commutes.",
            tags: "bag, backpack, travel",
            sku: "RCH-BP-001",
            quantity: 0, // Out of stock
            price: Price(
                amount: 89.99,
                currency_code: "USD",
                amount_incl_taxes: 98.99,
                tax_amount: 9.00,
                tax_rate: 0.10,
                compare_at: 100.00,
                compare_at_incl_taxes: 110.00
            ),
            variants: [
                Variant(
                    id: "v103-charcoal",
                    barcode: "1234567890127",
                    price: Price(amount: 89.99, currency_code: "USD"),
                    quantity: 0,
                    sku: "RCH-BP-001-CHR",
                    title: "Charcoal"
                ),
                Variant(
                    id: "v103-navy",
                    barcode: "1234567890128",
                    price: Price(amount: 89.99, currency_code: "USD"),
                    quantity: 0,
                    sku: "RCH-BP-001-NVY",
                    title: "Navy"
                )
            ],
            barcode: "1234567890127",
            options: [
                Option(id: "opt3", name: "Color", order: 1, values: "Charcoal, Navy")
            ],
            categories: [
                Category(id: 2, name: "Accessories"),
                Category(id: 7, name: "Bags")
            ],
            images: [
                ProductImage(
                    id: "img103-1",
                    url: "https://via.placeholder.com/400x300/333333/FFFFFF?text=Backpack",
                    order: 1
                )
            ],
            supplier: "Reachu Outdoors",
            supplier_id: 3
        ),
        Product(
            id: 104,
            title: "Reachu Wireless Charging Pad",
            brand: "Reachu Power",
            description: "Fast and convenient wireless charging for your devices.",
            tags: "charger, wireless, power",
            sku: "RCH-CP-002",
            quantity: 0, // Out of stock
            price: Price(
                amount: 39.99,
                currency_code: "USD",
                amount_incl_taxes: 43.99,
                tax_amount: 4.00,
                tax_rate: 0.10
            ),
            variants: [],
            barcode: "1234567890129",
            options: [],
            categories: [
                Category(id: 1, name: "Electronics"),
                Category(id: 8, name: "Chargers")
            ],
            images: [
                ProductImage(
                    id: "img104-1",
                    url: "https://via.placeholder.com/400x300/666666/FFFFFF?text=Charging+Pad",
                    order: 1
                )
            ],
            supplier: "Reachu Energy",
            supplier_id: 4
        )
    ]
}
