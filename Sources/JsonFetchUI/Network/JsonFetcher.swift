//
//  Fetcher.swift
//  Star Wars Ships
//
//  Created by Geoff Burns on 16/9/21.
//


import Foundation
import Combine


public struct JsonFetcher {
    
    static let cache = CustomCache<String, Decodable>()
    static let shared = JsonFetcher()
    var decoder : JSONDecoder = JSONDecoder()
    
    var isCaching = true
    
    
    
    fileprivate func HttpSuccess<T>(_ data: Data, url: String) -> AnyPublisher<T, Publishers.Map<Publishers.MapError<Publishers.Decode<Just<JSONDecoder.Input>, T, JSONDecoder>, FetchError>, T>.Failure> {
        let decoder = DecoderWithDates()
        return Just(data)
            .decode(type: T.self, decoder: decoder)
            .mapError {error in .jsonError(error.localizedDescription)}
            .handleEvents(receiveOutput: {   data in
                if self.isCaching
                {
                //  cache data
                JsonFetcher.cache.insert(data, forKey: url)
                }
            })
            .eraseToAnyPublisher()
    }
    
    fileprivate func cachedValue(for url: String) -> Decodable? {
        return JsonFetcher.cache.value(forKey: url)
    }
    
    fileprivate func JustAny<T>(_ cachedValue: T) -> AnyPublisher<Result<T, FetchError>.Publisher.Output, FetchError> {
        return Just(cachedValue)
            // change AnyPublisher<T, Never> to AnyPublisher<T, FetchError>
            .mapError { _ in  FetchError.never }
            .eraseToAnyPublisher()
    }
    
    func fetch<T>(from url: String) -> AnyPublisher<T, FetchError> where T: Decodable {
  
        if isCaching {
          // check cache for data
          if let cachedValue = cachedValue(for: url) as? T
          {
            // return data from cache
            return JustAny(cachedValue)
          }
        }
        // fetch data if not in cache
        return URLSession.shared
            .dataTaskPublisher(for: URL(string: url)!)
            .receive(on: DispatchQueue.main)
            // url badly formed?
            .mapError { _ in .unknown }
            .flatMap { data, response -> AnyPublisher<T, FetchError> in
                if let response = response as? HTTPURLResponse {
                    if (200...299).contains(response.statusCode) {
                        // http success
                        return HttpSuccess(data, url: url)
                    } else {
                        // http failure
                        return Fail(error: FetchError.httpError(response.statusCode))
                            .eraseToAnyPublisher()
                    }
                }
                // url badly formed?
                return Fail(error: FetchError.unknown)
                        .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

 
}
