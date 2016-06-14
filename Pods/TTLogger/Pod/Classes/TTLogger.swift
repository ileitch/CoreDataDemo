import Foundation
import CocoaLumberjack


public func TTLogError(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, flag: .Error, file: file, function: function, line: line)
}

public func TTLogWarn(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, flag: .Warning, file: file, function: function, line: line)
}

public func TTLogInfo(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, flag: .Info, file: file, function: function, line: line)
}

public func TTLogDebug(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, flag: .Debug, file: file, function: function, line: line)
}

public func TTLogVerbose(message: String, file: String = #file, function: String = #function, line: Int = #line) {
    log(message, flag: .Verbose, file: file, function: function, line: line)
}

private func log(message: String, flag: DDLogFlag, file: String, function: String, line: Int) {
    TTLogger.log(true,
                 flag: Int32(flag.rawValue),
                 file: file,
                 function: function,
                 line: Int32(line),
                 message: message)
}