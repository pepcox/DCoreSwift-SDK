import Foundation

/**
 NFT specification must conform to this protocol.
 Its properties can be converted to array of `NftDataType`, for `NftCreateOperation`.
 Properties of model conforming to `NftModel` can use `NftProperty` property wrapper to specify further parameters of a given property.
 Data types conforming to `NftModel` must be `public`.
 */
public protocol NftModel: Codable {
    init()
}

private func convertToAnyEncodable(any: Any) -> AnyEncodable? {
    guard let encodable = (any as? Encodable) else { return nil }
    return AnyEncodable(encodable)
}

extension NftModel {
    func values() throws -> [AnyValue] {
        return try Mirror(reflecting: self).children
            .map { $0.value }
            .compactMap(convertToAnyEncodable)
            .map { try JSONEncoder.codingContext().encode($0) }
            .map { try JSONDecoder.codingContext().decode(AnyValue.self, from: $0) }
    }

    func createDefinitions() -> [NftDataType] {
        return Mirror(reflecting: self).children.map { child in
            switch child.value {
            case let property as NftProperty<String>: return property.asNftDataType(name: child.label)
            case let property as NftProperty<Int>: return property.asNftDataType(name: child.label)
            case let property as NftProperty<UInt8>: return property.asNftDataType(name: child.label)
            case let property as NftProperty<UInt32>: return property.asNftDataType(name: child.label)
            case let property as NftProperty<UInt64>: return property.asNftDataType(name: child.label)
            case let property as NftProperty<Bool>: return property.asNftDataType(name: child.label)
            default:
                return NftDataType(
                    type: getTypeLiteral(value: child.value), unique: false, modifiable: .nobody, name: child.label
                )
            }
        }
    }
}

private func getTypeLiteral(value: Any) -> NftDataType.TypeLiteral {
    switch value {
    case is Int, is UInt8, is UInt32, is UInt64: return .integer
    case is Bool: return .boolean
    case is String: return .string
    default: preconditionFailure("Unsupported type \(value.self)")
    }
}

private extension NftProperty {
    func asNftDataType(name: String?) -> NftDataType {
        return NftDataType(
            type: getTypeLiteral(value: wrappedValue), unique: unique, modifiable: modifiableBy, name: name
        )
    }
}
