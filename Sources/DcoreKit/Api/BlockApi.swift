import Foundation
import RxSwift

public final class BlockApi: BaseApi {

    public func getBlockHeader(byBlockNum num: UInt64) -> Single<BlockHeader> {
        return GetBlockHeader(num).base.toResponse(api.core)
    }

    public func headBlockTime() -> Single<Date> {
        return HeadBlockTime().base.toResponse(api.core)
    }

    public func getBlock(byBlockNum num: UInt64) -> Single<SignedBlock> {
        return GetBlock(num).base.toResponse(api.core)
    }
}
