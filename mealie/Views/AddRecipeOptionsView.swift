//
//  AddRecipeOptionsView.swift
//  mealie
//
//  Created by Sravan Karuturi on 7/27/25.
//

import SwiftUI

struct AddRecipeOptionsView: View {
    
    let onURLImport: () -> Void
    let onManualImport: () -> Void
    
    var body: some View {
            
        VStack (alignment: .trailing, spacing: 10) {
            
            Group{
                HStack {
                    
                    Spacer()
                    
                    Text("URL")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Image(systemName: "link.circle")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                }
                .padding(.all)
            }
            .frame(width: 120, height: 36)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4)
            .onTapGesture {
                onURLImport()
            }
            
            Group{
                HStack {
                    
                    Spacer()
                    
                    Text("Manual")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                }
                .padding(.all)
            }
            .frame(width: 120, height: 36)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4)
            .onTapGesture {
                onManualImport()
            }
            
        }
        .padding(.trailing, 10)
    
    }
    
}

#Preview {
    AddRecipeOptionsView(onURLImport: { }, onManualImport: { })
}
