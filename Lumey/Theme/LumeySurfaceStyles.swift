//
//  LumeySurfaceStyles.swift
//  Lumey
//

import SwiftUI

enum LumeyProgressStyle {
    static var fill: LinearGradient {
        LGradients.progress
    }

    static var track: Color {
        LColors.progressTrack
    }

    // Solid paused-state color rendered through the LinearGradient API for
    // backward compat with call sites that expect LinearGradient. Both stops
    // are identical so it renders flat — no gradients.
    static var pausedFill: LinearGradient {
        let c = LColors.text.muted
        return LinearGradient(colors: [c, c], startPoint: .leading, endPoint: .trailing)
    }

    static var pausedTrack: Color {
        LColors.progressTrack.opacity(0.78)
    }

    static var idleDot: Color {
        LColors.progressTrack
    }
}
