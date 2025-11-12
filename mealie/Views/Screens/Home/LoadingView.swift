//
//  LoadingView.swift
//  mealIO
//
//  Created by Sravan Karuturi on 11/11/25.
//

import SwiftUI

struct LoadingView : View {
    
    var body: some View {
        
        VStack {
            
            ProgressView()
                .progressViewStyle(.linear)
            
            Text("Loading...")
                .font(.largeTitle)
                .foregroundColor(.primary)
        }
    }
    
}
