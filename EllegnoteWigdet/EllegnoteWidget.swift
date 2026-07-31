import ActivityKit
import WidgetKit
import SwiftUI

@main
struct EllegnoteWidgetBundle: WidgetBundle {
    var body: some Widget {
        EllegnoteLiveActivity()
    }
}

struct EllegnoteLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EllegnoteAttributes.self) { context in
            // Lock Screen UI / Banner na uzamknutej obrazovke
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tréning: \(context.attributes.routineName)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.gray)
                        .textCase(.uppercase)
                    
                    Text(context.state.currentFigureName)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.black)
                    
                    if !context.state.nextFigureName.isEmpty {
                        Text("Nasleduje: \(context.state.nextFigureName)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Pravo-stranný kruh s indexom figúry
                VStack(spacing: 4) {
                    Text("\(context.state.currentFigureIndex) / \(context.state.totalFigures)")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.black)
                    Text("figúra")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                }
                .padding(10)
                .background(Color(red: 0.98, green: 0.96, blue: 0.89)) // Creamy yellow
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 2)
                )
                .shadow(color: Color.black, radius: 0, x: 2, y: 2)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.white)
            .activityBackgroundTint(Color.white)
            
            
        } dynamicIsland: { context in
            DynamicIsland {
                // 1. Expanded Režim (Rozbalený po podržaní prsta na Dynamic Islande)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.socialdance")
                            .font(.system(size: 18, weight: .black))
                            .foregroundColor(Color(red: 0.95, green: 0.26, blue: 0.21)) // Latin Red
                        Text(context.attributes.danceName)
                            .font(.system(size: 15, weight: .black))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 4)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.currentFigureIndex) / \(context.state.totalFigures)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                        .padding(.top, 4)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.attributes.routineName)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                        
                        Text(context.state.currentFigureName)
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if !context.state.nextFigureName.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.7))
                                Text(context.state.nextFigureName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 8)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Tréning zostavy v reálnom čase")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                        Spacer()
                        // Natívny časovač od spustenia
                        Text(timerInterval: context.state.lastUpdated...context.state.lastUpdated.addingTimeInterval(3600), countsDown: false)
                            .font(.system(size: 12, weight: .black))
                            .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0)) // Gold
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                // 2. Compact Leading (Ľavá strana pilulky)
                HStack(spacing: 4) {
                    Image(systemName: "figure.socialdance")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.95, green: 0.26, blue: 0.21))
                    Text(context.attributes.danceName.prefix(3).uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // 3. Compact Trailing (Pravá strana pilulky)
                Text("\(context.state.currentFigureIndex)/\(context.state.totalFigures)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(Color(red: 1.0, green: 0.84, blue: 0.0))
            }  minimal: {
                // 4. Minimal (Samostatný krúžok na boku)
                Image(systemName: "figure.socialdance")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.95, green: 0.26, blue: 0.21))
            }
        }
    }
}

