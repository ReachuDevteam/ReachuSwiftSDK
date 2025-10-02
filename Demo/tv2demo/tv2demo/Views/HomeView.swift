import SwiftUI
import ReachuCore
import ReachuDesignSystem
import ReachuUI
import ReachuLiveUI

struct HomeView: View {
    @State private var selectedCategory: Category? = Category.mockCategories[0]
    @State private var filteredContent: [ContentItem] = ContentItem.mockItems
    @State private var selectedTab: TabItem = .home
    @State private var showMatchDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                TV2Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // ScrollView content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Categories
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: TV2Theme.Spacing.md) {
                                    ForEach(Category.mockCategories) { category in
                                        CategoryChip(
                                            category: category,
                                            isSelected: selectedCategory?.id == category.id
                                        ) {
                                            selectedCategory = category
                                            filterContent()
                                        }
                                    }
                                }
                                .padding(.horizontal, TV2Theme.Spacing.md)
                                .padding(.vertical, TV2Theme.Spacing.sm)
                            }
                            
                            // Featured Content Section
                            contentSection(
                                title: "Direkte",
                                items: filteredContent.filter { $0.isLive }
                            )
                            
                            // Recent Content Section
                            contentSection(
                                title: "Nylig",
                                items: filteredContent.filter { !$0.isLive }
                            )
                        }
                    }
                    
                    // Bottom Tab Bar (part of VStack, not floating)
                    BottomTabBar(selectedTab: $selectedTab)
                }
            }
            .RProductCard(product: product)
            .RLiveShowFullScreenOverlay(stream: stream)
            .RCheckoutOverlay()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(TV2Theme.Colors.textPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: TV2Theme.Spacing.md) {
                        Button(action: {}) {
                            Image(systemName: "airplayvideo")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(TV2Theme.Colors.textPrimary)
                        }
                        
                        Circle()
                            .fill(TV2Theme.Colors.secondary)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text("A")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            filterContent()
        }
    }
    
    // MARK: - Content Section
    @ViewBuilder
    private func contentSection(title: String, items: [ContentItem]) -> some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: TV2Theme.Spacing.md) {
                // Section Header
                HStack {
                    Text(title)
                        .font(TV2Theme.Typography.title)
                        .foregroundColor(TV2Theme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(TV2Theme.Colors.textSecondary)
                            .padding(TV2Theme.Spacing.sm)
                            .background(
                                Circle()
                                    .fill(TV2Theme.Colors.primary.opacity(0.3))
                            )
                    }
                }
                .padding(.horizontal, TV2Theme.Spacing.md)
                .padding(.top, TV2Theme.Spacing.lg)
                
                // Content Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: TV2Theme.Spacing.md) {
                        ForEach(items) { item in
                            NavigationLink(destination: MatchDetailView(match: Match.dortmundAtletico)) {
                                ContentCard(
                                    item: item,
                                    width: 280,
                                    height: 160
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, TV2Theme.Spacing.md)
                }
                .padding(.bottom, TV2Theme.Spacing.lg)
            }
        }
    }
    
    // MARK: - Helpers
    private func filterContent() {
        if let category = selectedCategory, category.slug != "sporten" {
            filteredContent = ContentItem.mockItems.filter { 
                $0.category.lowercased().contains(category.slug.lowercased()) ||
                category.name.lowercased().contains($0.category.lowercased())
            }
        } else {
            filteredContent = ContentItem.mockItems
        }
    }
}

#Preview {
    HomeView()
}


