// dragAndDrop.js
// GPLv3

const DND = imports.ui.dnd;
const AppDisplay = imports.ui.appDisplay;
const Clutter = imports.gi.Clutter;
const St = imports.gi.St;
const Main = imports.ui.main;
const Mainloop = imports.mainloop;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Convenience = Me.imports.convenience;
const Extension = Me.imports.extension;

const CHANGE_PAGE_TIMEOUT = 400;

const Gettext = imports.gettext.domain('appfolders-manager');
const _ = Gettext.gettext;

//-------------------------------------------------

var OVERLAY_MANAGER;

/* This method is called by extension.js' enable function. It does code injections
 * to AppDisplay.AppIcon, connecting it to DND-related signals.
 */
function initDND () {
	OVERLAY_MANAGER = new OverlayManager();
}

//--------------------------------------------------------------

/* Amazing! A singleton! It allows easy (and safer?) access to general methods,
 * managing other objects: it creates/updates/deletes all overlays (for folders,
 * pages, creation, removing).
 */
class OverlayManager {
	constructor () {
		this.addActions = [];
		this.removeAction = new FolderActionArea('remove');
		this.createAction = new FolderActionArea('create');
		this.upAction = new NavigationArea('up');
		this.downAction = new NavigationArea('down');
		
		this.next_drag_should_recompute = true;
		this.current_width = 0;
	}

	on_drag_begin () {
		this.ensurePopdowned();
		this.ensureFolderOverlayActors();
		this.updateFoldersVisibility();
		this.updateState(true);
	}

	on_drag_end () {
		// force to compute new positions if a drop occurs
		this.next_drag_should_recompute = true;
		this.updateState(false);
	}

	on_drag_cancelled () {
		this.updateState(false);
	}

	updateArrowVisibility () {
		let grid = Main.overview.viewSelector.appDisplay._views[1].view._grid;
		if (grid.currentPage == 0) {
			this.upAction.setActive(false);
		} else {
			this.upAction.setActive(true);
		}
		if (grid.currentPage == grid._nPages -1) {
			this.downAction.setActive(false);
		} else {
			this.downAction.setActive(true);
		}
		this.upAction.show();
		this.downAction.show();
	}

	updateState (isDragging) {
		if (isDragging) {
			this.removeAction.show();
			if (this.openedFolder == null) {
				this.removeAction.setActive(false);
			} else {
				this.removeAction.setActive(true);
			}
			this.createAction.show();
			this.updateArrowVisibility();
		} else {
			this.hideAll();
		}
	}

	hideAll () {
		this.removeAction.hide();
		this.createAction.hide();
		this.upAction.hide();
		this.downAction.hide();
		this.hideAllFolders();
	}

	hideAllFolders () {
		for (var i = 0; i < this.addActions.length; i++) {
			this.addActions[i].hide();
		}
	}

	updateActorsPositions () {
		let monitor = Main.layoutManager.primaryMonitor;
		this.topOfTheGrid = Main.overview.viewSelector.actor.get_parent().get_parent().get_allocation_box().y1;
		let temp = Main.overview.viewSelector.appDisplay._views[1].view.actor.get_parent();
		let bottomOfTheGrid = this.topOfTheGrid + temp.get_allocation_box().y2;
		
		let _availHeight = bottomOfTheGrid - this.topOfTheGrid;
		let _availWidth = Main.overview.viewSelector.appDisplay._views[1].view._grid.actor.width;
		let sideMargin = (monitor.width - _availWidth) / 2;

		let xMiddle = ( monitor.x + monitor.width ) / 2;
		let yMiddle = ( monitor.y + monitor.height ) / 2;

		// Positions of areas
		this.removeAction.setPosition( xMiddle , bottomOfTheGrid );
		this.createAction.setPosition( xMiddle, Main.overview._panelGhost.height );
		this.upAction.setPosition( 0, Main.overview._panelGhost.height );
		this.downAction.setPosition( 0, bottomOfTheGrid );

		// Sizes of areas
		this.removeAction.setSize(xMiddle, monitor.height - bottomOfTheGrid);
		this.createAction.setSize(xMiddle, this.topOfTheGrid - Main.overview._panelGhost.height);
		this.upAction.setSize(xMiddle, this.topOfTheGrid - Main.overview._panelGhost.height);
		this.downAction.setSize(xMiddle, monitor.height - bottomOfTheGrid);

		this.updateArrowVisibility();
	}

