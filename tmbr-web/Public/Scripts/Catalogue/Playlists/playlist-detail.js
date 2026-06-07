document.addEventListener('DOMContentLoaded', () => {
    const tracksSection = document.getElementById('tracks-section');
    if (!tracksSection) return;

    const syncEndpoint = tracksSection.dataset.syncEndpoint;
    if (!syncEndpoint) return;

    const syncBanner = document.getElementById('sync-banner');
    if (!syncBanner) return;

    // Collect the current tracklist URLs from data attributes
    const currentURLs = Array.from(
        tracksSection.querySelectorAll('li[data-track-url]')
    ).map(li => li.dataset.trackUrl);

    // Find the Apple Music URL from the resources section
    const appleMusicLink = document.querySelector('a[href*="music.apple.com"]');
    if (!appleMusicLink) return;

    const metadataEndpoint = '/playlists/metadata?url=' + encodeURIComponent(appleMusicLink.href);

    fetch(metadataEndpoint)
        .then(res => res.ok ? res.json() : null)
        .then(data => {
            if (!data || !Array.isArray(data.tracks)) return;
            const remoteURLs = data.tracks.map(t => t.url).filter(Boolean);
            if (remoteURLs.length === 0) return;

            const changed = remoteURLs.length !== currentURLs.length
                || remoteURLs.some((url, i) => url !== currentURLs[i]);

            if (changed) syncBanner.removeAttribute('hidden');
        })
        .catch(() => { /* ignore network errors silently */ });
});
