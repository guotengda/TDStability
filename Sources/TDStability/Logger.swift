//
//  Logger.swift
//  
//
//  Created by Sherlock on 2024/1/4.
//

import Foundation
import UIKit


/// A protocol for control all logers work or not
protocol LogGenerator: AnyObject {
    var enable: Bool { get set }
}

/// A protocol for object which need to show by logger.
public protocol Loggerable {
    var logDetail: String { get }
}

/// A enum for loger levels
///
/// - verbose: verbose level
/// - info: info level
/// - warning: warning level
/// - error: error level
public enum LogLevel: Int, Codable {
    case verbose, info, warning, error
    
    public var textColor: UIColor {
        switch self {
        case .verbose: return UIColor.lightGray
        case .info: return UIColor.cyan
        case .warning: return UIColor.yellow
        case .error: return UIColor.red
        }
    }
    
    public var logConsole: String {
        switch self {
        case .verbose: return "◽️"
        case .info: return "🔷"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

public func print(_ items: Any...) {
    if let items = items as? [Loggerable],  Logger.share.enable {
        Logger.handlerLog(items, level: LogLevel.error, file: nil, function: nil, line: nil)
    } else {
        Swift.print(items)
    }
}

/// A share instance for gengrate log infos
public class Logger: LogGenerator {
    
    /// Show log date or not
    public var showDate = true
    /// Show log fileInfo or not
    public var showFileInfo = true
    /// Log date formatter, 'yyyy-MM-dd HH:mm:ss' by defualt
    public var dateFormatter = DateFormatter.init().then {
        $0.timeZone = TimeZone.current
        $0.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    
    /// A closure for store log if you need, will call in Logger.share.queue
    /// SEE 'GSLogger'
    public var storeClosure: ((LogEntity) -> Void)? = nil
    
    public var enable: Bool = true
    public var level: LogLevel = .warning
    
    private let queue = DispatchQueue.init(label: "com.Sky-And-Hammer.ios.GS.log.queue")
    private let filePath = #file
    
    public static let share = Logger.init()
    
    /// Console a verbose level log
    public static func verbose(_ items: Loggerable..., file: String = #file, function: String = #function, line: Int = #line) {
        handlerLog(items, level: .verbose, file: file, function: function, line: line)
    }
    
    /// Console a info level log
    public static func info(_ items: Loggerable..., file: String = #file, function: String = #function, line: Int = #line) {
        handlerLog(items, level: .info, file: file, function: function, line: line)
    }
    
    /// Console a warning level log
    public static func warning(_ items: Loggerable..., file: String = #file, function: String = #function, line: Int = #line) {
        handlerLog(items, level: .warning, file: file, function: function, line: line)
    }
    
    /// Console a error level log
    public static func error(_ items: Loggerable..., file: String = #file, function: String = #function, line: Int = #line) {
        handlerLog(items, level: .error, file: file, function: function, line: line)
    }
    
    fileprivate static func handlerLog(_ items: [Loggerable], level: LogLevel, file: String?, function: String?, line: Int?) {
        guard Logger.share.enable else { return }
        guard Logger.share.level.rawValue <= level.rawValue else { return }
        
        let stringContent = items.map { $0.logDetail }.joined(separator: "\n")
        
        Logger.share.queue.async {
            let newLog = LogEntity.init(content: stringContent, level: level, module: moduleName(by: file), file: file, function: function, line: line)
            Logger.share.storeClosure?(newLog)
            Swift.print(newLog.debugDescription)
        }
    }
    
    private static func moduleName(by: String?) -> String? {
        guard let file = by else { return nil }
        
        let words = file.split(separator: "/")
        for i in 0..<words.count {
            if !Logger.share.filePath.contains(words[i]) { return String(words[i]) }
        }
        
        return "Unkonw Module"
    }
}

public struct LogEntity: Codable {
    
    public var id: Int64 = 0
    public var uuid = NSUUID().uuidString
    public let level: LogLevel
    public let moduleName: String?
    public let fileName: String?
    public let functionName: String?
    public let lineNumber: Int?
    public let fileInfo: String?
    public let content: String
    public var timestamp = Date()
    
    public init(content: String, level: LogLevel = .verbose, module: String? = nil, file: String? = nil, function: String? = nil, line: Int? = nil) {
        
        func parseFileInfo(file: String?, function: String?, line: Int?) -> String? {
            guard let file = file, let function = function, let line = line else { return nil }
            guard let fileName = file.components(separatedBy: "/").last else { return nil }
            
            return "\(fileName).\(function)[\(line)]"
        }
        
        self.content = content
        self.level = level
        self.moduleName = module
        self.fileName = file?.components(separatedBy: "/").last
        self.functionName = function
        self.lineNumber = line
        self.fileInfo = parseFileInfo(file: file, function: function, line: line)
    }
}

extension LogEntity: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        var value = level.logConsole
        if Logger.share.showDate { value.append("[\(Logger.share.dateFormatter.string(from: timestamp))]") }
        if Logger.share.showFileInfo { value.append(" \(fileInfo ?? "System print")") }
        value.append(": \n**********\(moduleName ?? "SYSTEM")**********\n")
        value.append(content)
        
        return value
    }
}

extension LogEntity: CustomStringConvertible {
    public var description: String { return debugDescription }
}

// MARK: Loggerable Extensions

extension String: Loggerable { public var logDetail: String { return self } }

