import Foundation

public struct Options: Codable {
    
    public let memoKey: Address
    public let votingAccount: ChainObject
    public let numMiner: UInt16
    public var votes: Set<VoteId>
    public var extensions: AnyValue?
    public let allowSubscription: Bool
    public let pricePerSubscribe: AssetAmount
    public let subscriptionPeriod: UInt32
    
    private enum CodingKeys: String, CodingKey {
        case
        memoKey = "memo_key",
        votingAccount = "voting_account",
        numMiner = "num_miner",
        votes,
        extensions,
        allowSubscription = "allow_subscription",
        pricePerSubscribe = "price_per_subscribe",
        subscriptionPeriod = "subscription_period"
    }
    
    public init(from address: Address) {
        memoKey = address
        votingAccount = "1.2.3".dcore.chainObject!
        numMiner = 0
        votes = Set<VoteId>([])
        extensions = .array([])
        allowSubscription = false
        pricePerSubscribe = AssetAmount(0)
        subscriptionPeriod = 0
    }
    
    public func apply(votes: Set<VoteId>) -> Options {
        var options = self
        options.votes = votes
        return options
    }
}

extension Options: DataConvertible {
    public func asData() -> Data {
        var data = Data()
        data += memoKey.asData()
        data += votingAccount.asData()
        data += numMiner.littleEndian
        data += votes.asVoteData()
        data += Data.ofZero
        data += allowSubscription.asData()
        data += pricePerSubscribe.asData()
        data += subscriptionPeriod.littleEndian
        
        DCore.Logger.debug(crypto: "Options binary: %{private}s", args: {
            "\(data.toHex()) (\(data)) \(data.bytes)"
        })
        return data
    }
}
