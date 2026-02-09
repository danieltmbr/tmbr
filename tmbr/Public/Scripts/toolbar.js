class ToolbarController {
    constructor({ toolbar, newItemButton, newItemCloseButton, newItemsPanel }) {
        this.toolbar = toolbar;
        this.newItemButton = newItemButton;
        this.newItemCloseButton = newItemCloseButton;
        this.newItemsPanel = newItemsPanel;
        this._onNewItemClick = this.openNewItemsPanel.bind(this);
        this._onCloseClick = this.closeNewItemsPanel.bind(this);
    }
    
    init() {
        this.newItemButton.addEventListener('click', this._onNewItemClick);
        this.newItemCloseButton.addEventListener('click', this._onCloseClick);
    }
    
    destroy() {
        this.newItemButton.removeEventListener('click', this._onNewItemClick);
        this.newItemCloseButton.removeEventListener('click', this._onCloseClick);
    }
    
    toggle() {
        if (this.newItemsPanel.classList.contains("open")) {
            this.close();
        } else {
            this.open();
        }
    }
    
    openNewItemsPanel() {
        this.newItemsPanel.classList.add("open");
    }
    
    closeNewItemsPanel() {
        this.newItemsPanel.classList.remove("open");
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

