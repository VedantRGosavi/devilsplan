import Foundation
import os // For os.Logger, if we decide to use it more formally later.

enum LogLevel: String {
    case error = "[ERROR]"
    case warning = "[WARNING]"
    case info = "[INFO]"
    case debug = "[DEBUG]"
}

struct AppLogger {
    
    private static func log(level: LogLevel, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(Date()) \(level.rawValue) [\(fileName):\(line) \(function)] \(message)"
        print(logMessage)
        // For more advanced logging, one might use os.Logger here:
        // if #available(iOS 14.0, *) {
        //     let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.app", category: "general")
        //     switch level {
        //     case .error:
        //         logger.error("\(logMessage)")
        //     case .warning:
        //         logger.warning("\(logMessage)")
        //     case .info:
        //         logger.info("\(logMessage)")
        //     case .debug:
        //         logger.debug("\(logMessage)")
        //     }
        // } else {
        //     print(logMessage)
        // }
    }
    
    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .error, message: message, file: file, function: function, line: line)
    }
    
    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .warning, message: message, file: file, function: function, line: line)
    }
    
    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .info, message: message, file: file, function: function, line: line)
    }
    
    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(level: .debug, message: message, file: file, function: function, line: line)
    }
}
