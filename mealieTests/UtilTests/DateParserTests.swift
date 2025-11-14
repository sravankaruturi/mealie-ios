//
//  DateParserTests.swift
//  mealIO
//
//  Created by ChatGPT on 2024-06-01.
//

import Foundation
import Testing
@testable import mealIO

struct DateParserTests {

    @Test
    func parsesISO8601WithFractionalSeconds() {
        let isoString = "2024-02-29T13:45:30.123Z"
        let parsedDate = parseAPIDate(isoString)

        var formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let expectedDate = formatter.date(from: isoString)

        #expect(parsedDate == expectedDate)
    }

    @Test
    func parsesISO8601WithoutFractionalSeconds() {
        let isoString = "2024-02-29T13:45:30Z"
        let parsedDate = parseAPIDate(isoString)

        var formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let expectedDate = formatter.date(from: isoString)

        #expect(parsedDate == expectedDate)
    }

    @Test
    func parsesDateOnlyString() {
        let parsedDate = parseAPIDate("2023-10-05")

        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = 2023
        components.month = 10
        components.day = 5
        let expectedDate = components.date

        #expect(parsedDate == expectedDate)
    }

    @Test
    func returnsNilForInvalidFormat() {
        #expect(parseAPIDate("not-a-date") == nil)
        #expect(parseAPIDate(nil) == nil)
        #expect(parseAPIDate("") == nil)
    }

    @Test
    func sortHelperFallsBackToDistantPast() {
        let validDate = parseAPIDateForSort("2024-05-01T00:00:00Z")
        let fallbackDate = parseAPIDateForSort("totally invalid")

        var formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let expectedDate = formatter.date(from: "2024-05-01T00:00:00Z")

        #expect(validDate == expectedDate)
        #expect(fallbackDate == .distantPast)
    }

    @Test
    func formatsStartOfDayUTCStringForAPI() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: -5)! // EST

        var components = DateComponents()
        components.year = 2023
        components.month = 12
        components.day = 25
        components.hour = 15
        components.minute = 45
        components.calendar = calendar

        let date = components.date!
        let apiString = getDateStringForAPI(date)

        var formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        var expectedComponents = DateComponents()
        expectedComponents.calendar = Calendar(identifier: .gregorian)
        expectedComponents.timeZone = formatter.timeZone
        expectedComponents.year = 2023
        expectedComponents.month = 12
        expectedComponents.day = 25
        let expectedString = formatter.string(from: expectedComponents.date!)

        #expect(apiString == expectedString)
    }
}
