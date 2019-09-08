//
//  CPMDecoder.swift
//  JPQRReader
//
//  Created by kenmaz on 2019/09/04.
//  Copyright © 2019 net.kenmaz. All rights reserved.
//

import Foundation

class CPMDecoder {
    func decode(payload: String) -> CPMEMV? {
        let prefix = String(payload.prefix(7))
        guard let format = CPMEMV.Format(rawValue: prefix) else {
            return nil
        }

        guard let bin = Data(base64Encoded: payload) else { return nil }
        var buff = Array(bin).map{ String($0, radix: 16) }
        buff = Array(buff[7..<buff.count])

        var poiDataList: [CPMEMV.POIData] = []
        var commonData: [CPMEMV.POIData] = []
        var otherDataList: [CPMEMV.POIData] = []
        let entries = TLV.buffToEntries(input: buff)
        entries?.forEach { tlv in
            switch tlv.tag {
            case .applicationTemplate:
                if let sub = TLV.buffToEntries(input: tlv.hexValue), let poiData = CPMEMV.POIData(input: sub) {
                    poiDataList.append(poiData)
                }
            case .commonDataTemplate:
                if let sub = TLV.buffToEntries(input: tlv.hexValue), let poiData = CPMEMV.POIData(input: sub) {
                    commonData.append(poiData)
                }
            default:
                if let sub = TLV.buffToEntries(input: tlv.hexValue), let poiData = CPMEMV.POIData(input: sub) {
                    otherDataList.append(poiData)
                }
            }
        }
        return CPMEMV(format: format, poiDataList: poiDataList, commonData: commonData, otherData: otherDataList)
    }
    struct TLV {
        let tag: Tag
        let hexValue: [String]
        
        enum Tag: String, CaseIterable {
            case adfName = "4f"
            case applicationLabel = "50"
            case applicationPAN = "5a"
            case applicationSpecificTransparentTemplate = "63"
            case applicationTemplate = "61"
            case applicationVersionNumber = "9f08"
            case commonDataTemplate = "62"
            case commonDataTransparentTemplate = "64"
            case cardholderName = "5f20"
            case issuerURL = "5f50"
            case last4DigitsOfPAN = "9f25"
            case languagePreference = "5f2d"
            case track2EquivalentData = "57"
            case tokenRequestorID = "9f19"
            case payloadFormatIndicator = "85"
            case paymentAccountReference = "9f24"
            case unknown = ""
        }
        
        static func buffToEntries(input: [String]) -> [TLV]? {
            var res: [TLV] = []
            var buff = input
            while buff.count > 0 {
                var index = 0
                let tag1 = buff[index]
                let tag2 = buff[index] + buff[index + 1]
                
                var emvTag: Tag? = nil
                for tag in Tag.allCases {
                    switch tag.rawValue {
                    case tag1:
                        emvTag = tag
                        index += 1
                        break
                    case tag2:
                        emvTag = tag
                        index += 2
                        break
                    default:
                        continue
                    }
                }
                let tag = emvTag ?? Tag.unknown
                
                guard let len = Int(buff[index], radix: 16) else { return nil }
                index += 1
                let appData = buff[index..<index + len]
                index += len
                res.append(.init(tag: tag, hexValue: Array(appData)))
                let remain = buff[index..<buff.count]
                buff = Array(remain)
            }
            return res
        }
    }
    struct CPMEMV {
        enum Format: String {
            case emv = "hQVDUFY"
            case jpqr = "hQVKUFFS"
        }
        let format: Format

        class POIData {
            var adfName: String?
            var appLabel: String?
            var track2EquivalentData: Track2EquivalentData?
            var applicationPAN: String?
            var applicationSpecificTransparentTemplate: [String]?
            var applicationTemplate: POIData?
            var applicationVersionNumber: String?
            var commonDataTemplate: POIData?
            var commonDataTransparentTemplate: [String]?
            var cardholderName: String?
            var issuerURL: String?
            var last4DigitsOfPAN: String?
            var languagePreference: String?
            var tokenRequestorID: String?
            var payloadFormatIndicator: String?
            var paymentAccountReference: String?
            var unknown: [String] = []

