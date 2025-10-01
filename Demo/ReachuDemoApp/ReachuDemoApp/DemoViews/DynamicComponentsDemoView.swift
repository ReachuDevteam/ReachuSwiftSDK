import SwiftUI
import ReachuCore
import ReachuDesignSystem
import ReachuDynamicComponents

struct DynamicComponentsDemoView: View {
    @StateObject private var manager = ReachuDynamicComponentManager()
    @State private var baseUrlString: String = "https://api-qa.reachu.io"
    @State private var campaignId: String = "6802cc64-6fec-4c60-a5af-4ac3668fc01e"
    @State private var isLoading: Bool = false
    @State private var lastError: String?
    
    var body: some View {
        DynamicComponentsHost(manager: manager) {
            VStack(spacing: ReachuSpacing.lg) {
                header
                form
                actions
                Spacer()
                info
            }
            .padding(ReachuSpacing.lg)
            .navigationTitle("Dynamic Components")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                ReachuDynamicComponents.configure()
                registerDynamicComponentExamples()
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: ReachuSpacing.xs) {
            Text("Prueba del sistema de componentes dinámicos")
                .font(ReachuTypography.headline)
                .foregroundColor(ReachuColors.textPrimary)
            Text("Carga componentes desde la campaña y renderízalos sobre la vista")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var form: some View {
        VStack(spacing: ReachuSpacing.sm) {
            TextField("Base URL", text: $baseUrlString)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(ReachuSpacing.sm)
                .background(ReachuColors.surface)
                .cornerRadius(ReachuBorderRadius.small)
            
            TextField("Campaign ID", text: $campaignId)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(ReachuSpacing.sm)
                .background(ReachuColors.surface)
                .cornerRadius(ReachuBorderRadius.small)
        }
    }
    
    private var actions: some View {
        HStack(spacing: ReachuSpacing.md) {
            RButton(title: "Cargar", style: .primary, isLoading: isLoading) {
                loadComponents()
            }
            RButton(title: "Limpiar", style: .secondary) {
                manager.clearAll()
            }
        }
    }
    
    private var info: some View {
        VStack(alignment: .leading, spacing: ReachuSpacing.sm) {
            Text("Activos: \(manager.activeComponents.count)")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textPrimary)
            Text("Visibles: \(manager.visibleComponents.count)")
                .font(ReachuTypography.body)
                .foregroundColor(ReachuColors.textPrimary)
            if let lastError {
                Text(lastError)
                    .font(ReachuTypography.caption1)
                    .foregroundColor(ReachuColors.error)
            }
        }
    }
    
    private func loadComponents() {
        guard let baseURL = URL(string: baseUrlString) else {
            lastError = "URL inválida"
            return
        }
        isLoading = true
        lastError = nil
        let api = DynamicComponentsAPI(baseURL: baseURL)
        Task {
            await manager.loadFromAPI(api: api, campaignId: campaignId)
            isLoading = false
        }
    }
}


