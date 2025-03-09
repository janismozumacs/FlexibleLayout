//
//  FlexibleLayoutCache.swift
//  FlexibleLayout
//
//  Created by Janis Mozumacs on 27/02/2025.
//

import SwiftUI

@available(iOS 16, *)
internal struct FlexibleLayoutCache {
    var layoutResult: FlexibleLayoutResult?
    
    var shouldReset: Bool = false
    var proposedContainerSize: ProposedViewSize?
    
    mutating func validate(forProposedContainer proposal: ProposedViewSize,
                           afterReset performUpdate: (inout Self) -> Void) {
        
        // If cache should reset, or container changed size
        if shouldReset || proposedContainerSize?.width != proposal.width {
            // reset cached layout
            layoutResult = nil
            
            // perform updated for the caller
            performUpdate(&self)
            
            // clean the cache
            shouldReset = false
            
            // remember the size proposal to compare during the next validation
            proposedContainerSize = proposal
        }
    }
}
