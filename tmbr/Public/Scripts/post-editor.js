document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('post-form');
    const idInput = document.getElementById('editor-post-id');
    const titleInput = document.getElementById('editor-post-title');
    const bodyTextArea = document.getElementById('editor-post-body');
    const publishedCheckbox = document.getElementById('editor-post-published');
    const previewButton = document.getElementById('editor-post-preview');
    
    // Insert text at caret position in a textarea and preserve scroll
    function insertAtCaret(textarea, text) {
        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const before = textarea.value.substring(0, start);
        const after = textarea.value.substring(end);
        textarea.value = before + text + after;
        const pos = start + text.length;
        textarea.selectionStart = textarea.selectionEnd = pos;
        textarea.dispatchEvent(new Event('input', { bubbles: true }));
        autosize();
    }
    
    function replacePlaceholder(textarea, placeholder, content) {
        const idx = textarea.value.indexOf(placeholder);
        if (idx !== -1) {
            textarea.value = textarea.value.slice(0, idx) + content + textarea.value.slice(idx + placeholder.length);
            textarea.dispatchEvent(new Event('input', { bubbles: true }));
            autosize();
        }
    }

    // Upload a single file to /gallery/upload and return markdown string
    async function uploadImageFile(file) {
        const form = new FormData();
        form.append('image', file, file.name);
        form.append('alt', file.name.replace(/\.[^.]+$/, ''));
        const res = await fetch('/gallery/upload', { method: 'POST', body: form, });
        if (!res.ok) {
            const text = await res.text().catch(() => '');
            throw new Error(text || `Upload failed with status ${res.status}`);
        }
        return await res.text();
    }

    function setupPageDragAndDrop(textarea) {
        let hideTimer = null;
        const DEBUG_DRAG = false; // set to true to log drag events

        function log(...args) { if (DEBUG_DRAG) console.log('[drag]', ...args); }

        // Very permissive detection for showing the cue (Safari-friendly)
        function shouldShowCue(e) {
            const dt = e.dataTransfer;
            if (!dt) { log('no dataTransfer'); return false; }

            if (dt.items && dt.items.length) {
                for (const item of dt.items) {
                    if (item.kind === 'file') {
                        if (!item.type || item.type.startsWith('image/')) {
                            log('cue: file item', item.type || '(no type)');
                            return true;
                        }
                    }
                }
                log('items present but no file item');
                return false;
            }

            if (dt.files && dt.files.length) {
                const files = Array.from(dt.files);
                if (files.every(f => f.type)) {
                    const anyImage = files.some(f => f.type.startsWith('image/'));
                    log('files with types, any image?', anyImage);
                    return anyImage;
                }
                log('files present (no types), permissive cue');
                return true;
            }

            log('dataTransfer exists but no items/files; showing cue (safari fallback)');
            return true;
        }

        function showCue() {
            document.body.classList.add('dragging-page');
            if (hideTimer) { clearTimeout(hideTimer); hideTimer = null; }
        }
        function hideCueDebounced() {
            if (hideTimer) clearTimeout(hideTimer);
            hideTimer = setTimeout(() => {
                document.body.classList.remove('dragging-page');
            }, 60);
        }

        window.addEventListener('dragenter', (e) => {
            if (shouldShowCue(e)) {
                showCue();
            }
        });

        window.addEventListener('dragover', (e) => {
            // Always prevent default to keep the drag session alive in Safari
            e.preventDefault();
            if (shouldShowCue(e)) {
                showCue();
            } else {
                hideCueDebounced();
            }
        });

        window.addEventListener('dragleave', () => {
            hideCueDebounced();
        });

        window.addEventListener('drop', async (e) => {
            e.preventDefault();
            document.body.classList.remove('dragging-page');

            const dt = e.dataTransfer;
            if (!dt) return;

            const files = Array.from(dt.files || []);
            if (!files.length) return;

            // Focus textarea and set caret to end if not focused
            if (document.activeElement !== textarea) {
                textarea.focus();
                const end = textarea.value.length;
                textarea.selectionStart = textarea.selectionEnd = end;
            }

            for (const file of files) {
                if (!file.type || !file.type.startsWith('image/')) {
                    continue; // filter non-images at drop time
                }

                const filename = file.name;
                const placeholder = `![Uploading...](${filename})`;
                insertAtCaret(
                    textarea,
                    (textarea.value && !textarea.value.endsWith('\n') ? '\n' : '') + placeholder + '\n'
                );

                try {
                    const markdown = await uploadImageFile(file);
                    replacePlaceholder(textarea, placeholder, markdown);
                } catch (err) {
                    const failed = `![Failed...](${filename})`;
                    replacePlaceholder(textarea, placeholder, failed);
                    console.error(`Image upload failed: ${err.message || err}`);
                }
            }
        }, { capture: true });
    }
        
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

    setupPageDragAndDrop(bodyTextArea);
});

