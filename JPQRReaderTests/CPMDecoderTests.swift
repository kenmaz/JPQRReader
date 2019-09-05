//
//  CPMDecoderTests.swift
//  JPQRReaderTests
//
//  Created by kenmaz on 2019/09/04.
//  Copyright © 2019 net.kenmaz. All rights reserved.
//

import XCTest

class CPMDecoderTests: XCTestCase {

    func testEMVCPM_Example1() {
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
            XCTAssertEqual(track2.serviceCode, "201")
            XCTAssertEqual(track2.discretionaryData, "12345")
        default:
            XCTFail()
        }
    }

    func testEMVCPM_Example2() {
        let decoder = CPMDecoder()
        let payload = "hQVDUFYwMWETTwegAAAAVVVVUAhQcm9kdWN0MWETTwegAAAAZmZmUAhQcm9kdWN0MmJJWggSNFZ4kBI0WF8gDkNBUkRIT0xERVIvRU1WXy0IcnVlc2RlZW5kIZ8QBwYBCgMAAACfJghYT9OF+iNLzJ82AgABnzcEbVjvEw=="
        let res = decoder.decode(payload: payload)!
        print(res)
        XCTAssertEqual(res.format, CPMDecoder.CPMEMV.Format.emv)
        XCTAssertNil(res.poiDataList.first)
        XCTAssertNotNil(res.commonData)
    }

    func testMerpayCPM() {
        let payload = "hQVDUFYwMWEfTwigAAAAZQOSAlcTMViZAHkkKUPUkSEhAAAFEgAADw=="
        let decoder = CPMDecoder()
        let res = decoder.decode(payload: payload)!
        print(res)
    }
}
