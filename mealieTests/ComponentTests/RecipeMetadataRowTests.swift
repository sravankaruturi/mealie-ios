import Testing
@testable import mealIO

struct RecipeMetadataRowTests {

    // MARK: - filtered() Tests

    @Test
    func filtered_removesEmptyValues() {
        let items: [RecipeMetadataRow.MetadataItem] = [
            .init(icon: "person.2", value: "4"),
            .init(icon: "timer", value: ""),
            .init(icon: "flame", value: "30 min"),
        ]
        let result = RecipeMetadataRow.filtered(items)
        #expect(result.count == 2)
        #expect(result[0].value == "4")
        #expect(result[1].value == "30 min")
    }

    @Test
    func filtered_keepsNonEmptyValues() {
        let items: [RecipeMetadataRow.MetadataItem] = [
            .init(icon: "person.2", value: "4"),
            .init(icon: "timer", value: "15 min"),
            .init(icon: "flame", value: "30 min"),
        ]
        let result = RecipeMetadataRow.filtered(items)
        #expect(result.count == 3)
    }

    @Test
    func filtered_handlesAllEmpty() {
        let items: [RecipeMetadataRow.MetadataItem] = [
            .init(icon: "timer", value: ""),
            .init(icon: "flame", value: ""),
        ]
        let result = RecipeMetadataRow.filtered(items)
        #expect(result.isEmpty)
    }

    @Test
    func filtered_trimsWhitespace() {
        let items: [RecipeMetadataRow.MetadataItem] = [
            .init(icon: "person.2", value: "  "),
            .init(icon: "timer", value: " 15 min "),
            .init(icon: "flame", value: "   "),
        ]
        let result = RecipeMetadataRow.filtered(items)
        #expect(result.count == 1)
        #expect(result[0].value == " 15 min ")
    }

    @Test
    func filtered_trimsNewlines() {
        let items: [RecipeMetadataRow.MetadataItem] = [
            .init(icon: "person.2", value: "\n"),
            .init(icon: "timer", value: "15 min"),
            .init(icon: "flame", value: " \n "),
        ]
        let result = RecipeMetadataRow.filtered(items)
        #expect(result.count == 1)
        #expect(result[0].value == "15 min")
    }
}
