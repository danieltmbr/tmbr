document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('post-form');
    const idInput = document.getElementById('editor-post-id');
    const titleInput = document.getElementById('editor-post-title');
    const bodyTextArea = document.getElementById('editor-post-body');
    const publishedCheckbox = document.getElementById('editor-post-published');
    const previewButton = document.getElementById('editor-post-preview');
    
    function preview() {
        const previewForm = document.getElementById('preview-form');
        const previewTitleInput = document.getElementById('preview-title');
        const previewBodyInput = document.getElementById('preview-body');
        if (!previewForm || !previewTitleInput || !previewBodyInput) {
            alert('Preview form is missing from the template.');
            return;
        }
        // Populate hidden inputs from current editor fields
        previewTitleInput.value = titleInput.value || '';
        previewBodyInput.value = bodyTextArea.value || '';
        previewForm.submit();
    }
    
    function autosize() {
        bodyTextArea.style.height = 'auto';
        bodyTextArea.style.height = bodyTextArea.scrollHeight + 'px';
    }
    
    if (!form || !titleInput || !bodyTextArea || !publishedCheckbox || !previewButton) {
        // Missing elements; avoid runtime errors
        return;
    }
    
    const postID = idInput ? idInput.value : '';
    const storageKey = postID ? `editor:post:${postID}` : 'editor:post:new';
    
    // Load from localStorage
    try {
        const saved = JSON.parse(localStorage.getItem(storageKey) || 'null');
        if (saved) {
            if (typeof saved.title === 'string' && !titleInput.value) {
                titleInput.value = saved.title;
            }
            if (typeof saved.body === 'string' && !bodyTextArea.value) {
                bodyTextArea.value = saved.body;
            }
            if (typeof saved.published === 'boolean') {
                publishedCheckbox.checked = saved.published;
            }
        }
    } catch (_) {
        // ignore
    }
    
    // Autosave to localStorage
    const saveDraftLocal = () => {
        const data = {
            title: titleInput.value || '',
            body: bodyTextArea.value || '',
            published: !!publishedCheckbox.checked
        };
        try {
            localStorage.setItem(storageKey, JSON.stringify(data));
        } catch (_) {

        }
    };
    
    titleInput.addEventListener('input', saveDraftLocal);
    bodyTextArea.addEventListener('input', saveDraftLocal);
    publishedCheckbox.addEventListener('change', (e) => {
        if (postID && !e.target.checked) {
            const ok = confirm('Unpublish this post? It will no longer be publicly visible.');
            if (!ok) {
                e.target.checked = true;
                return;
            }
        }
        saveDraftLocal();
    });
    
    // Clear storage only after successful navigation away from the editor
    // Mark intent on submit, then clear if the next page is not the editor
    form.addEventListener('submit', () => {
        try {
            localStorage.setItem('editor:pendingClear', storageKey);
        } catch (_) {
            // ignore
        }
    });

    // On page show (including BFCache restores), clear if we navigated away
    window.addEventListener('pageshow', () => {
        try {
            const pending = localStorage.getItem('editor:pendingClear');
            if (!pending) return;

            const stillOnEditor = !!document.getElementById('post-form');
            if (stillOnEditor) return;
            
            localStorage.removeItem(pending);
            localStorage.removeItem('editor:pendingClear');
        } catch (_) {
            // ignore
        }
    });
    
    // Preview: submit hidden form to /post/preview (form data only)
    previewButton.addEventListener('click', () => {
        preview();
    });
    
    bodyTextArea.addEventListener('input', autosize);
    window.addEventListener('load', autosize);

    document.addEventListener('keydown', (event) => {
        try {
            const isInputLike = (el) => {
                if (!el) return false;
                const tag = el.tagName;
                const editable = el.isContentEditable;
                return editable || tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT';
            };

            const active = document.activeElement;
            const inField = isInputLike(active);
            if (inField) { return; }
            
            const isMac = navigator.platform.toUpperCase().includes('MAC');
            const cmdOrCtrl = isMac ? event.metaKey : event.ctrlKey;
            const alt = event.altKey;
            const shift = event.shiftKey;
            const keyP = event.key === 'p' || event.key === 'P';
            const isPKey = event.code === 'KeyP';
            
            if (cmdOrCtrl && alt && !shift && isPKey) {
                event.preventDefault();
                preview();
            }
        } catch (_) {
            // ignore
        }
    });
});
