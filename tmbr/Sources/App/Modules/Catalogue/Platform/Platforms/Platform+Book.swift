extension Platform<Book> {
    
    static let all = Platform(platforms: [
        .goodreads
    ])
    
    static let goodreads = Platform(displayName: "GoodReads", parser: .goodreads)
}
