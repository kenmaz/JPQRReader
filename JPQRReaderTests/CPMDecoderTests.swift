//
//  CPMDecoderTests.swift
//  JPQRReaderTests
//
//  Created by kenmaz on 2019/09/04.
//  Copyright © 2019 net.kenmaz. All rights reserved.
//

import XCTest

class CPMDecoderTests: XCTestCase {

    func test() {
        let decoder = CPMDecoder()
        let payload = "hQVDUFYwMWEaTwegAAAAVVVVVw8SNFZ4kBI0WNGRIgESNF8="
        let res = decoder.decode(payload: payload)!
        print(res)
        XCTAssertEqual(res.format, CPMDecoder.CPMEMV.Format.emv)
        let poiData = res.poiDataList.first!
        XCTAssertEqual(poiData.adfName, "a0000555555")
        switch poiData.content {
        case .track2EquivalentData(let track2):
            XCTAssertEqual(track2.pan, "1234567890123458")
            XCTAssertEqual(track2.expirationDate, "1912")
            XCTAssertEqual(track2.serviceCode, "211")
            XCTAssertEqual(track2.discretionaryData, "2345")
        default:
            XCTFail()
        }

    }
}
