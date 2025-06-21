// If you need custom image loading logic, add it here. For now, Kingfisher is used directly in RecipeCardView.

import Foundation
import Kingfisher
import SwiftUI

struct RecipeImageView: View {
    let recipeId: String
    let imageType: MealieAPIService.ImageType
    let placeholder: Image?
    let contentMode: SwiftUI.ContentMode
    let cornerRadius: CGFloat
    
    init(
        recipeId: String,
        imageType: MealieAPIService.ImageType = .original,
        placeholder: Image? = nil,
        contentMode: SwiftUI.ContentMode = .fill,
        cornerRadius: CGFloat = 0
    ) {
        self.recipeId = recipeId
        self.imageType = imageType
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        let url = MealieAPIService.shared.getRecipeImageURLForKingfisher(
            recipeId: recipeId,
            imageType: imageType
        )
        
        KFImage(url)
            .placeholder {
                (self.placeholder ?? Image(systemName: "photo"))
                    .foregroundColor(.gray)
            }
            .onFailure { error in
                print("Failed to load recipe image: \(error)")
            }
            .cacheMemoryOnly(false) // Cache to disk for better performance
            .fade(duration: 0.3) // Smooth fade-in animation
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .cornerRadius(cornerRadius)
    }
} 
