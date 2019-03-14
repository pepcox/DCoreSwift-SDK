import Foundation
import RxSwift

public protocol AccountApi: BaseApi {
    func getAccount(byName name: String) -> Single<Account>
    func getAccount(byId id: ChainObject) -> Single<Account>
    func getAccounts(byIds ids: [ChainObject]) -> Single<[Account]>
    func getAccountIds(byAddressList list: [Address]) -> Single<[[ChainObject]]>
    func existAccount(byName name: String) -> Single<Bool>
    func existAccount(byId id: ChainObject) -> Single<Bool>
    func getAccount(byReference ref: Account.Reference) -> Single<Account>
    func search(accountHistory accoundId: ChainObject,
                from: ChainObject,
                order: SearchOrder.AccountHistory,
                limit: Int) -> Single<[TransactionDetail]>
    func create(credentialsByName name: String, wif: String) -> Single<Credentials>
    func create(credentialsByName name: String, encryptedWif wif: String, passphrase: String) -> Single<Credentials>
    func getFullAccounts(byReferences refs: [Account.Reference], subscribe: Bool) -> Single<[String: FullAccount]>
    func getAccountReferences(byId id: ChainObject) -> Single<[ChainObject]>
    func lookupAccounts(byNames names: [String]) -> Single<[Account]>
    func lookupAccounts(byLowerBound bound: String, limit: Int) -> Single<[String: ChainObject]>
    func search(accountsByTerm term: String,
                order: SearchOrder.Accounts,
                id: ChainObject,
                limit: Int) -> Single<[Account]>
    func getAccountCount() -> Single<UInt64>
    func create(_ account: SubmitAccount, registrar: Credentials, fee: AssetAmount) -> Single<TransactionConfirmation>
}

extension AccountApi {
    
    public func getAccount(byName name: String) -> Single<Account> {
        return GetAccountByName(name).base.toResponse(api.core)
    }
    
    public func getAccount(byId id: ChainObject) -> Single<Account> {
        return getAccounts(byIds: [id]).map { try $0.first.orThrow(DCoreException.network(.notFound)) }
    }
    
    public func getAccounts(byIds ids: [ChainObject]) -> Single<[Account]> {
        return GetAccountById(ids).base.toResponse(api.core)
    }
    
    public func getAccountIds(byAddressList list: [Address]) -> Single<[[ChainObject]]> {
        return GetKeyReferences(list).base.toResponse(api.core)
    }
    
    public func existAccount(byName name: String) -> Single<Bool> {
        return getAccount(byName: name).map({ _ in true }).catchErrorJustReturn(false)
    }
    
    public func existAccount(byId id: ChainObject) -> Single<Bool> {
        return getAccount(byId: id).map({ _ in true }).catchErrorJustReturn(false)
    }

    public func getAccount(byReference ref: Account.Reference) -> Single<Account> {
        return Single.deferred({
            
            if let id = ref.dcore.chainObject {
                return self.getAccounts(byIds: [id]).map({ try $0.first.orThrow(DCoreException.network(.notFound)) })
            }
            
            if Account.hasValid(name: ref) {
                return self.getAccount(byName: ref)
            }
            
            return Single.error(DCoreException.unexpected("Value \(ref) is not a valid account reference"))
        })
    }
    
    public func search(accountHistory accoundId: ChainObject,
                       from: ChainObject = ObjectType.nullObject.genericId,
                       order: SearchOrder.AccountHistory = .timeDesc,
                       limit: Int = 100) -> Single<[TransactionDetail]> {
        return SearchAccountHistory(accoundId, order: order, startId: from, limit: limit).base.toResponse(api.core)
    }
    
    public func create(credentialsByName name: String, wif: String) -> Single<Credentials> {
        return self.getAccount(byName: name).map({ try Credentials($0.id, wif: wif) })
    }
    
    public func create(credentialsByName name: String, encryptedWif wif: String, passphrase: String) -> Single<Credentials> {
        return self.getAccount(byName: name).map({ try Credentials($0.id, encryptedWif: wif, passphrase: passphrase) })
    }
    
    public func getFullAccounts(byReferences refs: [Account.Reference], subscribe: Bool = false) -> Single<[String: FullAccount]> {
        return GetFullAccounts(refs, subscribe: subscribe).base.toResponse(api.core)
    }
    
    public func getAccountReferences(byId id: ChainObject) -> Single<[ChainObject]> {
        return GetAccountReferences(id).base.toResponse(api.core)
    }
    
    public func lookupAccounts(byNames names: [String]) -> Single<[Account]> {
        return LookupAccountNames(names).base.toResponse(api.core)
    }
    
    public func lookupAccounts(byLowerBound bound: String, limit: Int = 1000) -> Single<[String: ChainObject]> {
        return LookupAccounts(bound, limit: limit).base.toResponse(api.core)
    }
    
    public func search(accountsByTerm term: String,
                       order: SearchOrder.Accounts = .nameDesc,
                       id: ChainObject = ObjectType.nullObject.genericId,
                       limit: Int = 1000) -> Single<[Account]> {
        
        return SearchAccounts(term, order: order, id: id, limit: limit).base.toResponse(api.core)
    }
    
    public func getAccountCount() -> Single<UInt64> {
        return GetAccountCount().base.toResponse(api.core)
    }
    
    public func create(_ account: SubmitAccount, registrar: Credentials, fee: AssetAmount = .unset) -> Single<TransactionConfirmation> {
        return existAccount(byName: account.name).flatMap { result in
            guard !result else { return Single.error(DCoreException.network(.alreadyFound)) }
            return self.api.broadcast.broadcast(withCallback: registrar.keyPair, operation: AccountCreateOperation(
                account, registrar: registrar.accountId, fee: fee
                )
            )
        }
    }
}

extension ApiProvider: AccountApi {}
