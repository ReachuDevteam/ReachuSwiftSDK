import Foundation

// MARK: - Category
struct Category: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let slug: String
}

// MARK: - Content Item
struct ContentItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let imageURL: String
    let category: String
    let isLive: Bool
    let duration: String?
    let date: String?
    
    init(
        title: String,
        subtitle: String? = nil,
        imageURL: String,
        category: String,
        isLive: Bool = false,
        duration: String? = nil,
        date: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.imageURL = imageURL
        self.category = category
        self.isLive = isLive
        self.duration = duration
        self.date = date
    }
}

// MARK: - Mock Data
extension ContentItem {
    static let mockItems: [ContentItem] = [
        ContentItem(
            title: "FOTBALLKVELD",
            subtitle: "Alt fra CL-runden",
            imageURL: "fotball_1",
            category: "Fotball",
            isLive: false,
            date: "I dag 17:40"
        ),
        ContentItem(
            title: "CHAMPIONS LEAGUE",
            subtitle: "Kremmerne",
            imageURL: "fotball_2",
            category: "Fotball",
            isLive: false,
            date: "I dag 19:00"
        ),
        ContentItem(
            title: "Rolex Shanghai Masters",
            subtitle: "Dag 2",
            imageURL: "tennis_1",
            category: "Tennis",
            isLive: true,
            duration: "DIREKTE"
        ),
        ContentItem(
            title: "Rosenborg vs Brann",
            subtitle: "Fotball kveld",
            imageURL: "fotball_3",
            category: "Fotball",
            isLive: false,
            date: "I dag 17:40"
        ),
        ContentItem(
            title: "Håndball Highlights",
            subtitle: "Best of Champions League",
            imageURL: "handball_1",
            category: "Håndball",
            isLive: false,
            date: "I går 20:00"
        ),
        ContentItem(
            title: "Sykkel VM",
            subtitle: "Herrenes fellesstart",
            imageURL: "cycling_1",
            category: "Sykkel",
            isLive: false,
            date: "27 sep"
        )
    ]
}

extension Category {
    static let mockCategories: [Category] = [
        Category(name: "Sporten", slug: "sporten"),
        Category(name: "Fotball", slug: "fotball"),
        Category(name: "Norsk", slug: "norsk"),
        Category(name: "Tennis", slug: "tennis"),
        Category(name: "Håndball", slug: "handball"),
        Category(name: "Sykkel", slug: "cycling")
    ]
}


