//
//  MPMDecoder.swift
//  JPQRReader
//
//  Created by kenmaz on 2019/09/04.
//  Copyright © 2019 net.kenmaz. All rights reserved.
//

import Foundation

class MPMDecoder {
    struct JPQR: CustomStringConvertible {
        struct MerchantAccountInformation: CustomStringConvertible {
            let globallyUniqueIdentifier: String
            let unifiedMerchantIdentifier: UnifiedMerchantIdentifier
            struct UnifiedMerchantIdentifier {
                let level1: String
                let level2: String
                let level3: String
                let level4: String
            }
            init?(payload: String) {
                guard let entries = TLV.stringToTLVEntries(string: payload) else { return nil }
                if let val = entries["00"] {
                    globallyUniqueIdentifier = val
                } else {
                    return nil
                }
                if let level1 = entries["01"],
                    let level2 = entries["02"],
                    let level3 = entries["03"],
                    let level4 = entries["04"] {
                    unifiedMerchantIdentifier = .init(level1: level1, level2: level2, level3: level3, level4: level4)
                } else {
                    return nil
                }
            }
            var description: String {
                return """
                GUID: \(globallyUniqueIdentifier)
                管理レベル1: \(unifiedMerchantIdentifier.level1)
                管理レベル2: \(unifiedMerchantIdentifier.level2)
                管理レベル3: \(unifiedMerchantIdentifier.level3)
                管理レベル4: \(unifiedMerchantIdentifier.level4)
                """
            }
        }

        let root: Root

        init?(payload: String) {
            guard let root = Root(payload: payload) else { return nil }
            self.root = root
        }

        var description: String {
            return root.description
        }
    }

    enum MerchantAccountInformation: CustomStringConvertible {
        case visa(String)
        case mastercard(String)
        case emvco(String)
        case discover(String)
        case amex(String)
        case jcb(String)
        case unionpay(String)
        case jpqr(JPQR.MerchantAccountInformation)
        case unknown(String)

        var description: String {
            switch self {
            case .visa(let val): return "VISA \(val)"
            case .mastercard(let val): return "MasterCard \(val)"
            case .emvco(let val): return "EMVCo \(val)"
            case .discover(let val): return "Discover \(val)"
            case .amex(let val): return "Amex \(val)"
            case .jcb(let val): return "JCB \(val)"
            case .unionpay(let val): return "UnionPay \(val)"
            case .jpqr(let info): return """
                [[JPQR]]
                \(info)
                """
            case .unknown(let val): return "Unknown \(val)"
            }
        }
    }

    struct MerchantInformationLanguageTemplate: CustomStringConvertible {
        let languagePreference: String
        let merchantName: String
        let merchantCity: String?

        init?(payload: String) {
            guard let entries = TLV.stringToTLVEntries(string: payload) else { return nil }
            if let val = entries["00"] {
                languagePreference = val
            } else {
                return nil
            }
            if let val = entries["01"] {
                merchantName = val
            } else {
                return nil
            }
            merchantCity = entries["02"]
        }

        var description: String {
            return """
            使用言語: \(languagePreference)
            契約店名: \(merchantName)
            契約店名: \(merchantCity ?? "-")
            """
        }
    }

    enum PointofInitiationMethod: String, CustomStringConvertible {
        case `static` = "11"
        case dynamic = "12"

        var description: String {
            switch self {
            case .static: return "静的MPM"
            case .dynamic: return "動的MPM"
            }
        }
    }

    struct Root: CustomStringConvertible {
        let payloadFormatIndicator: String
        let pointofInitiationMethod: PointofInitiationMethod?
        let merchantAccountInformation: MerchantAccountInformation
        let merchantCategoryCode: String
        let transactionCurrency: String
        let transactionAmount: String? //C TODO:enum
        let tipOrConvenienceIndicator: String?
        let valueOfConvenienceFeeFixed: String? //C
        let valueOfConvenienceFeePercentage: String? //C
        let countryCode: String
        let merchantName: String
        let merchantCity: String
        let postalCode: String?
        let additionalDataFieldTemplate: String?
        let merchantInformationLanguageTemplate: MerchantInformationLanguageTemplate?
        //let RFUForEMVCo: String?
        //let unreservedTemplates: String?
        //let crc: String

