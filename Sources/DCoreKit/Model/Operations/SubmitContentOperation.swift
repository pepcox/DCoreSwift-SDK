import Foundation
import BigInt

public struct SubmitContentOperation: Operation {
    public var author: ChainObject {
        willSet { precondition(newValue.objectType == .accountObject, "Not an account object id") }
    }
    public var uri: String {
        willSet { precondition(Content.hasValid(uri: newValue), "Invalid uri scheme") }
    }
    public var expiration: Date {
        willSet { precondition(newValue > Date(), "Invalid expiration") }
    }
    
    public let price: [RegionalPrice]
    public let synopsis: String

    public var hash: String {
        willSet { precondition(newValue.unhex()?.count == 20, "Invalid hash, should be 40 chars, hex encoded") }
    }
    public var quorum: UInt32 {
        willSet { precondition(newValue >= .unset, "Invalid seeders count") }
    }
    public var size: UInt64 {
        willSet { precondition(newValue > 0, "Invalid file size") }
    }
    public let seeders: [ChainObject]
    public let keyParts: [KeyParts]
    public var coauthors: [Pair<ChainObject, Int>]?
    public var custodyData: CustodyData?
    public let publishingFee: AssetAmount
    public var fee: AssetAmount  = .unset
    public let type: OperationType = .contentSubmitOperation
    
    init<Input>(_ content: SubmitContent<Input>,
                author: Credentials,
                publishingFee: AssetAmount = .unset,
                fee: AssetAmount = .unset) where Input: SynopsisConvertible {
        self.init(content,
                  author: author.accountId,
                  publishingFee: publishingFee,
                  fee: fee)
    }
    
    init<Input>(_ content: SubmitContent<Input>,
                author: ChainObject,
                publishingFee: AssetAmount = .unset,
                fee: AssetAmount = .unset) where Input: SynopsisConvertible {
        self.author = author
        self.uri = content.uri
        self.expiration = content.expiration
        self.price = content.price
        self.synopsis = content.synopsis
        self.hash = content.hash
        self.quorum = content.quorum
        self.size = content.size
        self.seeders = content.seeders
        self.keyParts = content.keyParts
        self.coauthors = content.coauthors(without: author)
        
        self.fee = fee
        self.publishingFee = publishingFee
    }
    
    private enum CodingKeys: String, CodingKey {
        case
        size,
        author,
        coauthors = "co_authors",
        uri = "URI",
        quorum,
        price,
        hash,
        seeders,
        keyParts = "key_parts",
        expiration,
        publishingFee = "publishing_fee",
        synopsis,
        custodyData = "cd",
        fee
    }
}

extension SubmitContentOperation {
    public func decrypt(_ keyPair: ECKeyPair, address: Address? = nil, nonce: BigInt = CryptoUtils.generateNonce()) throws -> SubmitContentOperation {
        return self
    }
}

extension SubmitContentOperation {
    public func asData() -> Data {
        
        var data = Data()
        data += type.asData()
        data += fee.asData()
        data += size.littleEndian
        data += author.asData()
        data += serializeCoAuthors()
        data += uri.asData()
        data += quorum
        data += price.asData()
        data += hash.unhex().or(Data.ofZero)
        data += seeders.asData()
        data += keyParts.asData()
        data += Int32(expiration.timeIntervalSince1970).littleEndian
        data += publishingFee.asData()
        data += synopsis.asData()
        data += custodyData.asOptionalData()
        
        DCore.Logger.debug(crypto: "SubmitContentOperation binary: %{private}s", args: {
            "\(data.toHex()) (\(data)) \(data.bytes)"
        })
        return data
    }

    private func serializeCoAuthors() -> Data {
        guard let coauthors = coauthors else { return Data.ofZero }
        var data = Data()
        data += UInt64(coauthors.count).asUnsignedVarIntData()
        coauthors.forEach {
            data += $0.first.asData()
            data += UInt32($0.second).littleEndian
        }
        return data
    }
}

extension UInt64 {
    fileprivate static let unset: UInt64 = 1
}

extension UInt32 {
    fileprivate static let unset: UInt32 = 0
}

extension Int {
    fileprivate static let unset: Int = 0
}

extension URLConvertible {
    fileprivate var uri: String {
        return (asURL()?.absoluteString).or("")
    }
    
    fileprivate var hash: String {
        return CryptoUtils.ripemd160(uri.asEncoded()).toHex()
    }
}

public enum SubmitContent<Input> where Input: SynopsisConvertible {
    
    var uri: String {
        switch self {
        case .cdnWithSharedPrice(let url, _, _, _, _): return url.uri
        case .cdnWithPrice(let url, _, _, _): return url.uri
        case .cdn(let url, _, _): return url.uri
        }
    }
    
    fileprivate var hash: String {
        switch self {
        case .cdnWithSharedPrice(let url, _, _, _, _): return url.hash
        case .cdnWithPrice(let url, _, _, _): return url.hash
        case .cdn(let url, _, _): return url.hash
        }
    }
    
    fileprivate var expiration: Date {
        switch self {
        case .cdnWithSharedPrice(_, let expiration, _, _, _): return expiration
        case .cdnWithPrice(_, let expiration, _, _): return expiration
        case .cdn(_, let expiration, _): return expiration
        }
    }
    
    fileprivate var price: [RegionalPrice] {
        switch self {
        case .cdnWithSharedPrice(_, _, let price, _, _): return [RegionalPrice(price)]
        case .cdnWithPrice(_, _, let price, _): return [RegionalPrice(price)]
        case .cdn: return [.unset]
        }
    }
    
    fileprivate var synopsis: String {
        switch self {
        case .cdnWithSharedPrice(_, _, _, let synopsis, _): return synopsis.asJson().or("")
        case .cdnWithPrice(_, _, _, let synopsis): return synopsis.asJson().or("")
        case .cdn(_, _, let synopsis): return synopsis.asJson().or("")
        }
    }
    
    fileprivate func coauthors(without author: ChainObject) -> [Pair<ChainObject, Int>]? {
        switch self {
        case .cdnWithSharedPrice(_, _, _, _, let coauthors):
            precondition(coauthors.allSatisfy { $0.first != author }, "Author can't be part of co-authors")
            return coauthors
        default: return nil
        }
    }
    
    fileprivate var quorum: UInt32 { return .unset }
    fileprivate var size: UInt64 { return .unset }
    fileprivate var seeders: [ChainObject] { return [] }
    fileprivate var keyParts: [KeyParts] { return [] }
    
    case
    cdnWithSharedPrice(url: URLConvertible, expiration: Date, price: AssetAmount, synopsis: Input, coauthors: [Pair<ChainObject, Int>]),
    cdnWithPrice(url: URLConvertible, expiration: Date, price: AssetAmount, synopsis: Input),
    cdn(url: URLConvertible, expiration: Date, synopsis: Input)
}
