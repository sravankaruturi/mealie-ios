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
                
            }
            
        }
        .padding(.trailing, 10)
    
    }
    
}

#Preview {
    AddRecipeOptionsView(onURLImport: { }, onManualImport: { })
}

//
//// Sheet view for adding recipes
//struct AddRecipeSheetView: View {
//    @Environment(\.dismiss) var dismiss
//    @Environment(\.modelContext) private var modelContext
//    let onURLImport: () -> Void
//    
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 32) {
//                Spacer()
//                Button(action: {
//                    // TODO: Implement manual recipe form
//                    dismiss()
//                }) {
//                    Text("Manual")
//                        .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.borderedProminent)
//                
//                Button(action: {
//                    onURLImport()
//                }) {
//                    Text("From URL")
//                        .frame(maxWidth: .infinity)
//                }
//                .buttonStyle(.bordered)
//                Spacer()
//            }
//            .padding()
//            .navigationTitle("Add Recipe")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
