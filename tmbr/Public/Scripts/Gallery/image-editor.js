document.addEventListener('DOMContentLoaded', () => {
    const deleteForm = document.getElementById('image-delete-form');
    const deleteButton = document.getElementById('editor-image-delete');

    if (!deleteButton || !deleteForm) {
        return;
    }

    deleteButton.addEventListener('click', (event) => {
        event.preventDefault();
        event.stopPropagation();

        const confirmed = window.confirm('Delete this image? This action cannot be undone.');
        if (!confirmed) return;

        deleteForm.submit();
    });
});
