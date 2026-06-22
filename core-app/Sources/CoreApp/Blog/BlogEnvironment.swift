import SwiftUI

public extension EnvironmentValues {
    @Entry
    var refreshBlog: BlogRefreshAction = BlogRefreshAction()
    
    @Entry
    var loadBlog: BlogPageLoadAction = BlogPageLoadAction()
}
