class ToolbarController {
    constructor({ toolbar, newItemButton, newItemCloseButton, newItemsPanel }) {
        this.toolbar = toolbar;
        this.newItemButton = newItemButton;
        this.newItemCloseButton = newItemCloseButton;
        this.newItemsPanel = newItemsPanel;
        this._onNewItemClick = this.openNewItemsPanel.bind(this);
        this._onCloseClick = this.closeNewItemsPanel.bind(this);
        this._onOutsideClick = this._handleOutsideClick.bind(this);
    }

    init() {
        this.newItemButton.addEventListener('click', this._onNewItemClick);
        this.newItemCloseButton.addEventListener('click', this._onCloseClick);
    }

    destroy() {
        this.newItemButton.removeEventListener('click', this._onNewItemClick);
        this.newItemCloseButton.removeEventListener('click', this._onCloseClick);
        document.removeEventListener('click', this._onOutsideClick);
    }

    openNewItemsPanel() {
        this.newItemsPanel.classList.add("open");
        setTimeout(() => {
            document.addEventListener('click', this._onOutsideClick);
        }, 0);
    }

    closeNewItemsPanel() {
        this.newItemsPanel.classList.remove("open");
        document.removeEventListener('click', this._onOutsideClick);
    }

    _handleOutsideClick(e) {
        if (!this.newItemsPanel.contains(e.target) && !this.newItemButton.contains(e.target)) {
            this.closeNewItemsPanel();
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const toolbar = document.getElementById('toolbar');
    const newItemButton = document.getElementById('new-item');
    const newItemCloseButton = document.getElementById('new-item-close');
    const newItemsPanel = document.getElementById('new-items');

    const editor = new ToolbarController({
        toolbar,
        newItemButton,
        newItemCloseButton,
        newItemsPanel,
    });
    editor.init();
});

