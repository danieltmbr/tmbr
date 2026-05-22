document.addEventListener('DOMContentLoaded', () => {
    CatalogueEditorController.init({
        type: 'album',
        metadataEndpoint: '/albums/metadata',
        lookupEndpoint: '/albums/lookup',
        duplicateLinkSelector: '#duplicate-album-link',
        imageTitle: 'Select album artwork',
        extraFields: [
            { inputId: 'editor-artist', stateKey: 'artist', metadataKey: 'artist' },
        ],
        previewMappings: [
            { sourceId: 'editor-artist', outputId: 'preview-artist' },
        ],
    });
});
