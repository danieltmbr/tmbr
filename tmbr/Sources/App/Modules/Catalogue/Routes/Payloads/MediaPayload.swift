import Vapor
import Foundation

struct MediaPayload: Decodable, Sendable {
    
    private enum CodingKeys: CodingKey {
        case content
        case kind
        case notes
        case preview
    }

    enum Content: Decodable, Sendable {
        
        case book(MediaPayload.Book)
        
        case movie(MediaPayload.Movie)
        
        case music(MediaPayload.Music)
        
        case podcast(MediaPayload.Podcast)
    }
    
    struct Note: Decodable, Sendable {
        
        let type: MediaNote.NoteType
        
        let text: String
        
        let commentary: String?
        
        let state: MediaNote.State?
        
        let positionStart: String?
        
        let positionEnd: String?
    }
    
    struct Preview: Decodable, Sendable {
        
        let title: String
        
        let subtitle: String?
        
        let body: String?
        
        let imageURL: String?
    }
    
    struct Resource: Decodable, Sendable {
        
        let externalID: String
        
        let url: URL
        
        func resource<Item: MediaItem>(platform: MediaPlatform<Item>) -> MediaResource<Item> {
            MediaResource(platform: platform, externalID: externalID, url: url)
        }
    }
    
    let content: Content
    
    let kind: Media.Kind

    let notes: [Note]?
    
    let preview: Preview
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.kind = try container.decode(Media.Kind.self, forKey: .kind)
        self.notes = try container.decodeIfPresent([MediaPayload.Note].self, forKey: .notes)
        self.preview = try container.decode(MediaPayload.Preview.self, forKey: .preview)
        
        self.content = switch kind {
        case .book: .book(try container.decode(Book.self, forKey: .content))
        case .movie: .movie(try container.decode(Movie.self, forKey: .content))
        case .music: .music(try container.decode(Music.self, forKey: .content))
        case .podcast: .podcast(try container.decode(Podcast.self, forKey: .content))
        }
    }
}

extension MediaPayload {
    
    @propertyWrapper
    struct Platform<M: MediaItem> {
        
        let platform: MediaPlatform<M>
        
        var wrappedValue: Resource?
        
        init(
            _ platform: MediaPlatform<M>,
            wrappedValue: Resource? = nil
        ) {
            self.platform = platform
            self.wrappedValue = wrappedValue
        }
        
    }
}
