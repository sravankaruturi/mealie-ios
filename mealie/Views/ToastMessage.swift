import SwiftUI

struct ToastMessage: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    let queueCount: Int
    
    enum ToastType {
        case error
        case warning
        case success
        case info
        
        var backgroundColor: Color {
            switch self {
            case .error:
                return .red
            case .warning:
                return .orange
            case .success:
                return .green
            case .info:
                return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .error:
                return "exclamationmark.triangle.fill"
            case .warning:
                return "exclamationmark.triangle"
            case .success:
                return "checkmark.circle.fill"
            case .info:
                return "info.circle.fill"
            }
        }
    }
    
    init(message: String, type: ToastType, onDismiss: @escaping () -> Void, queueCount: Int = 0) {
        self.message = message
        self.type = type
        self.onDismiss = onDismiss
        self.queueCount = queueCount
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
            
            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.leading)
                .lineLimit(3)
            
            Spacer()
            
            if queueCount > 0 {
                Text("+\(queueCount)")
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    VStack {
        Spacer()
        ToastMessage(
            message: "Server URL is null. Please check your connection.",
            type: .error,
            onDismiss: {},
            queueCount: 3
        )
    }
    .background(Color.gray.opacity(0.1))
} 