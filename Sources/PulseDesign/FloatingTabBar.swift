#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

public struct FloatingTabItem<Tab: Hashable>: Identifiable {
    public let tab: Tab
    public let title: LocalizedStringKey
    public let icon: String
    public var badge: Int?
    public var id: Tab { tab }

    public init(_ tab: Tab, title: LocalizedStringKey, icon: String, badge: Int? = nil) {
        self.tab = tab; self.title = title; self.icon = icon; self.badge = badge
    }
}

/// Floating glass capsule. The selected tab grows into a mint pill with its label and glides between tabs.
public struct FloatingTabBar<Tab: Hashable>: View {
    let items: [FloatingTabItem<Tab>]
    @Binding var selection: Tab
    @Namespace private var pill

    public init(items: [FloatingTabItem<Tab>], selection: Binding<Tab>) {
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(items) { item in
                let selected = item.tab == selection
                Button {
                    guard !selected else { return }
                    withAnimation(Theme.glide) { selection = item.tab }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: item.icon)
                            .font(.system(size: 19, weight: .semibold))
                            .symbolVariant(selected ? .fill : .none)
                            .symbolEffect(.bounce, value: selected)
                        if selected {
                            Text(item.title)
                                .font(.system(size: 14, weight: .bold))
                                .lineLimit(1)
                                .fixedSize()
                                .transition(.blurReplace.combined(with: .opacity))
                        }
                    }
                    .foregroundStyle(selected ? Theme.onAccent : Theme.textSecondary)
                    .padding(.horizontal, selected ? 18 : 0)
                    .frame(minWidth: 46, minHeight: 50)
                    .background {
                        if selected {
                            Capsule().fill(Theme.gradient)
                                .overlay(Capsule().fill(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .top, endPoint: .center)).blendMode(.overlay))
                                .shadow(color: Theme.accent.opacity(0.55), radius: 14, y: 4)
                                .matchedGeometryEffect(id: "pill", in: pill)
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if let badge = item.badge, badge > 0 {
                            Text("\(min(badge, 99))")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(minWidth: 17, minHeight: 17)
                                .background(Theme.ember, in: Capsule())
                                .offset(x: 4, y: -2)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(item.title))
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .background(.black.opacity(0.45), in: Capsule())
        .pulseCapsuleGlass()
        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
        .sensoryFeedback(.selection, trigger: selection)
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }
}
#endif
