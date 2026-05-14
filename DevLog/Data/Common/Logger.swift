//
//  Logger.swift
//  DevLog
//
//  Created by 최윤진 on 2/12/26.
//

import Foundation
import os.log

public final class Logger {
    private let subsystem: String
    private let category: String
    private let osLog: OSLog
    
    public init(subsystem: String = Bundle.main.bundleIdentifier ?? "DevLog", category: String) {
        self.subsystem = subsystem
        self.category = category
        self.osLog = OSLog(subsystem: subsystem, category: category)
    }

    public func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, type: .debug, file: file, function: function, line: line)
    }
    
    public func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, type: .info, file: file, function: function, line: line)
    }
    
    public func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, type: .default, file: file, function: function, line: line)
    }
    
    public func error(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error)"
        }
        log(fullMessage, type: .error, file: file, function: function, line: line)
    }
    
    public func fault(
        _ message: String,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        var fullMessage = message
        if let error = error {
            fullMessage += " | Error: \(error)"
        }
        log(fullMessage, type: .fault, file: file, function: function, line: line)
    }

    private func log(
        _ message: String,
        type: OSLogType,
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(fileName):\(line)] \(function) - \(message)"
        
        #if DEBUG
        os_log("%{public}@", log: osLog, type: type, logMessage)
        #else
        os_log("%{private}@", log: osLog, type: type, logMessage)
        #endif
    }
}