            init?(input: [TLV]) {
                input.forEach { tlv in
                    switch tlv.tag {
                    case .adfName:
                        adfName = tlv.hexValue.joined() //Not sure
                    case .applicationLabel:
                        let data = Data(hex: tlv.hexValue.joined())
                        appLabel = String(bytes: data, encoding: .utf8)
                    case .applicationPAN:
                        applicationPAN = tlv.hexValue.joined()
                    case .applicationSpecificTransparentTemplate:
                        applicationSpecificTransparentTemplate = tlv.hexValue
                    case .applicationTemplate:
                        if let sub = TLV.buffToEntries(input: tlv.hexValue) {
                            applicationTemplate = POIData(input: sub)
                        }
                    case .applicationVersionNumber:
                        applicationVersionNumber = tlv.hexValue.joined()
                    case .commonDataTemplate:
                        if let sub = TLV.buffToEntries(input: tlv.hexValue) {
                            commonDataTemplate = POIData(input: sub)
                        }
                    case .commonDataTransparentTemplate:
                        commonDataTransparentTemplate = tlv.hexValue
                    case .cardholderName:
                        let data = Data(hex: tlv.hexValue.joined())
                        cardholderName = String(bytes: data, encoding: .utf8)
                    case .issuerURL:
                        issuerURL = tlv.hexValue.joined()
                    case .last4DigitsOfPAN:
                        last4DigitsOfPAN = tlv.hexValue.joined()
                    case .languagePreference:
                        let data = Data(hex: tlv.hexValue.joined())
                        languagePreference = String(bytes: data, encoding: .utf8)
                    case .track2EquivalentData:
                        track2EquivalentData = Track2EquivalentData(payload: tlv.hexValue)
                    case .tokenRequestorID:
                        tokenRequestorID = tlv.hexValue.joined()
                    case .payloadFormatIndicator:
                        payloadFormatIndicator = tlv.hexValue.joined()
                    case .paymentAccountReference:
                        paymentAccountReference = tlv.hexValue.joined()
                    case .unknown:
                        unknown.append(tlv.hexValue.joined())
                    }
                }
            }
        }
        struct Track2EquivalentData {
            let pan: String
            let expirationDate: String
            let serviceCode: String
            let discretionaryData: String?
            
            init(payload: [String]) {
                let val = payload.map { chr in
                    if chr.count == 1 {
                        return "0\(chr)"
                    } else {
                        return chr
                    }
                }.joined()
                let comps = val.components(separatedBy: "d")
                self.pan = comps[0]
                var remain = Array(comps[1])
                self.expirationDate = String(remain.prefix(4))
                remain = Array(remain.suffix(from: 4))
                self.serviceCode = String(remain.prefix(3))
                remain = Array(remain.suffix(from: 3))
                self.discretionaryData = String(remain).components(separatedBy: "f").first
            }
        }
        let poiDataList: [POIData]
        let commonData: [POIData]
        let otherData: [POIData]
    }
}

extension CPMDecoder.CPMEMV: CustomStringConvertible {
    var description: String {
        var list: [String] = []
        list.append("Format: \(format)")
        poiDataList.forEach{ list.append("[Application]: \n\($0)") }
        commonData.forEach{ list.append("[Common Data]: \n\($0)") }
        otherData.forEach{ list.append("[Other Data] \n: \($0)")}
        return """
        ---------
        \(list.joined(separator: "\n"))
        ---------
        """
    }
}
extension CPMDecoder.CPMEMV.Format: CustomStringConvertible {
    var description: String {
        switch self {
        case .emv: return "EMV (CPM)"
        case .jpqr: return "JPQR (CPM)"
        }
    }
}
extension CPMDecoder.CPMEMV.POIData: CustomStringConvertible {
    var description: String {
        var list: [String] = []
        adfName.flatMap{ list.append("\tADF Name: \($0)") }
        appLabel.flatMap{ list.append("\tApplication Label: \($0)") }
        track2EquivalentData.flatMap{ list.append("\tTrack2 Equivalent Data: \n \($0)") }
        applicationPAN.flatMap{ list.append("\tApplication PAN: \($0)") }
        applicationSpecificTransparentTemplate.flatMap{
            list.append("\tApplication Specific Transparent Template: \($0.joined())") }
        applicationTemplate.flatMap{ list.append("\tApplication Template: \($0)") }
        applicationVersionNumber.flatMap{ list.append("\tApplication Version Number: \($0)") }
        commonDataTemplate.flatMap{ list.append("\tCommon Data Template: \($0)") }
        commonDataTransparentTemplate.flatMap{ list.append("\tCommon Data Transparent Template: \($0.joined())") }
        cardholderName.flatMap{ list.append("\tCardholder Name: \($0)") }
        issuerURL.flatMap{ list.append("\tIssuer URL: \($0)") }
        last4DigitsOfPAN.flatMap{ list.append("\tLast 4 Digits of PAN: \($0)") }
        languagePreference.flatMap{ list.append("\tLanguage Preference: \($0)") }
        tokenRequestorID.flatMap{ list.append("\tToken Requestor ID: \($0)") }
        payloadFormatIndicator.flatMap{ list.append("\tPayload Format Indicator: \($0)") }
        paymentAccountReference.flatMap{ list.append("\tPayment Account Reference: \($0)") }
        unknown.forEach{ list.append("\tUnknown: \($0)") }
        return list.joined(separator: "\n")
    }
}
extension CPMDecoder.CPMEMV.Track2EquivalentData: CustomStringConvertible {
    var description: String {
        return """
        \t\tPAN: \(pan)
        \t\tExpirationDate: \(expirationDate)
        \t\tServiceCode: \(serviceCode)
        \t\tDiscretionaryDate: \(discretionaryData ?? "-")
        """
    }
}
