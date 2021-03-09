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

public func BonjourLogExtra(_ str: String) {
    BonjourLogger.shared.log(str, level: .extra)
}

public class BonjourLogger {
    public static let shared = BonjourLogger()
    public var mode: Mode = .none
    
    public enum Mode {
        case none
        case quiet
        case verbose
        case extraVerbose
    }
    
    public enum Level {
        case debug
        case warning
        case error
        case extra
    }

    public func log(_ str: String, level: Level) {
        var needsToPrint: Bool
        switch level {
        case .extra:
            needsToPrint = mode == .extraVerbose
        case .debug:
            needsToPrint = mode == .verbose || mode == .extraVerbose
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