        init?(payload: String) {
            guard let entries = TLV.stringToTLVEntries(string: payload) else { return nil }
            if let str = entries["00"] {
                payloadFormatIndicator = str
            } else {
                return nil
            }

            if let str = entries["01"] {
                let  val = PointofInitiationMethod(rawValue: str)
                pointofInitiationMethod = val
            } else {
                return nil
            }

            func range(range: ClosedRange<Int>) -> String? {
                for i in range {
                    let id = String(format: "%2d", i)
                    if let str = entries[id] {
                        return str
                    }
                }
                return nil

            }
            if let val = range(range: 2...3) {
                merchantAccountInformation = .visa(val)
            } else if let val = range(range: 4...5) {
                merchantAccountInformation = .visa(val)
            } else if let val = range(range: 6...8) {
                merchantAccountInformation = .emvco(val)
            } else if let val = range(range: 9...10) {
                merchantAccountInformation = .discover(val)
            } else if let val = range(range: 11...12) {
                merchantAccountInformation = .amex(val)
            } else if let val = range(range: 13...14) {
                merchantAccountInformation = .jcb(val)
            } else if let val = range(range: 15...16) {
                merchantAccountInformation = .unionpay(val)
            } else if let val = range(range: 17...25) {
                merchantAccountInformation = .emvco(val)
            } else if let val = range(range: 26...26) {
                if let jpqrInfo = MPMDecoder.JPQR.MerchantAccountInformation(payload: val) {
                    merchantAccountInformation = .jpqr(jpqrInfo)
                } else {
                    return nil
                }
            } else if let val = range(range: 27...51) {
                merchantAccountInformation = .unknown(val)
            } else {
                return nil
            }

            if let str = entries["52"] {
                merchantCategoryCode = str
            } else {
                return nil
            }
            if let str = entries["53"] {
                transactionCurrency = str
            } else {
                return nil
            }
            if let str = entries["54"] {
                transactionAmount = str
            } else {
                transactionAmount = nil
            }
            if let str = entries["55"] {
                tipOrConvenienceIndicator = str
            } else {
                tipOrConvenienceIndicator = nil
            }
            if let str = entries["56"] {
                valueOfConvenienceFeeFixed = str
            } else {
                valueOfConvenienceFeeFixed = nil
            }
            if let str = entries["57"] {
                valueOfConvenienceFeePercentage = str
            } else {
                valueOfConvenienceFeePercentage = nil
            }
            if let str = entries["58"] {
                countryCode = str
            } else {
                return nil
            }
            if let str = entries["59"] {
                merchantName = str
            } else {
                return nil
            }
            if let str = entries["60"] {
                merchantCity = str
            } else {
                return nil
            }
            if let str = entries["61"] {
                postalCode = str
            } else {
                postalCode = nil
            }
            if let str = entries["62"] {
                additionalDataFieldTemplate = str
            } else {
                additionalDataFieldTemplate = nil
            }
            if let str = entries["64"] {
                merchantInformationLanguageTemplate = MerchantInformationLanguageTemplate(payload: str)
            } else {
                merchantInformationLanguageTemplate = nil
            }
        }
        var description: String {
            return """
            仕様バージョン: \(payloadFormatIndicator)
            静的/動的フラグ: \(pointofInitiationMethod?.description ?? "-")
            ■契約店情報
            \(merchantAccountInformation)
            業種: \(merchantCategoryCode)
            取引通貨: \(transactionCurrency)
            取引金額: \(transactionAmount ?? "-")
            国コード: \(countryCode)
            契約店名: \(merchantName)
            契約店郵便番号: \(merchantCity)
            ■契約店情報(Localized)
            \(merchantInformationLanguageTemplate?.description ?? "-")
            """
        }
    }

    func decode(payload: String) -> JPQR? {
        return JPQR(payload: payload)
    }
}

struct TLV {
    typealias ID = String
    typealias Value = String

    private static let idLength = 2
    private static let lengthLength = 2

    static func stringToTLVEntries(string: String) -> [ID: Value]? {
        var entries: [ID: Value] = [:]
        var buff = Array(string)
        while buff.count > 0 {
            var index = 0
            let id = String(buff[index..<index + idLength])
            index += idLength
            guard let lenght = Int(String(buff[index..<index + lengthLength])) else { return nil }
            index += lengthLength
            let value = String(buff[index..<index + lenght])
            index += lenght
            let remain = buff[index..<buff.count]
            buff = Array(remain)
            entries[id] = value
        }
        return entries
    }
}

