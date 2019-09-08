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
        let track2 = poiData.track2EquivalentData!
        XCTAssertEqual(track2.pan, "1234567890123458")
        XCTAssertEqual(track2.expirationDate, "1912")
        XCTAssertEqual(track2.serviceCode, "201")
        XCTAssertEqual(track2.discretionaryData, "12345")
    }

    func testEMVCPM_Example2() {
        let decoder = CPMDecoder()
        let payload = "hQVDUFYwMWETTwegAAAAVVVVUAhQcm9kdWN0MWETTwegAAAAZmZmUAhQcm9kdWN0MmJJWggSNFZ4kBI0WF8gDkNBUkRIT0xERVIvRU1WXy0IcnVlc2RlZW5kIZ8QBwYBCgMAAACfJghYT9OF+iNLzJ82AgABnzcEbVjvEw=="
        let res = decoder.decode(payload: payload)!
        print(res)
        XCTAssertEqual(res.format, CPMDecoder.CPMEMV.Format.emv)
        let product1 = res.poiDataList[0]
        XCTAssertEqual(product1.adfName, "a0000555555")
        XCTAssertEqual(product1.appLabel, "Product1")
        let product2 = res.poiDataList[1]
        XCTAssertEqual(product2.adfName, "a0000666666")
        XCTAssertEqual(product2.appLabel, "Product2")
        let common = res.commonData[0]
        XCTAssertEqual(common.applicationPAN, "1234567890123458")
        XCTAssertEqual(common.commonDataTransparentTemplate?.joined(), "9f10761a30009f268584fd385fa234bcc9f362019f3746d58ef13")
        XCTAssertEqual(common.cardholderName, "CARDHOLDER/EMV")
        XCTAssertEqual(common.languagePreference, "ruesdeen")
    }

    func testMerpayCPM() {
        let payload = "hQVDUFYwMWEfTwigAAAAZQOSAlcTMViZAHkkKUPUkSEhAAAFEgAADw=="
        let decoder = CPMDecoder()
        let res = decoder.decode(payload: payload)!
        print(res)
        let poiData = res.poiDataList.first!
        XCTAssertEqual(poiData.adfName!, "a0000653922")
        let t2 = poiData.track2EquivalentData!
        XCTAssertEqual(t2.pan, "3158990079242943")
        XCTAssertEqual(t2.expirationDate, "4912")
        XCTAssertEqual(t2.serviceCode, "121")
        XCTAssertEqual(t2.discretionaryData, "0000051200000")
    }
}
