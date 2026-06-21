import SwiftUI

public extension EnvironmentValues {
    @Entry
    var refreshBlog: RefreshBlogAction = RefreshBlogAction()
    
    @Entry
    var loadMoreBlog: LoadMoreBlogAction = LoadMoreBlogAction()
}
