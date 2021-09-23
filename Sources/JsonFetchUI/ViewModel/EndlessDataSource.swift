//
//  EndlessDataSource.swift
//  Star Wars Ships
//
//  Created by Geoff Burns on 19/9/21.
//
import SwiftUI
import Combine
import Utilities


/**Custom decoder for dates*/
open class DecoderWithDates: JSONDecoder {
    public override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }
}
open class EndlessDataSource<T : Equatable, TResponse : Decodable>: ObservableObject {
    public var fetcher: JsonFetcher
    @Published public var items = [T]()
    @Published public var isLoadingPage = false
    
    public init()
    {
        fetcher = JsonFetcher()
        fetcher.decoder  = DecoderWithDates()
    }
    
    var canLoadMorePages : Bool { !urlOfNextPage.isEmpty }
    
    public var urlOfNextPage = ""
    
    var cancellables = Set<AnyCancellable>()
    
    open func getItems(response :TResponse ) -> [T]
    {
        return undefined("getItem not overriden")
    }
    open func getUrlOfNextPage(response :TResponse ) -> String
    {
        return undefined("getUrlOfNextPage not overriden")
    }
    func NoOp(_ value: T?)
    {
        
    }
    public func loadMoreContent() {
        guard !isLoadingPage && canLoadMorePages else {
          NoOp(nil)
          return
        }

        isLoadingPage = true
        
        let cancellable = fetcher.fetch(from: urlOfNextPage)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print("Fetch Failed: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [self] (response : TResponse) in
                if(self.items.count==1)
                {
                self.items = self.getItems(response: response)
                }
                else
                {
                self.items += self.getItems(response: response)
                }
                self.urlOfNextPage = self.getUrlOfNextPage(response: response)
                self.isLoadingPage = false
        })
        
        cancellables.insert(cancellable)
      }
    
  
    public func loadMoreContentIfNeeded(currentItem item: T?) {
      guard let item = item else {
        loadMoreContent()
        return
      }

      let thresholdIndex = items.index(items.endIndex, offsetBy: -5)
        if items.firstIndex(where: { $0 == item }) == thresholdIndex {
        loadMoreContent()
      }
    }

    
}
