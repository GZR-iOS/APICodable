//
//  NWUrlEncoder.swift
//
//  Created by DươngPQ on 04/01/2019.
//  Copyright © 2019 GMO-Z.com RunSystem. All rights reserved.
//

import Foundation

/// Encode Model by its key-path
public class NWKeyPathEncoder: Encoder {

    public var codingPath = [CodingKey]()
    public var userInfo = [CodingUserInfoKey : Any]()
    public weak var delegate: NWKeyPathEncoderDelegate!

    var keyPath = NWKeyPath()

    public init(_ owner: NWKeyPathEncoderDelegate) {
        delegate = owner
    }

    public init() {

    }

    init(parent: NWKeyPathEncoder) {
        delegate = parent.delegate
    }

    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(NWKeyPathKeyedEncodingContainer<Key>(owner: self))
    }

    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return NWKeyPathUnkeyedEncodingContainer(owner: self)
    }

    public func singleValueContainer() -> SingleValueEncodingContainer {
        return NWKeyPathSingleValueEncodingContainer(owner: self)
    }

}
