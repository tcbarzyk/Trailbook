//
//  LoadingState.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/14/25.
//

enum LoadingState {
    case idle
    case loading
    case success
    case error(error: Error)
}
