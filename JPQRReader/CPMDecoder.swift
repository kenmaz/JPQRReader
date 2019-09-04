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

        while buff.count > 0 {
            var index = 0
            let tag = buff[index]
            index += 1
            guard let len = Int(buff[index], radix: 16) else { return nil }
            index += 1
            let appData = buff[index..<index + len]
            index += len
            print(tag, appData)
            let remain = buff[index..<buff.count]
            buff = Array(remain)
//            switch tag {
//            case "61":
//                //App template
//                break
//            case "62":
//                //Common template
//                break
//            default:
//                //Other template
//                break
//            }
        }
        return CPMEMV(format: format)
    }
}

struct CPMEMV {
    enum Format: String {
        case emv = "hQVDUFY"
        case jpqr = "hQVKUFFS"
    }
    let format: Format
}


