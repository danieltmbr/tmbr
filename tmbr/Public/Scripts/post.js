document.addEventListener('DOMContentLoaded', () => {

    document.addEventListener('keydown', (event) => {
        try {
            let isE = event.key === 'e' || event.key === 'E'
            let isNonModifier = !event.metaKey && !event.ctrlKey && !event.altKey && !event.shiftKey
            if (isE && isNonModifier) {
                let editURL = window.location.href + "/edit";
                event.preventDefault();
                window.location.assign(editURL);
            }
        } catch (_) {
            // ignore
        }
    });
});
