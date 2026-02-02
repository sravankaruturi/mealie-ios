import Testing
import Foundation
import SwiftData
@testable import mealIO

@Suite("SyncMetadata Tests")
struct SyncMetadataTests {

    @Test
    func lastSyncTime_returnsNil_whenNeverSynced() {
        let context = makeTestModelContext()
        let result = SyncMetadata.lastSyncTime(in: context)
        #expect(result == nil)
    }

    @Test
    func setLastSyncTime_persistsValue() {
        let context = makeTestModelContext()
        let now = Date()
        SyncMetadata.setLastSyncTime(now, in: context)

        let result = SyncMetadata.lastSyncTime(in: context)
        #expect(result != nil)
    }

    @Test
    func lastSyncTime_roundTrips() {
        let context = makeTestModelContext()

        // Use a date with second precision (SwiftData may truncate sub-second)
        let date = Date(timeIntervalSince1970: 1700000000)
        SyncMetadata.setLastSyncTime(date, in: context)

        let result = SyncMetadata.lastSyncTime(in: context)
        #expect(result != nil)
        // Allow 1 second tolerance for any precision differences
        if let result {
            #expect(abs(result.timeIntervalSince(date)) < 1.0)
        }
    }

    @Test
    func setLastSyncTime_updatesExistingValue() {
        let context = makeTestModelContext()

        let firstDate = Date(timeIntervalSince1970: 1700000000)
        SyncMetadata.setLastSyncTime(firstDate, in: context)

        let secondDate = Date(timeIntervalSince1970: 1700001000)
        SyncMetadata.setLastSyncTime(secondDate, in: context)

        let result = SyncMetadata.lastSyncTime(in: context)
        #expect(result != nil)
        if let result {
            #expect(abs(result.timeIntervalSince(secondDate)) < 1.0)
        }

        // Should only have one metadata entry, not two
        let allMetadata = (try? context.fetch(FetchDescriptor<SyncMetadata>())) ?? []
        #expect(allMetadata.count == 1)
    }
}
