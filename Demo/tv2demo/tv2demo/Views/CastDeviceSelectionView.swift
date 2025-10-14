import SwiftUI

/// Vista para seleccionar dispositivo de casting
struct CastDeviceSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var castingManager = CastingManager.shared
    let onDeviceSelected: (CastDevice) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                TV2Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Lista de dispositivos
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(castingManager.availableDevices) { device in
                                deviceRow(device)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
            }
            .navigationTitle("Cast to")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(TV2Theme.Colors.primary)
                }
            }
        }
    }
    
    private func deviceRow(_ device: CastDevice) -> some View {
        Button(action: {
            onDeviceSelected(device)
            dismiss()
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: device.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white)
                    
                    if let location = device.location {
                        Text("Casting: \(location)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(TV2Theme.Colors.surface)
        }
    }
}

#Preview {
    CastDeviceSelectionView { device in
        print("Selected: \(device.name)")
    }
}

