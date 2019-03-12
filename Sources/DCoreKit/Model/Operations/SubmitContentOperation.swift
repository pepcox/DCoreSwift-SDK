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
    public var quorum: Int {
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
    
    public init<Input>(_ content: SubmitContent<Input>,
                       credentials: Credentials,
                       publishingFee: AssetAmount = .unset,
                       fee: AssetAmount = .unset) where Input: SynopsisConvertible {
        self.init(content,
                  author: credentials.accountId,
                  publishingFee: publishingFee,
                  fee: fee)
    }
    
    public init<Input>(_ content: SubmitContent<Input>,
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
        data += Data.ofZero
        data += uri.asData()
        data += quorum
        data += price.asData()
        data += hash.unhex().asData()
        data += seeders.asData()
        data += keyParts.asData()
        data += Int(expiration.timeIntervalSince1970)
        data += publishingFee.asData()
        data += synopsis.asData()
        data += custodyData.asOptionalData()
        
        DCore.Logger.debug(crypto: "SubmitContentOperation binary: %{private}s", args: {
            "\(data.toHex()) (\(data)) \(data.bytes)"
        })
        return data
    }
}

extension UInt64 {
    fileprivate static let unset: UInt64 = 1
}

extension Int {
    fileprivate static let unset: Int = 0
}

public enum SubmitContent<Input> where Input: SynopsisConvertible {
    
    fileprivate var uri: String {
        switch self {
        case .cdnMultiPaid(let uri, _, _, _, _): return uri
        case .cdnPaid(let uri, _, _, _): return uri
        case .cdn(let uri, _, _): return uri
        }
    }
    
    fileprivate var hash: String {
        switch self {
        case .cdnMultiPaid(let uri, _, _, _, _): return CryptoUtils.ripemd160(uri.asEncoded()).toHex()
        case .cdnPaid(let uri, _, _, _): return CryptoUtils.ripemd160(uri.asEncoded()).toHex()
        case .cdn(let uri, _, _): return CryptoUtils.ripemd160(uri.asEncoded()).toHex()
        }
    }
    
    fileprivate var expiration: Date {
        switch self {
        case .cdnMultiPaid(_, let expiration, _, _, _): return expiration
        case .cdnPaid(_, let expiration, _, _): return expiration
        case .cdn(_, let expiration, _): return expiration
        }
    }
    
    fileprivate var price: [RegionalPrice] {
        switch self {
        case .cdnMultiPaid(_, _, let price, _, _): return [RegionalPrice(price)]
        case .cdnPaid(_, _, let price, _): return [RegionalPrice(price)]
        case .cdn(_, _, _): return [.unset] // swiftlint:disable:this empty_enum_arguments
        }
    }
    
    fileprivate var synopsis: String {
        switch self {
        case .cdnMultiPaid(_, _, _, let synopsis, _): return synopsis.asJson().or("")
        case .cdnPaid(_, _, _, let synopsis): return synopsis.asJson().or("")
        case .cdn(_, _, let synopsis): return synopsis.asJson().or("")
        }
    }
    
    fileprivate func coauthors(without author: ChainObject) -> [Pair<ChainObject, Int>]? {
        switch self {
        case .cdnMultiPaid(_, _, _, _, let coauthors):
            precondition(coauthors.allSatisfy { $0.first != author }, "Author can't be part of co-authors")
            return coauthors
        default: return nil
        }
    }
    
    fileprivate var quorum: Int { return .unset }
    fileprivate var size: UInt64 { return .unset }
    fileprivate var seeders: [ChainObject] { return [] }
    fileprivate var keyParts: [KeyParts] { return [] }
    
    case
    cdnMultiPaid(uri: String, expiration: Date, price: AssetAmount, synopsis: Input, coauthors: [Pair<ChainObject, Int>]),
    cdnPaid(uri: String, expiration: Date, price: AssetAmount, synopsis: Input),
    cdn(uri: String, expiration: Date, synopsis: Input)
}
