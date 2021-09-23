//
//  FetchViewModel.swift
//  Star Wars Ships
//
//  Created by Geoff Burns on 17/9/21.
//


import Foundation
import Combine
import SwiftUI

open class FetchViewModel: ObservableObject {
    var fetcher: JsonFetcher
    
    var cancellables : Set<AnyCancellable>
    
    public init()
    {
        fetcher = JsonFetcher.shared
        cancellables = Set<AnyCancellable>()
    }
    public func fetchData<T: Decodable>(url : String ) -> AnyPublisher<T, FetchError> {
        return fetcher.fetch(from: url)
            .eraseToAnyPublisher()
    }
    public func receiveCompletion(result : Subscribers.Completion< FetchError> )
    {
    switch result {
    case .failure(let error):
        print("Fetch Failed: \(error)")
    case .finished:
        break
    }
    }
    public func getData<T: Decodable>(url : String, responseHandler: @escaping (T) -> Void) {
        let cancellable = self.fetchData(url: url)
            .sink(receiveCompletion: self.receiveCompletion, receiveValue: responseHandler)
        
        cancellables.insert(cancellable)
    }
}
