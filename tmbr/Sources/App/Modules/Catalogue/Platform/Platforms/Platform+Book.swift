extension Platform where M == Void {

    static var book: Platform<Void> {
        Platform(platforms: [
            Platform(name: "GoodReads", checker: .goodreads)
        ])
    }
}
