import Foundation

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L123
// int_msg_info$0 ihr_disabled:Bool bounce:Bool bounced:Bool
//  src:MsgAddressInt dest:MsgAddressInt
//  value:CurrencyCollection ihr_fee:Grams fwd_fee:Grams
//  created_lt:uint64 created_at:uint32 = CommonMsgInfo;
// ext_in_msg_info$10 src:MsgAddressExt dest:MsgAddressInt
//  import_fee:Grams = CommonMsgInfo;
// ext_out_msg_info$11 src:MsgAddressInt dest:MsgAddressExt
//  created_lt:uint64 created_at:uint32 = CommonMsgInfo;

enum CommonMessageInfoType: String {
    case `internal` = "internal"
    case externalOut = "external-out"
    case externalIn = "external-in"
}

enum CommonMessageInfo {
    case internalInfo(info: CommonMessageInfoInternal)
    case externalOutInfo(info: CommonMessageInfoExternalOut)
    case externalInInfo(info: CommonMessageInfoExternalIn)
    
    static func loadCommonMessageInfo(slice: Slice) throws -> CommonMessageInfo {
        // Internal message
        if !(try slice.loadBit()) {
            let ihrDisabled = try slice.loadBit()
            let bounce = try slice.loadBit()
            let bounced = try slice.loadBit()
            let src = try slice.loadAddress()
            let dest = try slice.loadAddress()
            let value = try loadCurrencyCollection(slice: slice)
            let ihrFee = try slice.loadCoins()
            let forwardFee = try slice.loadCoins()
            let createdLt = try slice.loadUintBig(bits: 64)
            let createdAt = try slice.loadUint(bits: 32)
            
            return CommonMessageInfo.internalInfo(
                info: .init(
                    ihrDisabled: ihrDisabled,
                    bounce: bounce,
                    bounced: bounced,
                    src: src,
                    dest: dest,
                    value: value,
                    ihrFee: ihrFee,
                    forwardFee: forwardFee,
                    createdLt: createdLt,
                    createdAt: createdAt
                )
            )
        }
        
        // External In message
        if !(try slice.loadBit()) {
            let src = try slice.loadMaybeExternalAddress()
            let dest = try slice.loadAddress()
            let importFee = try slice.loadCoins()
            
            return CommonMessageInfo.externalInInfo(
                info: .init(
                    src: src,
                    dest: dest,
                    importFee: importFee
                )
            )
        }
        
        // External Out mesage
        let src = try slice.loadAddress()
        let dest = try slice.loadMaybeExternalAddress()
        let createdLt = try slice.loadUintBig(bits: 64)
        let createdAt = try slice.loadUint(bits: 32)
        
        return CommonMessageInfo.externalOutInfo(
            info: .init(
                src: src,
                dest: dest,
                createdLt: createdLt,
                createdAt: createdAt
            )
        )
    }
    
    static func storeCommonMessageInfo(source: CommonMessageInfo, builder: Builder) throws -> Builder {
        switch source {
        case .internalInfo(let info):
            try builder.storeBit(false)
            try builder.storeBit(info.ihrDisabled)
            try builder.storeBit(info.bounce)
            try builder.storeBit(info.bounced)
            try builder.storeAddress(address: info.src)
            try builder.storeAddress(address: info.dest)
            try builder.store(storeCurrencyCollection(collection: info.value, builder: builder))
            try builder.storeCoins(coins: info.ihrFee)
            try builder.storeCoins(coins: info.forwardFee)
            try builder.storeUint(info.createdLt, bits: 64)
            try builder.storeUint(info.createdAt, bits: 32)
            
        case .externalOutInfo(let info):
            try builder.storeBit(true)
            try builder.storeBit(true)
            try builder.storeAddress(address: info.src)
            try builder.storeAddress(address: info.dest)
            try builder.storeUint(info.createdLt, bits: 64)
            try builder.storeUint(info.createdAt, bits: 32)
            
        case .externalInInfo(let info):
            try builder.storeBit(true)
            try builder.storeBit(false)
            try builder.storeAddress(address: info.src)
            try builder.storeAddress(address: info.dest)
            try builder.storeCoins(coins: info.importFee)
        }
        
        return builder
    }
}

struct CommonMessageInfoInternal {
    let type: CommonMessageInfoType = .internal
    let ihrDisabled: Bool
    let bounce: Bool
    let bounced: Bool
    let src: Address
    let dest: Address
    let value: CurrencyCollection
    let ihrFee: Coins
    let forwardFee: Coins
    let createdLt: UInt32
    let createdAt: UInt32
}

struct CommonMessageInfoExternalIn {
    let type: CommonMessageInfoType = .externalIn
    let src: ExternalAddress?
    let dest: Address
    let importFee: Coins
}

struct CommonMessageInfoExternalOut {
    let type: CommonMessageInfoType = .externalOut
    let src: Address
    let dest: ExternalAddress?
    let createdLt: UInt32
    let createdAt: UInt32
}