document.addEventListener('DOMContentLoaded', () => {
    CatalogueEditorController.init({
        type: 'playlist',
        imageTitle: 'Select playlist artwork',
        extraFields: [],
        previewMappings: [
            { sourceId: 'editor-description', outputId: 'preview-description' },
        ],
    });
});
