//
//  BonjourLogger.swift
//  bonjour-http
//
//  Created by SATOSHI NAKAJIMA on 1/18/21.
//

import Foundation

public func BonjourLogError(_ str: String) {
    BonjourLogger.shared.log(str, level: .error)
}

public func BonjourLogWarning(_ str: String) {
    BonjourLogger.shared.log(str, level: .warning)
}

public func BonjourLog(_ str: String) {
    BonjourLogger.shared.log(str, level: .debug)
}

class BonjourLogger {
    static let shared = BonjourLogger()
    var mode: Mode = .none
    
    enum Mode {
        case none
        case quiet
        case verbose
    }
    
    enum Level {
        case debug
        case warning
        case error
    }

    public func log(_ str: String, level: Level) {
        var needsToPrint: Bool
        switch level {
        case .debug:
            needsToPrint = mode == .verbose
        case .warning:
            needsToPrint = mode != .quiet
        case .error:
            needsToPrint = true
        }
        if needsToPrint {
            print(str)
        }
    }
}
