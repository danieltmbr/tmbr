document.addEventListener('DOMContentLoaded', () => {
    const notesSection   = document.getElementById('notes-section');
    const resourcesSection = document.getElementById('resources-section');
    const detailsSection = document.getElementById('details-section');

    const artwork = new ArtworkController(
        {
            hiddenInput:      document.getElementById('editor-artwork-id'),
            externalUrlInput: document.getElementById('editor-artwork-source-url'),
            placeholder:      document.getElementById('artwork-placeholder'),
            imageEl:          document.getElementById('artwork-image'),
            clearButton:      document.getElementById('artwork-clear'),
        },
        { onChange: null, onOpenGallery: null }
    );
    artwork.init();

    let notesController = null;
    if (notesSection) {
        notesController = new NotesController(
            { section: notesSection },
            { onInput: null, onAccessChange: null }
        );
        notesController.init();
    }

    new DragAndDropController(
        { resourcesSection, detailsSection, notesSection },
        { uploads: new UploadsController(), artwork, notes: notesController }
    ).init();
});
