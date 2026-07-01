/**
 * QuoteShareController
 *
 * Handles share button clicks inside a container via event delegation.
 * Any `.quote-share` button click within the container triggers a share.
 * Uses the Web Share API when available; falls back to clipboard copy with
 * a brief "Copied!" aria-label feedback on the clicked button.
 *
 * `getQuoteId(button)` receives the clicked button element and returns
 * the quote's UUID string (or null). For a single-article page, the button
 * argument can be ignored and the article's dataset read directly.
 *
 * Lifecycle: init() once on DOMContentLoaded; destroy() if needed.
 */
class QuoteShareController {

    constructor({ container }, { getQuoteId } = {}) {
        this.container = container;
        this.getQuoteId = getQuoteId ?? (() => null);
        this._feedbackTimer = null;
        this._onClick = this.onClick.bind(this);
    }

    init() {
        this.container.addEventListener('click', this._onClick);
    }

    destroy() {
        this.container.removeEventListener('click', this._onClick);
        clearTimeout(this._feedbackTimer);
    }

    async onClick(event) {
        const button = event.target.closest('.quote-share');
        if (!button) return;

        const id = this.getQuoteId(button);
        if (!id) return;

        const url = `${location.origin}/quotes/${id}`;

        if (navigator.share) {
            try {
                await navigator.share({ url });
            } catch (err) {
                // AbortError = user dismissed the share sheet — expected, not an error.
                if (err.name !== 'AbortError') console.warn('share failed', err);
            }
        } else {
            try {
                await navigator.clipboard.writeText(url);
                this._showCopied(button);
            } catch (err) {
                console.warn('clipboard copy failed', err);
            }
        }
    }

    _showCopied(button) {
        const original = button.getAttribute('aria-label');
        button.setAttribute('aria-label', 'Copied!');
        button.classList.add('active');
        clearTimeout(this._feedbackTimer);
        this._feedbackTimer = setTimeout(() => {
            button.setAttribute('aria-label', original);
            button.classList.remove('active');
        }, 2000);
    }
}
