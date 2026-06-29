import SwiftUI

// MARK: - Document-style header

/// Mirrors the web's responsive catalogue item header.
/// - Compact (iPhone): artwork centered above, then title → credit → info below.
/// - Regular (iPad/macOS): title → credit → info on the left, artwork on the right.
struct CatalogueItemHeader<InfoContent: View>: View {

    let title: String
    var artworkURL: String? = nil
    var credit: String? = nil
    let info: InfoContent
    var resourceURLs: [String] = []

    @Environment(\.horizontalSizeClass) private var sizeClass

    init(
        title: String,
        artworkURL: String? = nil,
        credit: String? = nil,
        @ViewBuilder info: () -> InfoContent,
        resourceURLs: [String] = []
    ) {
        self.title = title
        self.artworkURL = artworkURL
        self.credit = credit
        self.info = info()
        self.resourceURLs = resourceURLs
    }

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
            info
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
