import SwiftUI

// MARK: - Document-style header

/// Mirrors the web's responsive catalogue item header.
/// - Compact (iPhone): artwork centered above, then title → credit → info below.
/// - Regular (iPad/macOS): title → credit → info on the left, artwork on the right.
struct CatalogueItemHeader: View {

    let title: String
    var artworkURL: String? = nil
    var credit: String? = nil
    var info: String? = nil
    var resourceURLs: [String] = []

    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular {
                HStack(alignment: .top, spacing: 16) {
                    textContent
                    artworkImage
                        .frame(width: 130, height: 130)
                }
                .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    artworkImage
                        .frame(maxWidth: 200)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                    textContent
                }
                .padding(.vertical, 8)
            }

            ForEach(resourceURLs, id: \.self) { urlString in
                if let url = URL(string: urlString) {
                    Link(url.host ?? urlString, destination: url)
                }
            }
        }
    }

    @ViewBuilder
    private var artworkImage: some View {
        if let artworkURL, let url = URL(string: artworkURL) {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Rectangle()
                    .fill(.secondary.opacity(0.12))
                    .aspectRatio(1, contentMode: .fit)
            }
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
            if let credit {
                Text(credit)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            if let info, !info.isEmpty {
                Text(info)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