	ensureFolderOverlayActors () {
		// A folder was opened, and just closed.
		if (this.openedFolder != null) {
			this.updateActorsPositions();
			this.computeFolderOverlayActors();
			this.next_drag_should_recompute = true;
			return;
		}

		// The grid "moved" or the whole shit needs forced updating
		let allAppsGrid = Main.overview.viewSelector.appDisplay._views[1].view._grid;
		let new_width = allAppsGrid.actor.allocation.get_width();
		if (new_width != this.current_width || this.next_drag_should_recompute) {
			this.next_drag_should_recompute = false;
			this.updateActorsPositions();
			this.computeFolderOverlayActors();
		}
	}

	computeFolderOverlayActors () {
		let monitor = Main.layoutManager.primaryMonitor;
		let xMiddle = ( monitor.x + monitor.width ) / 2;
		let yMiddle = ( monitor.y + monitor.height ) / 2;
		let allAppsGrid = Main.overview.viewSelector.appDisplay._views[1].view._grid;
		
		let nItems = 0;
		let indexes = [];
		let folders = [];
		let x, y;

		Main.overview.viewSelector.appDisplay._views[1].view._allItems.forEach(function(icon) {
			if (icon.actor.visible) {
				if (icon instanceof AppDisplay.FolderIcon) {
					indexes.push(nItems);
					folders.push(icon);
				}
				nItems++;
			}
		});

		this.current_width = allAppsGrid.actor.allocation.get_width();
		let x_correction = (monitor.width - this.current_width)/2;
		let availHeightPerPage = (allAppsGrid.actor.height)/(allAppsGrid._nPages);
		
		for (var i = 0; i < this.addActions.length; i++) {
			this.addActions[i].actor.destroy();
		}

		for (var i = 0; i < indexes.length; i++) {
			let inPageIndex = indexes[i] % allAppsGrid._childrenPerPage;
			let page = Math.floor(indexes[i] / allAppsGrid._childrenPerPage);
			x = folders[i].actor.get_allocation_box().x1;
			y = folders[i].actor.get_allocation_box().y1;

			// Invalid coords (example: when dragging out of the folder) should
			// not produce a visible overlay, a negative page number is an easy
			// way to be sure it stays hidden.
			if (x == 0) {
				page = -1;
			}
			x = Math.floor(x + x_correction);
			y = y + this.topOfTheGrid;
			y = y - (page * availHeightPerPage);

			this.addActions[i] = new FolderArea(folders[i].id, x, y, page);
		}
	}

	updateFoldersVisibility () {
		let appView = Main.overview.viewSelector.appDisplay._views[1].view;
		for (var i = 0; i < this.addActions.length; i++) {
			if ((this.addActions[i].page == appView._grid.currentPage) && (!appView._currentPopup)) {
				this.addActions[i].show();
			} else {
				this.addActions[i].hide();
			}
		}
	}

	ensurePopdowned () {
		let appView = Main.overview.viewSelector.appDisplay._views[1].view;
		if (appView._currentPopup) {
			this.openedFolder = appView._currentPopup._source.id;
			appView._currentPopup.popdown();
		} else {
			this.openedFolder = null;
		}
	}

	goToPage (nb) {
		Main.overview.viewSelector.appDisplay._views[1].view.goToPage( nb );
		this.updateArrowVisibility();
		this.hideAllFolders();
		this.updateFoldersVisibility(); //load folders of the new page
	}

	destroy () {
		for (let i = 0; i > this.addActions.length; i++) {
			this.addActions[i].destroy();
		}
		this.removeAction.destroy();
		this.createAction.destroy();
		this.upAction.destroy();
		this.downAction.destroy();
		//log('OverlayManager destroyed');
	}
};

//-------------------------------------------------------

// Abstract overlay with very generic methods
class DroppableArea {

