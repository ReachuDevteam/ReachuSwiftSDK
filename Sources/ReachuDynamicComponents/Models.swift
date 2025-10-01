import Foundation
import SwiftUI
import ReachuCore

public enum DynamicComponentType: String, Codable, CaseIterable, Hashable {
    case countdown
    case banner
    case poll
    case productSpotlight
}

public enum DynamicComponentPosition: String, Codable, CaseIterable, Hashable {
    case top
    case bottom
    case leading
    case trailing
    case center
    case overlay
}

public struct DynamicComponent: Identifiable, Codable, Hashable {
    public let id: String
    public let type: DynamicComponentType
    public let startTime: Date?
    public let endTime: Date?
    public let position: DynamicComponentPosition
    public let priority: Int
    public let payload: [String: String]? // datos simples para MVP
    
    public init(
        id: String,
        type: DynamicComponentType,
        startTime: Date? = nil,
        endTime: Date? = nil,
        position: DynamicComponentPosition = .overlay,
        priority: Int = 0,
        payload: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.endTime = endTime
        self.position = position
        self.priority = priority
        self.payload = payload
    }
}

// Configuración específica del sistema de componentes
public struct DynamicComponentsConfiguration: Equatable {
    public let enableDynamicComponents: Bool
    public let maxConcurrentComponents: Int
    public let autoRefreshInterval: TimeInterval
    
    public init(
        enableDynamicComponents: Bool = true,
        maxConcurrentComponents: Int = 3,
        autoRefreshInterval: TimeInterval = 60
    ) {
        self.enableDynamicComponents = enableDynamicComponents
        self.maxConcurrentComponents = maxConcurrentComponents
        self.autoRefreshInterval = autoRefreshInterval
    }
    
    public static let `default` = DynamicComponentsConfiguration()
}

