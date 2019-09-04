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
            let adfName: String
            let appLabel: [String]?
            let content: POIContent
            
            enum POIContent {
                case track2EquivalentData(Track2EquivalentData)
                case applicationPAN(String)
            }
            init?(input: [TLV]) {
                if let adfName = input.first(where: { $0.tag == "4f" })?.hexValue {
                    self.adfName = adfName.joined() //Not sure
                } else {
                    return nil
                }
                self.appLabel = input.first(where: { $0.tag == "50" })?.hexValue
            
                var content: POIContent? = nil
                if let val = input.first(where: { $0.tag == "57" })?.hexValue {
                    let data = Track2EquivalentData(payload: val)
                    content = .track2EquivalentData(data)
                } else if let val = input.first(where: { $0.tag == "5A" })?.hexValue {
                    content = .applicationPAN(val.joined())
                }
                if let content = content {
                    self.content = content
                } else {
                    return nil
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
        let commonData: [String]?
        let otherData: [[String]]
    }
}

extension CPMDecoder.CPMEMV: CustomStringConvertible {
    var description: String {
        return """
        Format: \(format)
        POI Data:
        \(poiDataList.map{ $0.description }.joined(separator: "\n"))
        CommonData: \(commonData?.description ?? "-")
        OtherData: \(otherData)
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
        return """
        ADF Name: \(adfName)
        \(content)
        """
    }
}
extension CPMDecoder.CPMEMV.POIData.POIContent: CustomStringConvertible {
    var description: String {
        switch self {
        case .applicationPAN(let pan):
            return "Application PAN: \(pan)"
        case .track2EquivalentData(let track2):
            return track2.description
        }
    }
}
extension CPMDecoder.CPMEMV.Track2EquivalentData: CustomStringConvertible {
    var description: String {
        return """
        [Track2]
        PAN: \(pan)
        ExpirationDate: \(expirationDate)
        ServiceCode: \(serviceCode)
        DiscretionaryDate: \(discretionaryData ?? "-")
        """
    }
}
