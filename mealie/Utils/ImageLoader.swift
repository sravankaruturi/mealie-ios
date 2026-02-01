// If you need custom image loading logic, add it here. For now, Kingfisher is used directly in RecipeCardView.

import Foundation
import Kingfisher
import SwiftUI

/// A SwiftUI view that loads and displays a recipe image from the Mealie server using Kingfisher.
struct RecipeImageView: View {

    /// The API service used to construct image URLs.
    var mealieAPIService: MealieAPIServiceProtocol

    /// The remote recipe ID used to build the image URL.
    let recipeId: String
    /// The image size variant to load.
    let imageType: ImageType
    /// An optional placeholder image shown while loading.
    let placeholder: Image?
    /// How the image fills its frame.
    let contentMode: SwiftUI.ContentMode
    /// Corner radius applied to the loaded image.
    let cornerRadius: CGFloat

    /// Creates a recipe image view.
    init(
        mealieAPIService: MealieAPIServiceProtocol,
        recipeId: String,
        imageType: ImageType = .original,
        placeholder: Image? = nil,
        contentMode: SwiftUI.ContentMode = .fill,
        cornerRadius: CGFloat = 0
    ) {
        self.mealieAPIService = mealieAPIService
        self.recipeId = recipeId
        self.imageType = imageType
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        
        let url = self.mealieAPIService.getRecipeImageURLForKingfisher(
            recipeId: recipeId,
            imageType: imageType
        )
        
        KFImage(url)
            .placeholder {
                (self.placeholder ?? Image(systemName: "photo"))
                    .foregroundColor(.gray)
            }
            .onFailure { error in
                AppLogger.error(.general, "Failed to load recipe image: \(error)")
            }
            .cacheMemoryOnly(false) // Cache to disk for better performance
            .fade(duration: 0.3) // Smooth fade-in animation
            .resizable()
            .aspectRatio(contentMode: contentMode)
            .cornerRadius(cornerRadius)
    }
} 

#Preview {
    
    let mockAPI = MockMealieAPIService()
    
    RecipeImageView(mealieAPIService: mockAPI, recipeId: "TestImage")
}
