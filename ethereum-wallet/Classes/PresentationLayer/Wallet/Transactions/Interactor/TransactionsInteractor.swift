// ethereum-wallet https://github.com/flypaper0/ethereum-wallet
// Copyright (C) 2018 Artur Guseinov
//
// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of  MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
// more details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <http://www.gnu.org/licenses/>.


import Foundation


class TransactionsInteractor {
  weak var output: TransactionsInteractorOutput!
  
  var transactionsNetworkService: TransactionsNetworkServiceProtocol!
  var transactionsDataStoreService: TransactionsDataStoreServiceProtocol!
  var tokenTransactionsNetworkService: TokenTransactionsNetworkServiceProtocol!
  var tokenTransactionsDataStoreService: TokenTransactionsDataStoreServiceProtocol!
  var transactionIndexDataStoreService: TxIndexDataStoreServiceProtocol!
  var walletDataStoreService: WalletDataStoreServiceProtocol!
  
  private func groupTransactions(_ transactions: [TxIndex]) {
    DispatchQueue.global().async {
      var sections = [Date: [TxIndex]]()
      for tx in transactions {
        let time = Calendar.current.startOfDay(for: tx.time)
        if sections.index(forKey: time) == nil {
          sections[time] = [tx]
        } else {
          sections[time]?.append(tx)
        }
      }
      
      let sortedSections = sections.keys.sorted(by: { $0 > $1 })
      DispatchQueue.main.async { [unowned self] in
        self.output.didReceiveSections(sections, sortedSections: sortedSections)
      }
    }
  }
  
}


// MARK: - TransactionsInteractorInput

extension TransactionsInteractor: TransactionsInteractorInput {
  
  func getTxIndex() {
    transactionIndexDataStoreService.observe { [unowned self] transactions in
      self.groupTransactions(transactions)
    }
  }
  
  func getWallet() {
    walletDataStoreService.observe { [unowned self] wallet in
      self.output.didReceiveWallet(wallet)
    }
  }
  
  func loadTransactions() {
    updateTransactions()
    updateTokenTransactions()
  }

  private func updateTokenTransactions() {
    let wallet = walletDataStoreService.getWallet()
    tokenTransactionsNetworkService.getTokenTransactions(address: wallet.address) { [unowned self] result in
      switch result {
      case .success(var transactions):
        self.tokenTransactionsDataStoreService.markAndSaveTransactions(&transactions, address: wallet.address)
        self.output.didReceiveTransactions()
      case .failure(let error):
        self.output.didFailedTransactionsReceiving(with: error)
      }
    }
  }
  
  private func updateTransactions() {
    let wallet = walletDataStoreService.getWallet()
    transactionsNetworkService.getTransactions(address: wallet.address) { [unowned self] result in
      switch result {
      case .success(var transactions):
        self.transactionsDataStoreService.markAndSaveTransactions(&transactions, address: wallet.address)
        self.output.didReceiveTransactions()
      case .failure(let error):
        self.output.didFailedTransactionsReceiving(with: error)
      }
    }
  }
  
}

