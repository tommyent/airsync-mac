//
//  PlaybackState.swift
//  airsync-mac
//
//  Created by Sameera Sandakelum on 2026-06-04.
//

import Foundation
import Observation

@Observable
class PlaybackState {
    static let shared = PlaybackState()
    
    var mediaPosition: Double = 0
    var activeCallDurationSec: Int = 0
    
    private init() {}
}
