import Foundation

@MainActor
public extension DynamicComponentManager {
    func loadFromAPI(api: DynamicComponentsAPI, campaignId: String) async {
        do {
            let components = try await api.fetchComponents(campaignId: campaignId)
            clearAll()
            components.forEach { register($0) }
        } catch {
            print("[DynamicComponents] loadFromAPI error: \(error)")
        }
    }
}


