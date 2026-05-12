class ResourceInputsController {
    constructor({ section }, { onUrlChange, onInput }) {
        this.section = section;
        this.onUrlChange = onUrlChange;
        this.onInputCallback = onInput;
        this._onInput = this.onInput.bind(this);
        this._onChange = this.onChange.bind(this);
        this._onPaste = this.onPaste.bind(this);
        this.inputListeners = [];
    }

    init() {
        this.getInputs().forEach((input) => this.attachListener(input));
    }

    destroy() {
        this.inputListeners.forEach(({ input }) => {
            input.removeEventListener('input', this._onInput);
            input.removeEventListener('change', this._onChange);
            input.removeEventListener('paste', this._onPaste);
        });
        this.inputListeners = [];
    }

    getInputs() {
        return Array.from(this.section.querySelectorAll('input.resource-url'));
    }

    getValues() {
        return this.getInputs()
            .map(input => input.value.trim())
            .filter(url => url.length > 0);
    }

    setValues(urls) {
        if (!Array.isArray(urls)) return;
        urls.forEach((url, index) => {
            const inputs = this.getInputs();
            if (inputs[index]) {
                if (!inputs[index].value) inputs[index].value = url;
            } else {
                const newInput = this.createInput();
                newInput.value = url;
                this.section.appendChild(newInput);
                this.attachListener(newInput);
            }
        });
        if (!this.getInputs().some(i => !i.value.trim())) {
            const newInput = this.createInput();
            this.section.appendChild(newInput);
            this.attachListener(newInput);
        }
    }

    attachListener(input) {
        input.addEventListener('input', this._onInput);
        input.addEventListener('change', this._onChange);
        input.addEventListener('paste', this._onPaste);
        this.inputListeners.push({ input });
    }

    detachListener(input) {
        input.removeEventListener('input', this._onInput);
        input.removeEventListener('change', this._onChange);
        input.removeEventListener('paste', this._onPaste);
        this.inputListeners = this.inputListeners.filter((entry) => entry.input !== input);
    }

    createInput() {
        const input = document.createElement('input');
        input.className = 'text-input resource-url';
        input.dataset.autofillSource = 'true';
        input.type = 'url';
        input.name = 'resourceURLs[]';
        input.value = '';
        input.placeholder = 'https://…';
        return input;
    }

    onInput(event) {
        const input = event.target;
        const inputs = this.getInputs();
        const emptyInputs = inputs.filter((i) => !i.value.trim());

        if (input.value.trim() && emptyInputs.length === 0) {
            const newInput = this.createInput();
            this.section.appendChild(newInput);
            this.attachListener(newInput);
        } else if (!input.value.trim() && emptyInputs.length > 1) {
            this.detachListener(input);
            input.remove();
        }

        if (typeof this.onInputCallback === 'function') {
            this.onInputCallback();
        }
    }

    onChange(event) {
        const url = (event.target.value || '').trim();
        if (url && typeof this.onUrlChange === 'function') {
            this.onUrlChange(url);
        }
    }

    onPaste(event) {
        setTimeout(() => {
            const url = (event.target.value || '').trim();
            if (url && typeof this.onUrlChange === 'function') {
                this.onUrlChange(url);
            }
        }, 0);
    }
}
