//
//  JPQRReaderTests.swift
//  JPQRReaderTests
//
//  Created by kenmaz on 2019/09/04.
//  Copyright © 2019 net.kenmaz. All rights reserved.
//

import XCTest

class MPMDecoderTests: XCTestCase {

    func test() {
        let decoder = MPMDecoder()
        guard let res = decoder.decode(payload: "00020164210002JA0111JPQRMPM本舗食堂53033925903xxx6003xxx610710600325802JP01021126680019jp.or.paymentsjapan0113000000000000102040001030600000104060000015204412163046D60") else {
            XCTFail()
            return
        }
        //print(res)
        let root = res.root
        XCTAssertEqual(root.payloadFormatIndicator, "01")
        XCTAssertEqual(root.pointofInitiationMethod, MPMDecoder.PointofInitiationMethod.static)
        XCTAssertEqual(root.merchantCategoryCode, "4121")
        XCTAssertEqual(root.transactionCurrency, "392")
        XCTAssertEqual(root.transactionAmount, nil)
        XCTAssertEqual(root.tipOrConvenienceIndicator, nil)
        XCTAssertEqual(root.valueOfConvenienceFeeFixed, nil)
        XCTAssertEqual(root.valueOfConvenienceFeePercentage, nil)
        XCTAssertEqual(root.countryCode, "JP")
        XCTAssertEqual(root.merchantName, "xxx")
        XCTAssertEqual(root.merchantCity, "xxx")
        XCTAssertEqual(root.postalCode, "1060032")

        switch root.merchantAccountInformation {
        case .jpqr(let info):
            XCTAssertEqual(info.globallyUniqueIdentifier, "jp.or.paymentsjapan")
            XCTAssertEqual(info.unifiedMerchantIdentifier.level1, "0000000000001")
            XCTAssertEqual(info.unifiedMerchantIdentifier.level2, "0001")
            XCTAssertEqual(info.unifiedMerchantIdentifier.level3, "000001")
            XCTAssertEqual(info.unifiedMerchantIdentifier.level4, "000001")
        default:
            XCTFail()
        }

        let localizedInfo = root.merchantInformationLanguageTemplate!
        XCTAssertEqual(localizedInfo.languagePreference, "JA")
        XCTAssertEqual(localizedInfo.merchantName, "JPQRMPM本舗食堂")
        XCTAssertEqual(localizedInfo.merchantCity, nil)
    }
}
