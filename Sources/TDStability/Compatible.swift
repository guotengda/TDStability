//
//  Compatible.swift
//  
//
//  Created by Sherlock on 2024/1/4.
//

import Foundation


extension Compatible {
    public var td: TD<Self> { get { return TD(self) } }
}

/// extension Use 'TD' to manager instance methods
/// For example:
///
///     extension String: Compatible {}
///
///     extension TD where Base == String {
///
///         /// String's length
///         public var length: Int {
///             return base.characters.count
///         }
///     }
public protocol Compatible {
    
    associatedtype CompatibleType
    var td: CompatibleType { get }
}

public final class TD<Base> {
    
    /// wrapped instance object
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
