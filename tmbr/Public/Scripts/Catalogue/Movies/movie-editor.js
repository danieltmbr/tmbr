document.addEventListener('DOMContentLoaded', () => {
    CatalogueEditorController.init({
        type: 'movie',
        metadataEndpoint: '/movies/metadata',
        lookupEndpoint: '/movies/lookup',
        duplicateLinkSelector: '#duplicate-movie-link',
        imageTitle: 'Select movie poster',
        artworkMetadataKey: 'cover',
        extraFields: [
            { inputId: 'editor-director', stateKey: 'director', metadataKey: 'director' },
        ],
        previewMappings: [
            { sourceId: 'editor-director', outputId: 'preview-director' },
        ],
    });
});
