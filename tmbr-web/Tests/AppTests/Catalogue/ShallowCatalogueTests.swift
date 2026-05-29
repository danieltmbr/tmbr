@testable import Backend
import VaporTesting
import Testing
import Fluent
import Vapor
import AuthKit

@Suite("Catalogue — Shallow Items", .serialized)
struct ShallowCatalogueTests {

    // MARK: Unauthenticated guards

    @Test("Unauthenticated GET /catalogue/new redirects")
    func unauthenticated_getNew_redirects() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "/catalogue/new") { res async in
                #expect(res.status == .seeOther || res.status == .found)
            }
        }
    }

    @Test("Unauthenticated POST /catalogue/new redirects")
    func unauthenticated_postNew_redirects() async throws {
        try await withApp { app in
            try await app.testing().test(.POST, "/catalogue/new") { res async in
                #expect(res.status == .seeOther || res.status == .found)
            }
        }
    }

    // MARK: Editor page

    @Test("Authenticated GET /catalogue/new renders editor")
    func authenticated_getNew_rendersForm() async throws {
        try await withAuthenticatedApp { app, headers in
            try await app.testing().test(.GET, "/catalogue/new", headers: headers) { res async in
                #expect(res.status == .ok)
                let body = res.body.string
                #expect(body.contains("id=\"editor-title\""))
                #expect(body.contains("id=\"editor-url\""))
            }
        }
    }

    // MARK: Create item

    @Test("POST /catalogue/new with valid title creates item and redirects")
    func authenticated_createItem_redirectsToDetailPage() async throws {
        try await withAuthenticatedApp { app, headers in
            var redirectLocation = ""
            try await app.testing().test(
                .POST, "/catalogue/new",
                headers: headers,
                beforeRequest: { req in
                    struct Form: Content {
                        let title: String
                        let url: String
                        let category: String
                        let access: String
                    }
                    try req.content.encode(Form(
                        title: "Test Link",
                        url: "https://example.com",
                        category: "link",
                        access: "private"
                    ))
                },
                afterResponse: { res async in
                    #expect(res.status == .seeOther || res.status == .found)
                    redirectLocation = res.headers.first(name: "Location") ?? ""
                }
            )
            #expect(redirectLocation.hasPrefix("/catalogue/item/"), "Should redirect to the new item's page")
        }
    }

    @Test("POST /catalogue/new with notes creates item and notes without crashing")
    func authenticated_createItemWithNotes_succeeds() async throws {
        // Regression test for the attachNote permission crash:
        // BatchCreateNoteCommand passes a freshly-created Preview (parentOwner not eager-loaded)
        // to attachPermission. Using preview.ownerID ($parentOwner.id) instead of
        // preview.parentOwner.id prevents the "Parent relation not eager loaded" fatal error.
        try await withAuthenticatedApp { app, headers in
            var redirectLocation = ""
            try await app.testing().test(
                .POST, "/catalogue/new",
                headers: headers,
                beforeRequest: { req in
                    struct Form: Content {
                        let title: String
                        let url: String
                        let category: String
                        let access: String
                        let notes: [[String: String]]

                        enum CodingKeys: String, CodingKey {
                            case title, url, category, access, notes
                        }
                    }
                    var buffer = ByteBuffer()
                    buffer.writeString("title=Test+With+Notes&url=https%3A%2F%2Fexample.com&category=link&access=private&notes%5B0%5D%5Bbody%5D=My+note&notes%5B0%5D%5Baccess%5D=private")
                    req.headers.contentType = .urlEncodedForm
                    req.body = .init(buffer: buffer)
                },
                afterResponse: { res async in
                    #expect(res.status == .seeOther || res.status == .found, "Should redirect, not crash")
                    redirectLocation = res.headers.first(name: "Location") ?? ""
                }
            )
            #expect(redirectLocation.hasPrefix("/catalogue/item/"))

            // Verify the note appears on the item page
            try await app.testing().test(.GET, redirectLocation, headers: headers) { res async in
                #expect(res.status == .ok)
                #expect(res.body.string.contains("My note"))
            }
        }
    }

    @Test("POST /catalogue/new with empty title re-renders editor with error")
    func authenticated_createItem_emptyTitle_rendersError() async throws {
        try await withAuthenticatedApp { app, headers in
            try await app.testing().test(
                .POST, "/catalogue/new",
                headers: headers,
                beforeRequest: { req in
                    req.headers.contentType = .urlEncodedForm
                    var buffer = ByteBuffer()
                    buffer.writeString("title=&url=https%3A%2F%2Fexample.com&category=link&access=private")
                    req.body = .init(buffer: buffer)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                    #expect(res.body.string.contains("id=\"editor-title\""))
                    #expect(res.body.string.contains("Title is required"))
                }
            )
        }
    }

    @Test("POST /catalogue/item/:id/notes by owner creates note")
    func authenticated_addNote_toOwnItem_succeeds() async throws {
        try await withAuthenticatedApp { app, headers in
            // Create the item
            var itemPath = ""
            try await app.testing().test(
                .POST, "/catalogue/new",
                headers: headers,
                beforeRequest: { req in
                    req.headers.contentType = .urlEncodedForm
                    var buffer = ByteBuffer()
                    buffer.writeString("title=Note+Test+Item&url=https%3A%2F%2Fexample.com&category=link&access=private")
                    req.body = .init(buffer: buffer)
                },
                afterResponse: { res async in
                    itemPath = res.headers.first(name: "Location") ?? ""
                }
            )
            #expect(itemPath.hasPrefix("/catalogue/item/"))

            // Add a note via the HTMX endpoint
            let notesPath = itemPath + "/notes"
            try await app.testing().test(
                .POST, notesPath,
                headers: headers,
                beforeRequest: { req in
                    req.headers.contentType = .urlEncodedForm
                    var buffer = ByteBuffer()
                    buffer.writeString("body=A+later+note&access=private")
                    req.body = .init(buffer: buffer)
                },
                afterResponse: { res async in
                    #expect(res.status == .ok)
                    #expect(res.body.string.contains("A later note"))
                }
            )
        }
    }

    @Test("POST /catalogue/item/:id/notes by a different user returns error")
    func authenticated_addNote_toOtherOwnersItem_fails() async throws {
        try await withApp { app in
            let (_, ownerHeaders) = try await makeTestUser(on: app)
            var itemPath = ""
            try await app.testing().test(
                .POST, "/catalogue/new",
                headers: ownerHeaders,
                beforeRequest: { req in
                    req.headers.contentType = .urlEncodedForm
                    var buffer = ByteBuffer()
                    buffer.writeString("title=Owners+Item&url=https%3A%2F%2Fexample.com&category=link&access=private")
                    req.body = .init(buffer: buffer)
                },
                afterResponse: { res async in
                    itemPath = res.headers.first(name: "Location") ?? ""
                }
            )

            let (_, otherHeaders) = try await makeTestUser(on: app)
            try await app.testing().test(
                .POST, itemPath + "/notes",
                headers: otherHeaders,
                beforeRequest: { req in
                    req.headers.contentType = .urlEncodedForm
                    var buffer = ByteBuffer()
                    buffer.writeString("body=Unauthorized+note&access=private")
                    req.body = .init(buffer: buffer)
                },
                afterResponse: { res async in
                    #expect(res.status == .forbidden || res.status == .unauthorized || res.status == .unprocessableEntity)
                }
            )
        }
    }
}
