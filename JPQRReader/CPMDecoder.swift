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
        var commonData: [String]?
        var otherDataList: [[String]] = []
        let entries = TLV.buffToEntries(input: buff)
        entries?.forEach { tlv in
            switch tlv.tag {
            case "61":
                if let sub = TLV.buffToEntries(input: tlv.hexValue), let poiData = CPMEMV.POIData(input: sub) {
                    poiDataList.append(poiData)
                }
            case "62":
                commonData = tlv.hexValue
            default:
                otherDataList.append(tlv.hexValue)
            }
        }
        return CPMEMV(format: format, poiDataList: poiDataList, commonData: commonData, otherData: otherDataList)
    }
    struct TLV {
        let tag: String
        let hexValue: [String]
        static func buffToEntries(input: [String]) -> [TLV]? {
            var res: [TLV] = []
            var buff = input
            while buff.count > 0 {
                var index = 0
                let tag = buff[index]
                index += 1
                guard let len = Int(buff[index], radix: 16) else { return nil }
                index += 1
                let appData = buff[index..<index + len]
                index += len
                print(tag, appData)
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
        
        struct POIData {
            let adfName: [String]
            let appLabel: [String]?
            let content: POIContent
            
            enum POIContent {
                case track2EquivalentData([String])
                case applicationPAN([String])
            }
            init?(input: [TLV]) {
                if let adfName = input.first(where: { $0.tag == "4f" })?.hexValue {
                    self.adfName = adfName
                } else {
                    return nil
                }
                self.appLabel = input.first(where: { $0.tag == "50" })?.hexValue
            
                var content: POIContent? = nil
                if let val = input.first(where: { $0.tag == "57" })?.hexValue {
                    content = .track2EquivalentData(val)
                } else if let val = input.first(where: { $0.tag == "5A" })?.hexValue {
                    content = .applicationPAN(val)
                }
                if let content = content {
                    self.content = content
                } else {
                    return nil
                }
            }
        }
        let poiDataList: [POIData]
        let commonData: [String]?
        let otherData: [[String]]
    }
}

