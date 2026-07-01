/**
 * QuoteImmersionController
 *
 * Fades page chrome (nav, title, footer) after a period of cursor inactivity,
 * leaving only the quote visible. The tmbr logo is not included in the fade set.
 * Cursor movement reveals chrome and resets the idle timer. Scrolling
 * intentionally does NOT reveal chrome — it only advances the quote.
 *
 * Pass `hold` (the section <nav>) to prevent hiding while the cursor is over
 * those controls or the search field is focused.
 *
 * Lifecycle: init() in enterFocused(), destroy() in enterList() /
 * controller.destroy(). On the random page, init() is called once on load.
 */
class QuoteImmersionController {

    constructor({ timeout = 1200, hold = null } = {}) {
        this.timeout = timeout;
        this.hold = hold;
        this._idleTimer = null;
        this._onMove = this.onMove.bind(this);
    }

    init() {
        window.addEventListener('mousemove', this._onMove, { passive: true });
        window.addEventListener('touchstart', this._onMove, { passive: true });
        // Begin the idle countdown immediately — the user may not move the
        // cursor at all after the page loads.
        this._scheduleHide();
    }

    destroy() {
        window.removeEventListener('mousemove', this._onMove);
        window.removeEventListener('touchstart', this._onMove);
        clearTimeout(this._idleTimer);
        // Restore chrome so switching to list mode doesn't leave the page faded.
        document.body.classList.remove('quotes-immersive');
    }

    onMove() {
        document.body.classList.remove('quotes-immersive');
        this._scheduleHide();
    }

    // Returns true if the user is hovering the held element or has focus inside
    // it (e.g. the search input is active). In that case we reschedule instead
    // of hiding, so we never fade out controls the user is currently using.
    _isHeld() {
        return !!this.hold && (
            this.hold.matches(':hover') ||
            this.hold.contains(document.activeElement)
        );
    }

    _scheduleHide() {
        clearTimeout(this._idleTimer);
        this._idleTimer = setTimeout(() => {
            if (this._isHeld()) {
                // Controls are in use — reschedule and keep checking.
                this._scheduleHide();
                return;
            }
            document.body.classList.add('quotes-immersive');
        }, this.timeout);
    }
}