	constructor (id) {
		this.id = id;
		this.styleClass = 'folderArea';

		this.actor = new St.BoxLayout ({
			width: 10,
			height: 10,
			visible: false,
		});
		this.actor._delegate = this;

		this.lock = true;
		this.use_frame = Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('debug');
	}

	setPosition  (x, y) {
		let monitor = Main.layoutManager.primaryMonitor;
		this.actor.set_position(monitor.x + x, monitor.y + y);
	}

	setSize (w, h) {
		this.actor.width = w;
		this.actor.height = h;
	}

	hide () {
		this.actor.visible = false;
		this.lock = true;
	}

	show () {
		this.actor.visible = true;
	}

	setActive (active) {
		this._active = active;
		if (this._active) {
			this.actor.style_class = this.styleClass;
		} else {
			this.actor.style_class = 'insensitiveArea';
		}
	}

	destroy () {
		this.actor.destroy();
	}
}

/* Overlay representing an "action". Actions can be creating a folder, or
 * removing an app from a folder. These areas accept drop, and display a label.
 */
class FolderActionArea extends DroppableArea {
	constructor (id) {
		super(id);

		let x, y, label;

		switch (this.id) {
			case 'create':
				label = _("Create a new folder");
				this.styleClass = 'shadowedAreaTop';
			break;
			case 'remove':
				label = '';
				this.styleClass = 'shadowedAreaBottom';
			break;
			default:
				label = 'invalid id';
			break;
		}
		if (this.use_frame) {
			this.styleClass = 'framedArea';
		}
		this.actor.style_class = this.styleClass;

		this.label = new St.Label({
			text: label,
			style_class: 'dropAreaLabel',
			x_expand: true,
			y_expand: true,
			x_align: Clutter.ActorAlign.CENTER,
			y_align: Clutter.ActorAlign.CENTER,
		});
		this.actor.add(this.label);

		this.setPosition(10, 10);
		Main.layoutManager.overviewGroup.add_actor(this.actor);
	}

	getRemoveLabel () {
		let label;
		if (OVERLAY_MANAGER.openedFolder == null) {
			label = '…';
		} else {
			let folder_schema = Extension.folderSchema (OVERLAY_MANAGER.openedFolder);
			label = folder_schema.get_string('name');
		}
		return (_("Remove from %s")).replace('%s', label);
	}

	setActive (active) {
		super.setActive(active);
		if (this.id == 'remove') {
			this.label.text = this.getRemoveLabel();
		}
	}

	handleDragOver (source, actor, x, y, time) {
		if (source instanceof AppDisplay.AppIcon && this._active) {
			return DND.DragMotionResult.MOVE_DROP;
		}
		Main.overview.endItemDrag(this);
		return DND.DragMotionResult.NO_DROP;
	}

	acceptDrop (source, actor, x, y, time) {
		if ((source instanceof AppDisplay.AppIcon) && (this.id == 'create')) {
			Extension.createNewFolder(source);
			Main.overview.endItemDrag(this);
			return true;
		}
		if ((source instanceof AppDisplay.AppIcon) && (this.id == 'remove')) {
			this.removeApp(source);
			Main.overview.endItemDrag(this);
			return true;
		}
		Main.overview.endItemDrag(this);
		return false;
	}

	removeApp (source) {
		let id = source.app.get_id();
		Extension.removeFromFolder(id, OVERLAY_MANAGER.openedFolder);
		OVERLAY_MANAGER.updateState(false);
		Main.overview.viewSelector.appDisplay._views[1].view._redisplay();
	}

	destroy () {
		this.label.destroy();
		super.destroy();
	}
};

/* Overlay reacting to hover, but isn't droppable. The goal is to go to an other
 * page of the grid while dragging an app.
 */
class NavigationArea extends DroppableArea {
	constructor (id) {
		super(id);

		let x, y, i;
		switch (this.id) {
			case 'up':
				i = 'pan-up-symbolic';
				this.styleClass = 'shadowedAreaTop';
			break;
			case 'down':
				i = 'pan-down-symbolic';
				this.styleClass = 'shadowedAreaBottom';
			break;
			default:
				i = 'dialog-error-symbolic';
			break;
		}
		if (this.use_frame) {
			this.styleClass = 'framedArea';
		}
		this.actor.style_class = this.styleClass;

		this.actor.add(new St.Icon({
			icon_name: i,
			icon_size: 24,
			style_class: 'system-status-icon',
			x_expand: true,
			y_expand: true,
			x_align: Clutter.ActorAlign.CENTER,
			y_align: Clutter.ActorAlign.CENTER,
		}));

		this.setPosition(x, y);
		Main.layoutManager.overviewGroup.add_actor(this.actor);
	}

