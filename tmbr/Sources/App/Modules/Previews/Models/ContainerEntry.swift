import Fluent
import Foundation

final class ContainerEntry: Model, @unchecked Sendable {
    static let schema = "container_entries"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "container_type")
    var containerType: String

    @Field(key: "container_id")
    var containerID: Int

    @Parent(key: "preview_id")
    var preview: Preview

    @Field(key: "position")
    var position: Int

    init() {}

    init(containerType: String, containerID: Int, previewID: UUID, position: Int) {
        self.containerType = containerType
        self.containerID = containerID
        self.$preview.id = previewID
        self.position = position
    }
}
