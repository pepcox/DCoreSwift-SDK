import Foundation

class GetRequiredFees: BaseRequest<[AssetAmount]> {
    
    required init(operations: [BaseOperation], assetId: ChainObject = DCore.Constant.Default.dct) {
        guard assetId.objectType == ObjectType.assetObject else { preconditionFailure("not a valid asset object id") }
        super.init(.database, api: "get_required_fees", returnClass: [AssetAmount].self, params: [
            operations.map({ RequiredFee($0) }), assetId
        ])
    }
}