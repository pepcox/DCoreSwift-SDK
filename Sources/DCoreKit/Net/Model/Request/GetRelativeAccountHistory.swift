import Foundation

struct GetRelativeAccountHistory: BaseRequestConvertible {
    
    typealias Output = [OperationHistory]
    private(set) var base: BaseRequest<[OperationHistory]>
    
    init(_ accountId: ChainObject, stop: UInt64 = 0, limit: UInt64 = 100, start: UInt64 = 0) {
        
        precondition(accountId.objectType == .accountObject, "Not a valid account object id")
        self.base = GetRelativeAccountHistory.toBase(
            .history,
            api: "get_relative_account_history",
            returnType: [OperationHistory].self,
            params: [
                accountId, stop, max(0, min(100, limit)), start
            ]
        )
    }
}
