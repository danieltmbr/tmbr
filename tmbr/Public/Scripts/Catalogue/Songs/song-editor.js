document.addEventListener('DOMContentLoaded', () => {
    CatalogueEditorController.init({
        type: 'song',
        metadataEndpoint: '/songs/metadata',
        lookupEndpoint: '/songs/lookup',
        duplicateLinkSelector: '#duplicate-song-link',
        imageTitle: 'Select album artwork',
        extraFields: [
            { inputId: 'editor-artist', stateKey: 'artist', metadataKey: 'artist' },
            { inputId: 'editor-album', stateKey: 'album', metadataKey: 'album' },
        ],
        previewMappings: [
            { sourceId: 'editor-artist', outputId: 'preview-artist' },
            { sourceId: 'editor-album', outputId: 'preview-album' },
        ],
    });
});
