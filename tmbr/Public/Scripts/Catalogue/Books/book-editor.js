document.addEventListener('DOMContentLoaded', () => {
    CatalogueEditorController.init({
        type: 'book',
        metadataEndpoint: '/books/metadata',
        lookupEndpoint: '/books/lookup',
        duplicateLinkSelector: '#duplicate-book-link',
        imageTitle: 'Select book cover',
        artworkMetadataKey: 'cover',
        extraFields: [
            { inputId: 'editor-author', stateKey: 'author', metadataKey: 'author' },
        ],
        previewMappings: [
            { sourceId: 'editor-author', outputId: 'preview-author' },
        ],
    });
});
