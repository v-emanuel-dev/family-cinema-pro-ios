//
//  ChannelRowView.swift
//  Family Cinema Pro
//
//  Componente de linha de canal
//

import SwiftUI

struct ChannelRowView: View {
    let channel: Channel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Live indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .textPrimary)
                        .lineLimit(1)
                    
                    Text(channel.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text(channel.category)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .primaryColor : .accentBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white : Color.clear)
                    .cornerRadius(8)
            }
            .padding(12)
            .background(isSelected ? Color.primaryColor : Color.surfaceDark)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct ChannelRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChannelRowView(
                channel: Channel.defaultFreeChannels[0],
                isSelected: false,
                onTap: {}
            )
            
            ChannelRowView(
                channel: Channel.defaultFreeChannels[0],
                isSelected: true,
                onTap: {}
            )
        }
        .padding()
        .background(Color.backgroundDark)
        .previewLayout(.sizeThatFits)
    }
}
#endif
