#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import PulseCore
import PulseDesign

/// Category tiles shown on Search before you type. Each opens the library with a ready-made filter.
struct BrowseTiles: View {
    private struct Category: Identifiable {
        let id: String
        let title: LocalizedStringKey
        let name: String
        let symbol: String
        let seed: Int
        let query: LibraryQuery
    }

    private var categories: [Category] {
        func make(_ id: String, _ title: LocalizedStringKey, _ name: String, _ symbol: String, _ seed: Int, _ edit: (inout LibraryQuery) -> Void) -> Category {
            var q = LibraryQuery()
            edit(&q)
            return Category(id: id, title: title, name: name, symbol: symbol, seed: seed, query: q)
        }
        return [
            make("added", "Recently added", "Recently added", "sparkles", 1) { $0.sort = .added },
            make("fav", "Favourites", "Favourites", "heart.fill", 4) { $0.favoritesOnly = true },
            make("watchlist", "Watchlist", "Watchlist", "bookmark.fill", 3) { $0.watchlistOnly = true },
            make("unwatched", "Unwatched", "Unwatched", "eye.slash.fill", 0) { $0.watched = .false },
            make("progress", "In progress", "In progress", "play.circle.fill", 5) { $0.watched = .inprogress },
            make("random", "Surprise me", "Surprise me", "dice.fill", 2) { $0.sort = .random },
            make("long", "Longest", "Longest", "hourglass", 7) { $0.sort = .duration },
            make("matched", "Matched", "Matched", "checkmark.seal.fill", 9) { $0.matched = true },
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse").font(PulseFont.title(.title3)).foregroundStyle(Theme.text)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(categories) { category in
                    NavigationLink(value: Route.filtered(title: category.name, query: category.query)) {
                        tile(category)
                    }
                    .buttonStyle(.pressable)
                    .pulseScrollReveal()
                }
            }
        }
        .padding(.horizontal, Theme.Space.page)
    }

    private func tile(_ category: Category) -> some View {
        Color.clear
            .frame(height: 112)
            .overlay { PosterArt(seed: category.seed) }
            .overlay { LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom) }
            .overlay(alignment: .topTrailing) {
                Image(systemName: category.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .pulseGlass(in: Circle())
                    .padding(10)
            }
            .overlay(alignment: .bottomLeading) {
                Text(category.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 1)
                    .padding(14)
            }
            .clipShape(.rect(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Theme.rim, lineWidth: 1))
    }
}
#endif
