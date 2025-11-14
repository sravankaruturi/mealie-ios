//
//  DateFormatterTests.swift
//  mealIO
//
//  Created by Sravan Karuturi on 11/12/25.
//

// This file is to store all the tests run for the DateFormatter Extensions

import Testing
import Foundation
@testable import mealIO

struct DateFormatterTests {

    @Test
    func mealieDisplayDateFormat() {
        var comps = DateComponents()
        comps.year = 2025
        comps.month = 12
        comps.day = 11
        comps.calendar = Calendar(identifier: .gregorian)
        let date = comps.date!

        let expectedFormat = "Dec 11, 2025"
        #expect(DateFormatter.mealieDisplay.string(from: date) == expectedFormat)
    }

}
