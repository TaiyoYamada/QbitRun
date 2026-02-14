import SwiftUI
import UIKit

// MARK: - QuantumGate UI拡張

/// QuantumGateのUI表示に必要なプロパティを集約
extension QuantumGate {
    
    /// ゲートの表示記号
    var symbol: String {
        switch self {
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        case .h: return "H"
        case .s: return "S"
        case .t: return "T"
        }
    }
    
    /// SwiftUI用カラー
    var swiftUIColor: Color {
        switch self {
        case .x: return Color(red: 0.9, green: 0.3, blue: 0.3)
        case .y: return Color(red: 0.3, green: 0.8, blue: 0.3)
        case .z: return Color(red: 0.3, green: 0.5, blue: 0.9)
        case .h: return Color(red: 0.9, green: 0.6, blue: 0.2)
        case .s: return Color(red: 0.7, green: 0.3, blue: 0.8)
        case .t: return Color(red: 0.2, green: 0.7, blue: 0.7)
        }
    }
    
    /// UIKit用カラー
    var color: UIColor {
        switch self {
        case .x: return UIColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        case .y: return UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1.0)
        case .z: return UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
        case .h: return UIColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1.0)
        case .s: return UIColor(red: 0.7, green: 0.3, blue: 0.8, alpha: 1.0)
        case .t: return UIColor(red: 0.2, green: 0.7, blue: 0.7, alpha: 1.0)
        }
    }
}
