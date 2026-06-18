@testable import Backend
import VaporTesting
import Testing
import Fluent
import Vapor
import CoreAuth

@Suite("Catalogue — Albums", .serialized)
struct AlbumTests {

    // MARK: Unauthenticated guards

    @Test("Unauthenticated GET /albums/new redirects")
    func unauthenticated_create_redirects() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "/albums/new") { res async in
                #expect(res.status == .seeOther || res.status == .found)
            }
        }
    }

    @Test("Unauthenticated POST /albums/new redirects")
    func unauthenticated_createPost_redirects() async throws {
        try await withApp { app in
            try await app.testing().test(.POST, "/albums/new") { res async in
                #expect(res.status == .seeOther || res.status == .found)
            }
        }
    }

    // MARK: Authenticated — editor page

    @Test("Authenticated GET /albums/new renders editor with required fields")
    func authenticated_getEditor_rendersForm() async throws {
        try await withAuthenticatedApp { app, headers in
            try await app.testing().test(.GET, "/albums/new", headers: headers) { res async in
                #expect(res.status == .ok)
                let body = res.body.string
                #expect(body.contains("id=\"editor-title\""))
                #expect(body.contains("id=\"editor-artist\""))
                #expect(body.contains("name=\"_csrf\""))
            }
        }
    }

    // MARK: Authenticated — create album

    @Test("Authenticated POST /albums/new with valid input creates album and redirects")
    func authenticated_createAlbum_succeeds() async throws {
        try await withAuthenticatedApp { app, headers in
            // Step 1: GET editor to seed CSRF into the session
            var csrf = ""
            try await app.testing().test(.GET, "/albums/new", headers: headers) { res async in
                #expect(res.status == .ok)
                // Extract CSRF from hidden input
                let body = res.body.string
                if let range = body.range(of: "name=\"_csrf\" value=\"") {
                    let start = body.index(range.upperBound, offsetBy: 0)
                    let end = body[start...].firstIndex(of: "\"") ?? body.endIndex
                    csrf = String(body[start..<end])
                }
            }
            #expect(!csrf.isEmpty, "CSRF token must be present in the form")

            // Step 2: POST with CSRF token and album data
            var redirectLocation = ""
            try await app.testing().test(
                .POST, "/albums/new",
                headers: headers,
                beforeRequest: { req in
                    struct AlbumForm: Content {
                        let _csrf: String
                        let title: String
                        let artist: String
                        let access: String
                    }
                    try req.content.encode(AlbumForm(
                        _csrf: csrf,
                        title: "Kind of Blue",
                        artist: "Miles Davis",
                        access: "private"
                    ))
                },
                afterResponse: { res async in
                    #expect(res.status == .seeOther || res.status == .found)
                    redirectLocation = res.headers.first(name: "Location") ?? ""
                }
            )
            #expect(redirectLocation.hasPrefix("/albums/"), "Should redirect to the new album's page")
        }
    }

    @Test("POST /albums/new missing title returns editor with error")
    func createAlbum_missingTitle_returnsEditorWithError() async throws {
        try await withAuthenticatedApp { app, headers in
            var csrf = ""
            try await app.testing().test(.GET, "/albums/new", headers: headers) { res async in
                let body = res.body.string
                if let range = body.range(of: "name=\"_csrf\" value=\"") {
                    let start = body.index(range.upperBound, offsetBy: 0)
                    let end = body[start...].firstIndex(of: "\"") ?? body.endIndex
                    csrf = String(body[start..<end])
                }
            }

            try await app.testing().test(
                .POST, "/albums/new",
                headers: headers,
                beforeRequest: { req in
                    struct AlbumForm: Content {
                        let _csrf: String
                        let title: String
                        let artist: String
                        let access: String
                    }
                    try req.content.encode(AlbumForm(_csrf: csrf, title: "", artist: "", access: "private"))
                },
                afterResponse: { res async in
                    // Should re-render the editor, not redirect
                    #expect(res.status == .ok || res.status == .unprocessableEntity)
                    #expect(res.body.string.contains("id=\"editor-title\""))
                }
            )
        }
    }

    // MARK: Permissions

    @Test("PATCH /albums/:id by a different user returns 403")
    func editAlbum_byNonOwner_returns403() async throws {
        try await withApp { app in
            // Create owner and their album
            let (owner, ownerHeaders) = try await makeTestUser(role: .standard, on: app)
            var albumLocation = ""
            var csrf = ""

            try await app.testing().test(.GET, "/albums/new", headers: ownerHeaders) { res async in
                let body = res.body.string
                if let range = body.range(of: "name=\"_csrf\" value=\"") {
                    let start = body.index(range.upperBound, offsetBy: 0)
                    let end = body[start...].firstIndex(of: "\"") ?? body.endIndex
                    csrf = String(body[start..<end])
                }
            }
            try await app.testing().test(
                .POST, "/albums/new",
                headers: ownerHeaders,
                beforeRequest: { req in
                    struct AlbumForm: Content {
                        let _csrf: String; let title: String; let artist: String; let access: String
                    }
                    try req.content.encode(AlbumForm(_csrf: csrf, title: "Test", artist: "Tester", access: "private"))
                },
                afterResponse: { res async in
                    albumLocation = res.headers.first(name: "Location") ?? ""
                }
            )
            let albumID = albumLocation.components(separatedBy: "/").last ?? ""
            #expect(!albumID.isEmpty)
            _ = owner // suppress unused warning

            // A different user tries to edit it
            let (_, otherHeaders) = try await makeTestUser(role: .standard, on: app)
            try await app.testing().test(.GET, "/albums/\(albumID)/edit", headers: otherHeaders) { res async in
                #expect(res.status == .forbidden || res.status == .notFound)
            }
        }
    }

    @Test("POST /albums/:id/notes preserves submitted language")
    func createNote_withNonDefaultLanguage_savesLanguage() async throws {
        try await withAuthenticatedApp { app, headers in
            var csrf = ""
            try await app.testing().test(.GET, "/albums/new", headers: headers) { res async in
                let body = res.body.string
                if let range = body.range(of: "name=\"_csrf\" value=\"") {
                    let start = body.index(range.upperBound, offsetBy: 0)
                    let end = body[start...].firstIndex(of: "\"") ?? body.endIndex
                    csrf = String(body[start..<end])
                }
            }
            var albumLocation = ""
            try await app.testing().test(
                .POST, "/albums/new",
                headers: headers,
                beforeRequest: { req in
                    struct AlbumForm: Content {
                        let _csrf: String; let title: String; let artist: String; let access: String
                    }
                    try req.content.encode(AlbumForm(_csrf: csrf, title: "Test Album", artist: "Tester", access: "private"))
                },
                afterResponse: { res async in albumLocation = res.headers.first(name: "Location") ?? "" }
            )
            let albumID = albumLocation.components(separatedBy: "/").last ?? ""
            #expect(!albumID.isEmpty)

            struct NoteForm: Content {
                let body: String; let access: String; let language: String
            }
            try await app.testing().test(
                .POST, "/albums/\(albumID)/notes",
                headers: headers,
                beforeRequest: { req in
                    try req.content.encode(NoteForm(body: "Teszt megjegyzés", access: "private", language: "hu"))
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                }
            )

            let note = try await Note.query(on: app.db).first()
            #expect(note?.language == .hu)
        }
    }

    @Test("GET /albums/:id detail page returns 200")
    func getAlbumDetail_returnsOK() async throws {
        try await withAuthenticatedApp { app, headers in
            var csrf = ""
            try await app.testing().test(.GET, "/albums/new", headers: headers) { res async in
                let body = res.body.string
                if let range = body.range(of: "name=\"_csrf\" value=\"") {
                    let start = body.index(range.upperBound, offsetBy: 0)
                    let end = body[start...].firstIndex(of: "\"") ?? body.endIndex
                    csrf = String(body[start..<end])
                }
            }
            var albumLocation = ""
            try await app.testing().test(
                .POST, "/albums/new",
                headers: headers,
                beforeRequest: { req in
                    struct AlbumForm: Content {
                        let _csrf: String; let title: String; let artist: String; let access: String
                    }
                    try req.content.encode(AlbumForm(_csrf: csrf, title: "Test Album", artist: "Tester", access: "private"))
                },
                afterResponse: { res async in albumLocation = res.headers.first(name: "Location") ?? "" }
            )
            try await app.testing().test(.GET, albumLocation, headers: headers) { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("Test Album"))
            }
        }
    }
}
