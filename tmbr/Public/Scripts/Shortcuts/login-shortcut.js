document.addEventListener('DOMContentLoaded', () => {
    document.addEventListener('keydown', (event) => {
        try {
            let isL = event.key === 'l' || event.key === 'L'
            let isNonModifier = !event.metaKey && !event.ctrlKey && !event.altKey && !event.shiftKey
            if (isL && isNonModifier) {
                let redirect = encodeURIComponent(window.location.pathname + window.location.search);
                event.preventDefault();
                window.location.assign('/signin?redirectReturn=' + redirect);
            }
        } catch (_) {
            // ignore
        }
    });
});
