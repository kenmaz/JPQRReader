//
//  JPQRReaderTests.swift
//  JPQRReaderTests
//
//  Created by kenmaz on 2019/09/04.
//  Copyright © 2019 net.kenmaz. All rights reserved.
//

import XCTest

class JPQRReaderTests: XCTestCase {

    func test() {
        let decoder = JPQRDecoder()
        guard let res = decoder.decode(payload: "00020164210002JA0111JPQRMPM本舗食堂53033925903xxx6003xxx610710600325802JP01021126680019jp.or.paymentsjapan0113000000000000102040001030600000104060000015204412163046D60") else {
            XCTFail()
            return
        }
        print(res)
    }
}
