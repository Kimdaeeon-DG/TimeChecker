import SwiftUI

struct ProgressBarView: View {
    let value: Double
    let total: Double
    
    private var percentage: Double {
        min(value / total * 100, 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .cornerRadius(10)
                    
                    Rectangle()
                        .foregroundColor(progressColor)
                        .frame(width: min(CGFloat(percentage) * geometry.size.width / 100, geometry.size.width), height: 20)
                        .cornerRadius(10)
                        .animation(.linear, value: value)
                }
            }
            .frame(height: 20)
            
            Text("\(Int(percentage))% 달성")
                .font(.caption)
                .foregroundColor(.gray)
        }
    }
    
    private var progressColor: Color {
        if percentage < 50 {
            return .blue
        } else if percentage < 80 {
            return .green
        } else if percentage < 100 {
            return .orange
        } else {
            return .red
        }
    }
}
