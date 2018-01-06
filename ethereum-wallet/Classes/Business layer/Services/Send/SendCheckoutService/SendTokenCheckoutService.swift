//
//  SendTokenCheckout.swift
//  ethereum-wallet
//
//  Created by Artur Guseinov on 06/01/2018.
//  Copyright © 2018 Artur Guseinov. All rights reserved.
//

import Foundation

class SendTokenCheckoutService: SendCheckoutServiceProtocol {
  
  func checkout(for coin: CoinDisplayable, amount: Decimal, iso: String, fee: Decimal) throws -> SendCheckout {
    guard let rate = coin.rates.first(where: {$0.to == iso}) else {
        throw SendCheckoutError.noRate
    }
    let feeAmount = Ether(fee)
    let localFeeAmount = fee.etherToLocal(rate: rate.value).fromWei()
    let localAmount = amount // + Local amount
    let totalAmountDecimal = amount.localToEther(rate: rate.value).toWei() + fee
    let totalAmount = coin.balance.tokenValue(with: totalAmountDecimal)
    return SendCheckout(localAmount: localAmount, totalAmount: totalAmount, localFeeAmount: localFeeAmount, feeAmount: feeAmount, iso: iso)
  }
  
}