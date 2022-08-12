//
// Copyright (c) 2021 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import func Darwin.fputs

/// Provides control over SDK logging.
public enum Logging {
    /// Indicates whether to enable printing to the console.
    public static var isEnabled: Bool = false
}

@_spi(AdyenInternal)
public func adyenPrint(_ items: Any..., separator: String = " ", terminator: String = "\n", fileId: String = #fileID) {
    guard Logging.isEnabled else { return }
    let moduleName = fileId.split(separator: "/").first ?? "AdyenNetworking"
    
    var items = items
    items.insert("[\(moduleName)]", at: 0)
    items.insert(ISO8601DateFormatter().string(from: Date()), at: 0)
    
    var idx = items.startIndex
    let endIdx = items.endIndex
    
    repeat {
        Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
        idx += 1
    } while idx < endIdx
}

@_spi(AdyenInternal)
public func adyenPrintAsJSON(_ dictionary: [String: Any]) {
    guard Logging.isEnabled else { return }
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: jsonOptions())
        adyenPrintAsJSON(jsonData)
    } catch {
        adyenPrint(dictionary)
    }
}

@_spi(AdyenInternal)
public func adyenPrintAsJSON(_ data: Data) {
    guard Logging.isEnabled else { return }
    do {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: jsonOptions())
        guard let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        adyenPrint(jsonString)
    } catch {
        if let string = String(data: data, encoding: .utf8) {
            adyenPrint(string)
        }
    }
}

private func jsonOptions() -> JSONSerialization.WritingOptions {
    if #available(iOS 13.0, *) {
        return [.prettyPrinted, .withoutEscapingSlashes]
    } else {
        return [.prettyPrinted]
    }
}
