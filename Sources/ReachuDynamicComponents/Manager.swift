import Foundation
import SwiftUI
import Combine
import ReachuCore

public protocol DynamicComponentRenderable: View {
    init(component: DynamicComponent)
}

@MainActor
public final class DynamicComponentRegistry {
    public static let shared = DynamicComponentRegistry()
    
    private var builders: [DynamicComponentType: (DynamicComponent) -> AnyView] = [:]
    
    private init() {}
    
    public func register<T: DynamicComponentRenderable>(_ type: DynamicComponentType, as view: T.Type) {
        builders[type] = { component in AnyView(T(component: component)) }
    }
    
    public func buildView(for component: DynamicComponent) -> AnyView? {
        builders[component.type]?(component)
    }
}

@MainActor
public final class DynamicComponentManager: ObservableObject {
    @Published public private(set) var activeComponents: [DynamicComponent] = []
    @Published public private(set) var visibleComponents: [DynamicComponent] = []
    
    private var cancellables = Set<AnyCancellable>()
    private let configuration: DynamicComponentsConfiguration
    
    public init(configuration: DynamicComponentsConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func register(_ component: DynamicComponent) {
        guard configuration.enableDynamicComponents else { return }
        activeComponents.removeAll { $0.id == component.id }
        activeComponents.append(component)
        recomputeVisibility()
    }
    
    public func unregister(id: String) {
        activeComponents.removeAll { $0.id == id }
        recomputeVisibility()
    }
    
    public func activate(id: String) {
        guard let comp = activeComponents.first(where: { $0.id == id }) else { return }
        if !visibleComponents.contains(comp) {
            visibleComponents.append(comp)
            trimIfNeeded()
        }
    }
    
    public func deactivate(id: String) {
        visibleComponents.removeAll { $0.id == id }
    }
    
    public func clearAll() {
        activeComponents.removeAll()
        visibleComponents.removeAll()
    }
    
    private func recomputeVisibility() {
        let sorted = activeComponents.sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                return (lhs.startTime ?? .distantPast) < (rhs.startTime ?? .distantPast)
            }
            return lhs.priority > rhs.priority
        }
        visibleComponents = Array(sorted.prefix(configuration.maxConcurrentComponents))
    }
    
    private func trimIfNeeded() {
        if visibleComponents.count > configuration.maxConcurrentComponents {
            visibleComponents = Array(visibleComponents.prefix(configuration.maxConcurrentComponents))
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public struct DynamicComponentsHost<Background: View>: View {
    @ObservedObject private var manager: DynamicComponentManager
    private let background: Background
    
    public init(manager: DynamicComponentManager, @ViewBuilder background: () -> Background) {
        self.manager = manager
        self.background = background()
    }
    
    public var body: some View {
        ZStack {
            background
            ForEach(manager.visibleComponents, id: \.id) { component in
                if let view = DynamicComponentRegistry.shared.buildView(for: component) {
                    view
                        .modifier(PositionModifier(position: component.position))
                        .transition(.opacity)
                }
            }
        }
    }
}

private struct PositionModifier: ViewModifier {
    let position: DynamicComponentPosition
    
    func body(content: Content) -> some View {
        switch position {
        case .top: return AnyView(VStack { content; Spacer() })
        case .bottom: return AnyView(VStack { Spacer(); content })
        case .leading: return AnyView(HStack { content; Spacer() })
        case .trailing: return AnyView(HStack { Spacer(); content })
        case .center: return AnyView(content)
        case .overlay: return AnyView(content)
        }
    }
}

