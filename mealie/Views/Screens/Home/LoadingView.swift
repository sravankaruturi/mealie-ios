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
            
            Text("Loading...")
                .font(.title2)
                .foregroundColor(.primary)
        }
    }
    
}
