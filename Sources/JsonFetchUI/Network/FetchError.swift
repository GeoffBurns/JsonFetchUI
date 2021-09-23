//
//  FetchError.swift
//  Star Wars Ships
//
//  Created by Geoff Burns on 16/9/21.
//

import Foundation

enum FetchError: Error { 
    case jsonError(String)      // parsing error / illegal JSON
    case httpError(Int)         // bad response from server
    case unknown                // url badly formed?
    case never                  // will never happen
}
