import SwiftUI
import SwiftData

struct MealPlanView: View {
    @Query(sort: [SortDescriptor<MealPlanEntry>(\.date)]) var entries: [MealPlanEntry]
    @State private var selectedSegment = 0
    @State private var selectedDate = Date()
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("View", selection: $selectedSegment) {
                    Text("Week").tag(0)
                    Text("Month").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                CalendarView(selectedDate: $selectedDate, entries: entries)
                
                Button("Add Recipe to Plan") { showAddSheet = true }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .navigationTitle("Meal Plan")
            .sheet(isPresented: $showAddSheet) {
                // You will need to implement this view to add recipes to your plan.
                AddMealPlanEntryView(selectedDate: selectedDate)
            }
        }
    }
}

// NOTE: This is a placeholder view. You will need to implement a full calendar UI.
struct CalendarView: View {
    @Binding var selectedDate: Date
    let entries: [MealPlanEntry]
    
    var body: some View {
        Text("Calendar UI Placeholder")
            .frame(maxWidth: .infinity, minHeight: 200)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding()
    }
}

// NOTE: This is a placeholder view. You will need to implement the UI for adding a meal plan entry.
struct AddMealPlanEntryView: View {
    let selectedDate: Date
    
    var body: some View {
        Text("Add Meal Plan Entry for \(selectedDate, formatter: DateFormatter.mealieDisplay)")
            .padding()
    }
}

//// FIX: Make this extension private to avoid "Invalid redeclaration" errors
//// if it's defined in other files.
//private extension DateFormatter {
//    static let mealieDisplay: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .long
//        return formatter
//    }()
//}
