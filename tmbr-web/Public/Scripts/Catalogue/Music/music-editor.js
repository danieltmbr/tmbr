document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('editor-form');
    if (!form) return;

    const titleInput = document.getElementById('editor-title');
    const statusEl  = document.getElementById('autofill-status');

    const resourcesSection = document.getElementById('resources-section');
    const detailsSection   = document.getElementById('details-section');
    const notesSection     = document.getElementById('notes-section');
    const gallery          = document.getElementById('gallery');
    const gallerySection   = document.getElementById('gallery-section');
    const galleryStatus    = document.getElementById('gallery-status');
    const galleryTitle     = document.getElementById('gallery-title');
    const notesGalleryOpen = document.getElementById('notes-gallery-open');
    const galleryClose     = document.getElementById('gallery-close');

    const persistence = new PersistenceController();
    const uploads     = new UploadsController();
    const metadata    = new MetadataController({ endpoint: '/music/metadata' });

    const storageKey = 'editor:music:new';

    const typeActions = {
        song:     '/songs/new',
        album:    '/albums/new',
        playlist: '/playlists/new',
    };

    const typePreviewActions = {
        song:     '/songs/preview',
        album:    '/albums/preview',
        playlist: '/playlists/preview',
    };

    const fields = {
        song: {
            group:          document.querySelector('[data-music-type="song"]'),
            artist:         document.getElementById('editor-song-artist'),
            album:          document.getElementById('editor-song-album'),
            releaseDate:    document.getElementById('editor-song-release-date'),
            releaseDateISO: document.getElementById('editor-song-release-date-iso'),
            genre:          document.getElementById('editor-song-genre'),
        },
        album: {
            group:             document.querySelector('[data-music-type="album"]'),
            artist:            document.getElementById('editor-album-artist'),
            releaseDate:       document.getElementById('editor-album-release-date'),
            releaseDateISO:    document.getElementById('editor-album-release-date-iso'),
            genre:             document.getElementById('editor-album-genre'),
            tracklistJson:     document.getElementById('editor-album-tracklist-json'),
            tracklistSection:  document.getElementById('editor-album-tracklist-section'),
            tracklistEl:       document.getElementById('editor-album-tracklist'),
        },
        playlist: {
            group:             document.querySelector('[data-music-type="playlist"]'),
            description:       document.getElementById('editor-playlist-description'),
            tracklistJson:     document.getElementById('editor-playlist-tracklist-json'),
            tracklistSection:  document.getElementById('editor-playlist-tracklist-section'),
            tracklistEl:       document.getElementById('editor-playlist-tracklist'),
        },
    };

    let currentType = 'song';

    const artwork = new ArtworkController({
        hiddenInput:      document.getElementById('editor-artwork-id'),
        externalUrlInput: document.getElementById('editor-artwork-source-url'),
        placeholder:      document.getElementById('artwork-placeholder'),
        imageEl:          document.getElementById('artwork-image'),
        clearButton:      document.getElementById('artwork-clear'),
    }, {
        onChange:      () => saveDraft(),
        onOpenGallery: () => imagePicker.open('image'),
    });
    artwork.init();

    const notes = new NotesController(
        { section: notesSection },
        { onInput: () => saveDraft(), onAccessChange: () => saveDraft() }
    );
    notes.init();

    const lookup = new LookupController({ endpoint: '/songs/lookup', excludeID: null });
    const duplicateAlert = new DuplicateAlertController(
        { containerEl: document.getElementById('duplicate-container'), linkSelector: '#duplicate-song-link' },
        { onNavigate: () => persistence.clear(storageKey) }
    );
    duplicateAlert.init();

    function selectType(type) {
        if (!fields[type]) return;
        currentType = type;

        document.querySelectorAll('input[name="music-type"]').forEach(r => {
            r.checked = r.value === type;
        });

        Object.entries(fields).forEach(([t, f]) => {
            const active = t === type;
            f.group.hidden = !active;
            f.group.querySelectorAll('input, textarea').forEach(el => {
                el.disabled = !active;
            });
        });

        form.action = typeActions[type];
    }

    function applyMetadata(data) {
        if (data.musicType && data.musicType !== 'unknown') {
            selectType(data.musicType);
        }
        const type = currentType;
        const f = fields[type];

        if (!titleInput.value && data.title) titleInput.value = data.title;
        if (artwork.isEmpty() && data.artwork) artwork.setExternalURL(data.artwork);

        if (type === 'song' || type === 'album') {
            if (f.artist && !f.artist.value && data.artist) f.artist.value = data.artist;
            if (f.genre && !f.genre.value && data.genre) f.genre.value = data.genre;
            if (f.releaseDate && data.releaseDate) f.releaseDate.value = data.releaseDate.substring(0, 10);
        }
        if (type === 'song' && fields.song.album && !fields.song.album.value && data.album) {
            fields.song.album.value = data.album;
        }
        if ((type === 'album' || type === 'playlist') && f.tracklistJson) {
            if (Array.isArray(data.tracks) && data.tracks.length > 0) {
                f.tracklistJson.value = JSON.stringify(data.tracks);
                if (f.tracklistEl) {
                    f.tracklistEl.replaceChildren();
                    data.tracks.forEach(track => {
                        const li = document.createElement('li');
                        li.dataset.trackName = track.name;
                        if (track.url) li.dataset.trackUrl = track.url;
                        const span = document.createElement('span');
                        span.textContent = track.name;
                        li.appendChild(span);
                        f.tracklistEl.appendChild(li);
                    });
                    if (f.tracklistSection) f.tracklistSection.hidden = false;
                }
            }
        }
        if (type === 'playlist' && f.description && !f.description.value && data.description) {
            f.description.value = data.description;
        }
    }

    const resourceInputs = new ResourceInputsController(
        { section: resourcesSection },
        {
            onUrlChange: (url) => autofill.fetchAndApply(url),
            onInput: () => saveDraft(),
        }
    );
    resourceInputs.init();

    document.querySelectorAll('input[name="music-type"]').forEach(radio => {
        radio.addEventListener('change', () => {
            if (radio.checked) { selectType(radio.value); saveDraft(); }
        });
    });

    function getState() {
        return {
            type:         currentType,
            title:        titleInput?.value || '',
            notes:        notes.getNotes(),
            resourceURLs: resourceInputs.getValues(),
            artworkId:           artwork.getArtworkId(),
            artworkThumbnailUrl: artwork.getThumbnailUrl(),
            artworkExternalURL:  artwork.getExternalURL(),
            song: {
                artist:      fields.song.artist?.value || '',
                album:       fields.song.album?.value || '',
                releaseDate: fields.song.releaseDate?.value || '',
                genre:       fields.song.genre?.value || '',
            },
            album: {
                artist:        fields.album.artist?.value || '',
                releaseDate:   fields.album.releaseDate?.value || '',
                genre:         fields.album.genre?.value || '',
                tracklistJson: fields.album.tracklistJson?.value || '',
            },
            playlist: {
                description:   fields.playlist.description?.value || '',
                tracklistJson: fields.playlist.tracklistJson?.value || '',
            },
        };
    }

    function setState(state) {
        if (!state || typeof state !== 'object') return;
        if (state.type) selectType(state.type);
        if (state.title && !titleInput.value) titleInput.value = state.title;
        if (Array.isArray(state.notes)) notes.setNotes(state.notes, true);
        if (Array.isArray(state.resourceURLs)) resourceInputs.setValues(state.resourceURLs);
        if (artwork.isEmpty()) {
            if (state.artworkId) artwork.setArtwork(state.artworkId, state.artworkThumbnailUrl);
            else if (state.artworkExternalURL) artwork.setExternalURL(state.artworkExternalURL);
        }
        const s = state.song || {};
        const a = state.album || {};
        const p = state.playlist || {};
        if (s.artist && !fields.song.artist?.value) fields.song.artist.value = s.artist;
        if (s.album && !fields.song.album?.value) fields.song.album.value = s.album;
        if (s.releaseDate && !fields.song.releaseDate?.value) fields.song.releaseDate.value = s.releaseDate;
        if (s.genre && !fields.song.genre?.value) fields.song.genre.value = s.genre;
        if (a.artist && !fields.album.artist?.value) fields.album.artist.value = a.artist;
        if (a.releaseDate && !fields.album.releaseDate?.value) fields.album.releaseDate.value = a.releaseDate;
        if (a.genre && !fields.album.genre?.value) fields.album.genre.value = a.genre;
        if (a.tracklistJson && fields.album.tracklistJson) {
            fields.album.tracklistJson.value = a.tracklistJson;
            if (fields.album.tracklistEl && fields.album.tracklistEl.children.length === 0) {
                try {
                    const tracks = JSON.parse(a.tracklistJson);
                    if (Array.isArray(tracks) && tracks.length > 0) {
                        tracks.forEach(track => {
                            const li = document.createElement('li');
                            li.dataset.trackName = track.name || '';
                            if (track.url) li.dataset.trackUrl = track.url;
                            const span = document.createElement('span');
                            span.textContent = track.name || '';
                            li.appendChild(span);
                            fields.album.tracklistEl.appendChild(li);
                        });
                        if (fields.album.tracklistSection) fields.album.tracklistSection.hidden = false;
                    }
                } catch {}
            }
        }
        if (p.description && !fields.playlist.description?.value) fields.playlist.description.value = p.description;
        if (p.tracklistJson && fields.playlist.tracklistJson) {
            fields.playlist.tracklistJson.value = p.tracklistJson;
            if (fields.playlist.tracklistEl && fields.playlist.tracklistEl.children.length === 0) {
                try {
                    const tracks = JSON.parse(p.tracklistJson);
                    if (Array.isArray(tracks) && tracks.length > 0) {
                        tracks.forEach(track => {
                            const li = document.createElement('li');
                            li.dataset.trackName = track.name || '';
                            if (track.url) li.dataset.trackUrl = track.url;
                            const span = document.createElement('span');
                            span.textContent = track.name || '';
                            li.appendChild(span);
                            fields.playlist.tracklistEl.appendChild(li);
                        });
                        if (fields.playlist.tracklistSection) fields.playlist.tracklistSection.hidden = false;
                    }
                } catch {}
            }
        }
    }

    function saveDraft() { persistence.save(storageKey, getState()); }
    function loadDraft() {
        if (persistence.clearIfPending(storageKey)) return;
        const saved = persistence.load(storageKey);
        if (saved) setState(saved);
    }

    function fillPreview() {
        const pf = document.getElementById('preview-form');
        if (!pf) return;
        pf.action = typePreviewActions[currentType];
        const set = (id, v) => { const el = pf.querySelector(`#${id}`); if (el) el.value = v || ''; };
        const f = fields[currentType];
        set('preview-title', titleInput?.value || '');
        set('preview-artwork-url', artwork.getThumbnailUrl());
        set('preview-resource-urls', resourceInputs.getValues().join('\n'));
        set('preview-notes', notes.getValues().join('\n\n'));
        if (currentType === 'song' || currentType === 'album') {
            set('preview-artist', f.artist?.value || '');
            set('preview-genre', f.genre?.value || '');
            set('preview-release-date', f.releaseDate?.value || '');
        }
        if (currentType === 'song') set('preview-album', fields.song.album?.value || '');
        if (currentType === 'playlist') set('preview-description', f.description?.value || '');
        pf.submit();
    }

    const autofill = {
        async fetchAndApply(url) {
            try {
                const data = await metadata.fetch(url);
                if (statusEl) { statusEl.textContent = ''; statusEl.hidden = true; }
                applyMetadata(data);
                if (currentType === 'song') {
                    const html = await lookup.fetch(url).catch(() => null);
                    if (html) duplicateAlert.show(html);
                }
                saveDraft();
            } catch (err) {
                handleAutofillError(err, url, statusEl);
            }
        }
    };
    retryPendingMetadata(autofill);
    loadDraft();

    titleInput?.addEventListener('input', saveDraft);

    const imagePicker = new ImagePickerController(
        { gallery, gallerySection, galleryStatus, galleryTitle, notesOpenButton: notesGalleryOpen, galleryCloseButton: galleryClose },
        { onSelectImage: (id, url) => artwork.setArtwork(id, url), onInsertMarkdown: (md) => notes.insertMarkdown(md), imageTitle: 'Select artwork' }
    );
    imagePicker.init();

    new DragAndDropController({ resourcesSection, detailsSection, notesSection }, { uploads, artwork, notes }).init();
    new ShortcutsController([ShortcutsController.login, ShortcutsController.preview(() => fillPreview())]).init();

    document.getElementById('editor-preview')?.addEventListener('click', () => fillPreview());

    form.addEventListener('keydown', (e) => {
        if (e.key !== 'Enter' || e.target.tagName !== 'INPUT') return;
        e.preventDefault();
        const focusable = Array.from(form.querySelectorAll('input:not([type="hidden"]), textarea')).filter(el => !el.disabled);
        const idx = focusable.indexOf(e.target);
        if (idx !== -1 && idx < focusable.length - 1) focusable[idx + 1].focus();
    });

    form.addEventListener('submit', (e) => {
        e.preventDefault();
        form.action = typeActions[currentType];
        const f = fields[currentType];
        if (f.releaseDate && f.releaseDateISO) {
            const date = parseReleaseDate(f.releaseDate.value.trim());
            if (date) f.releaseDateISO.value = date.toISOString();
            else f.releaseDateISO.disabled = true;
        }
        persistence.markPendingClear(storageKey);
        form.submit();
    });
});
