import Foundation

public struct RegionalPrice: Codable {
    
    public let price: AssetAmount
    public let region: Int
    
    private enum CodingKeys: String, CodingKey {
        case
        price,
        region
    }
}

extension RegionalPrice: DataSerializable {
    public var serialized: Data {
        var data = Data()
        data += region
        data += price
        return data
    }
}

public struct PricePerRegion: Codable {
    
    public let prices: [Int:AssetAmount]
    
    private enum CodingKeys: String, CodingKey {
        case
        prices = "map_price"
    }
}

public enum Regions {
    
    public static let NULL: Regions = Regions.code("null", 0)
    public static let NONE: Regions = Regions.code("", 1)
    public static let ALL: Regions = Regions.code("default", 2)
    
    case code(String, Int)
    
    public var id: Int {
        switch self {
        case let .code(_, value): return value
        }
    }
    
    public var code: String {
        switch self {
        case let .code(value, _): return value
        }
    }
    
}