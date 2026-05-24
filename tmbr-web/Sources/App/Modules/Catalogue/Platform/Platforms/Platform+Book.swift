extension Platform where M == BookMetadata {

    static var book: Platform<BookMetadata> {
        Platform(platforms: [
            Platform(name: "GoodReads", checker: .goodreads, extractor: .goodreads)
        ])
    }
}
