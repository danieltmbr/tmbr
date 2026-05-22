document.addEventListener('DOMContentLoaded', () => {
    CatalogueEditorController.init({
        type: 'podcast',
        metadataEndpoint: '/podcasts/metadata',
        lookupEndpoint: '/podcasts/lookup',
        duplicateLinkSelector: '#duplicate-podcast-link',
        imageTitle: 'Select podcast artwork',
        titleMetadataKey: 'episodeTitle',
        extraFields: [
            { inputId: 'editor-show-title', stateKey: 'showTitle', metadataKey: 'showTitle' },
            { inputId: 'editor-season-number', stateKey: 'seasonNumber', metadataKey: 'seasonNumber', isNumber: true },
            { inputId: 'editor-episode-number', stateKey: 'episodeNumber', metadataKey: 'episodeNumber', isNumber: true },
        ],
        previewMappings: [
            { sourceId: 'editor-title', outputId: 'preview-episode-title' },
            { sourceId: 'editor-show-title', outputId: 'preview-title' },
            { sourceId: 'editor-season-number', outputId: 'preview-season-number' },
            { sourceId: 'editor-episode-number', outputId: 'preview-episode-number' },
        ],
    });
});
