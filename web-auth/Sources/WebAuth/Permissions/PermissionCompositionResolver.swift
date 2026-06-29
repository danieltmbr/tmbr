import Vapor

public struct PermissionCompositionResolver: Sendable {

    private let request: Request

    init(request: Request) {
        self.request = request
    }

    public func callAsFunction<I: Hashable & Sendable>(
        _ pairs: some Collection<(I, AuthPermission<Void>)>
    ) -> Set<I> {
        Set(pairs.compactMap { item, permission in
            permission.isGranted(for: request) ? item : nil
        })
    }
}
