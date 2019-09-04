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
        XCTAssertEqual(res.format, CPMEMV.Format.emv)

    }
}
