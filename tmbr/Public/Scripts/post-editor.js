document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('post-form');
    const idInput = document.getElementById('editor-post-id');
    const titleInput = document.getElementById('editor-post-title');
    const bodyTextArea = document.getElementById('editor-post-body');
    const publishedCheckbox = document.getElementById('editor-post-published');
    const previewButton = document.getElementById('editor-post-preview');
    const gallery = document.getElementById('gallery');
    const galleryButton = document.getElementById('gallery-open');

    // Insert text at caret position in a textarea and preserve scroll
    function insertAtCaret(textarea, text) {
        const start = textarea.selectionStart ?? textarea.value.length;
        const end = textarea.selectionEnd ?? textarea.value.length;
        const before = textarea.value.slice(0, start);
        const after = textarea.value.slice(end);
        const insert = (textarea.value && !textarea.value.endsWith('\n') ? '\n' : '') + text + '\n';
        textarea.value = before + insert + after;
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

    async function uploadImageFile(file) {
        const form = new FormData();
        form.append('image', file, file.name);
        form.append('alt', file.name.replace(/\.[^.]+$/, ''));
        const res = await fetch('/gallery', { method: 'POST', body: form, });
        if (!res.ok) {
            const text = await res.text().catch(() => '');
            throw new Error(text || `Upload failed with status ${res.status}`);
        }
        return await res.text();
    }

    function setupPageDragAndDrop(textarea) {
        let hideTimer = null;

        // Very permissive detection for showing the cue (Safari-friendly)
        function shouldShowCue(e) {
            const dt = e.dataTransfer;
            if (!dt) { return false; }

            if (dt.items && dt.items.length) {
                for (const item of dt.items) {
                    if (item.kind === 'file') {
                        if (!item.type || item.type.startsWith('image/')) {
                            return true;
                        }
                    }
                }
                return false;
            }

            if (dt.files && dt.files.length) {
                const files = Array.from(dt.files);
                if (files.every(f => f.type)) {
                    return files.some(f => f.type.startsWith('image/'));
                }
                return true;
            }

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
        
        function focus(textarea) {
            if (document.activeElement !== textarea) {
                textarea.focus();
                if (typeof textarea.selectionStart !== 'number' || typeof textarea.selectionEnd !== 'number') {
                    const end = textarea.value.length;
                    textarea.selectionStart = textarea.selectionEnd = end;
                }
            }
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
            
            const customMarkdown = dt.getData('application/x-editor-markdown') || '';
            if (customMarkdown) {
                focus(textarea);
                insertAtCaret(
                    textarea,
                    (textarea.value && !textarea.value.endsWith('\n') ? '\n' : '') + customMarkdown + '\n'
                );
                return;
            }
            
            const files = Array.from(dt.files || []);
            if (!files.length) return;

            focus(textarea);

            // Filter to images only, but keep mapping info for placeholders
            const imageFiles = files.filter(f => f && (!f.type || f.type.startsWith('image/')));
            if (!imageFiles.length) return;

            const entries = imageFiles.map((file) => {
                const filename = file.name;
                const placeholder = `![Uploading...](${filename})`;
                insertAtCaret(
                    textarea,
                    (textarea.value && !textarea.value.endsWith('\n') ? '\n' : '') + placeholder + '\n'
                );
                return { file, filename, placeholder };
            });

            const uploads = entries.map(async ({ file, filename, placeholder }) => {
                try {
                    const markdown = await uploadImageFile(file);
                    replacePlaceholder(textarea, placeholder, markdown);
                    return { filename, ok: true };
                } catch (err) {
                    const failed = `![Failed...](${filename})`;
                    replacePlaceholder(textarea, placeholder, failed);
                    console.error(`Image upload failed: ${err.message || err}`);
                    return { filename, ok: false };
                }
            });

            await Promise.allSettled(uploads);
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
    
    function attachListenersToGallery() {
        const gallerySection = document.getElementById('gallery-section');
        const galleryCloseButton = document.getElementById('gallery-close');
        
        galleryCloseButton.addEventListener('click', () => {
            window.dispatchEvent(new CustomEvent('gallery-close'));
        });
        
        const items = gallerySection.querySelectorAll('.gallery-item');
        items.forEach((btn) => {
            const alt = btn.dataset.alt || '';
            const url = btn.dataset.url;
            
            if (!url) return;
            
            const markdown = `![${alt}](${url})`;
            
            btn.addEventListener('click', () => {
                let insert = new CustomEvent('editor-insert-markdown', { detail: { markdown } })
                window.dispatchEvent(insert);
            });
            
            btn.addEventListener('dragstart', (e) => {
                e.dataTransfer.setData('text/uri-list', url);
                e.dataTransfer.setData('text/plain', url);
                e.dataTransfer.setData('text/html', `<img src="${url}" alt="${alt}">`);
                e.dataTransfer.setData('application/x-editor-markdown', markdown);
                e.dataTransfer.effectAllowed = 'copy';
            });
        });
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
        } catch (err) {
            console.error('Couldn\'t save draft. ${err.message || err}')
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
    
    async function openGallery() {
        gallery.innerHTML = 'Loading...';
        try {
            const res = await fetch('/gallery?embedded=true', { headers: { 'Accept': 'text/html' }});
            const html = await res.text();
            gallery.innerHTML = html;
            attachListenersToGallery();
            gallery.style.display = 'block';
        } catch (err) {
            gallery.innerHTML = 'Failed to load gallery.';
            console.error(`Image upload failed: ${err.message || err}`);
        }
    }
    
    function closeGallery() {
        gallery.style.display = 'none';
    }
    
    window.addEventListener('editor-insert-markdown', (e) => {
        const md = e.detail && e.detail.markdown ? e.detail.markdown : '';
        if (!md) return;
        insertAtCaret(bodyTextArea, md);
    });
    galleryButton.addEventListener('click', openGallery);
    window.addEventListener('gallery-close', closeGallery);
});

