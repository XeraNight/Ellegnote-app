import SwiftUI

// MARK: - Category Tile View
struct CategoryTileView: View {
    let title: String
    let description: String
    let accentColor: Color
    let iconName: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Accent Bar matching the style (Standard or Latin)
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 5)
                .padding(.vertical, 16)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: iconName)
                        .font(.system(size: 14))
                        .foregroundColor(accentColor)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(.themeDark)
                        .tracking(0.5)
                }
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.themeDark.opacity(0.6))
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.themeDark.opacity(0.3))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .frame(height: 120)
        .neubrutalistCard(cornerRadius: 20, shadowOffset: 4)
    }
}