	handleDragOver (source, actor, x, y, time) {
		if (this.id == 'up' && this._active) {
			this.pageUp();
			return DND.DragMotionResult.CONTINUE;
		}

		if (this.id == 'down' && this._active) {
			this.pageDown();
			return DND.DragMotionResult.CONTINUE;
		}

		Main.overview.endItemDrag(this);
		return DND.DragMotionResult.NO_DROP;
	}

	pageUp () {
		if(this.lock && !this.timeoutSet) {
			this._timeoutId = Mainloop.timeout_add(CHANGE_PAGE_TIMEOUT, this.unlock.bind(this));
			this.timeoutSet = true;
		}
		if(!this.lock) {
			let currentPage = Main.overview.viewSelector.appDisplay._views[1].view._grid.currentPage;
			this.lock = true;
			OVERLAY_MANAGER.goToPage(currentPage - 1);
		}
	}

	pageDown () {
		if(this.lock && !this.timeoutSet) {
			this._timeoutId = Mainloop.timeout_add(CHANGE_PAGE_TIMEOUT, this.unlock.bind(this));
			this.timeoutSet = true;
		}
		if(!this.lock) {
			let currentPage = Main.overview.viewSelector.appDisplay._views[1].view._grid.currentPage;
			this.lock = true;
			OVERLAY_MANAGER.goToPage(currentPage + 1);
		}
	}

	acceptDrop (source, actor, x, y, time) {
		Main.overview.endItemDrag(this);
		return false;
	}

	unlock () {
		this.lock = false;
		this.timeoutSet = false;
		Mainloop.source_remove(this._timeoutId);
	}
};

/* This overlay is the area upon a folder. Position and visibility of the actor
 * is handled by exterior functions.
 * "this.id" is the folder's id, a string, as written in the gsettings key.
 * Dropping an app on this folder will add it to the folder
 */
class FolderArea extends DroppableArea {
	constructor (id, asked_x, asked_y, page) {
		super(id);
		this.page = page;

		let grid = Main.overview.viewSelector.appDisplay._views[1].view._grid;
		this.actor.width = grid._getHItemSize();
		this.actor.height = grid._getVItemSize();

		if (this.use_frame) {
			this.styleClass = 'framedArea';
			this.actor.add(new St.Label({
				text: this.id,
				x_expand: true,
				y_expand: true,
				x_align: Clutter.ActorAlign.CENTER,
				y_align: Clutter.ActorAlign.CENTER,
			}));
		} else {
			this.styleClass = 'folderArea';
			this.actor.add(new St.Icon({
				icon_name: 'list-add-symbolic',
				icon_size: 24,
				style_class: 'system-status-icon',
				x_expand: true,
				y_expand: true,
				x_align: Clutter.ActorAlign.CENTER,
				y_align: Clutter.ActorAlign.CENTER,
			}));
		}
		if (this.use_frame) {
			this.styleClass = 'framedArea';
		}
		this.actor.style_class = this.styleClass;

		this.setPosition(asked_x, asked_y);
		Main.layoutManager.overviewGroup.add_actor(this.actor);
	}

	handleDragOver (source, actor, x, y, time) {
		if (source instanceof AppDisplay.AppIcon) {
			return DND.DragMotionResult.MOVE_DROP;
		}
		Main.overview.endItemDrag(this);
		return DND.DragMotionResult.NO_DROP;
	}

	acceptDrop (source, actor, x, y, time) { //FIXME recharger la vue ou au minimum les miniatures des dossiers
		if ((source instanceof AppDisplay.AppIcon) &&
		                            !Extension.isInFolder(source.id, this.id)) {
			Extension.addToFolder(source, this.id);
			Main.overview.endItemDrag(this);
			return true;
		}
		Main.overview.endItemDrag(this);
		return false;
	}
};

