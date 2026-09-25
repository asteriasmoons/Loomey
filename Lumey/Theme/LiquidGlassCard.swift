//
//  LiquidGlassCard.swift
//  Lumey
//
//  Standard card surface for the app. Uses iOS 26 Liquid Glass
//  (`.glassEffect`) and falls back to a tinted material on earlier OSes.
//  New Liquid Glass cards in Lumey should go through this component so a
//  theme change updates the whole surface language in one place.
//

import SwiftUI

struct LiquidGlassCard<Content: View>: View {
    enum Emphasis {
        case regular
        case elevated
        case tinted(Color)
    }

    @Environment(\.appTheme) private var theme

    var emphasis: Emphasis
    var cornerRadius: CGFloat?
    var padding: CGFloat?
    var content: () -> Content

    init(
        emphasis: Emphasis = .regular,
        cornerRadius: CGFloat? = nil,
        padding: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.emphasis = emphasis
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content
    }

    var body: some View {
        let radius = cornerRadius ?? theme.metrics.cornerCard
        let pad = padding ?? theme.metrics.cardVPadding

        content()
            .padding(.horizontal, theme.metrics.cardHPadding)
            .padding(.vertical, pad)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                surface(radius: radius)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(theme.palette.raisedSurface, lineWidth: 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    @ViewBuilder
    private func surface(radius: CGFloat) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)

        if #available(iOS 26.0, *) {
            switch emphasis {
            case .regular:
                shape.fill(.clear)
                    .glassEffect(.regular, in: shape)
            case .elevated:
                shape.fill(.clear)
                    .glassEffect(.regular.interactive(), in: shape)
            case .tinted(let color):
                shape.fill(.clear)
                    .glassEffect(.regular.tint(color), in: shape)
            }
        } else {
            switch emphasis {
            case .regular:
                shape.fill(theme.palette.surface)
            case .elevated:
                shape.fill(theme.palette.raisedSurface)
            case .tinted(let color):
                shape.fill(color)
            }
        }
    }
}
