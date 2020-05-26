// appfolderDialog.js
// GPLv3

const Clutter = imports.gi.Clutter;
const Gio = imports.gi.Gio;
const St = imports.gi.St;
const Main = imports.ui.main;
const ModalDialog = imports.ui.modalDialog;
const PopupMenu = imports.ui.popupMenu;
const ShellEntry = imports.ui.shellEntry;
const Signals = imports.signals;
const Gtk = imports.gi.Gtk;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Convenience = Me.imports.convenience;
const Extension = Me.imports.extension;

const Gettext = imports.gettext.domain('appfolders-manager');
const _ = Gettext.gettext;

let FOLDER_SCHEMA;
let FOLDER_LIST;

//--------------------------------------------------------------

// This is a modal dialog for creating a new folder, or renaming or modifying
// categories of existing folders.
var AppfolderDialog = class AppfolderDialog {

	// build a new dialog. If folder is null, the dialog will be for creating a new
	// folder, else app is null, and the dialog will be for editing an existing folder
	constructor (folder, app, id) {
		this._folder = folder;
		this._app = app;
		this._id = id;
		this.super_dialog = new ModalDialog.ModalDialog({ destroyOnClose: true });

		FOLDER_SCHEMA = new Gio.Settings({ schema_id: 'org.gnome.desktop.app-folders' });
		FOLDER_LIST = FOLDER_SCHEMA.get_strv('folder-children');

		let nameSection = this._buildNameSection();
		let categoriesSection = this._buildCategoriesSection();

		this.super_dialog.contentLayout.style = 'spacing: 20px';
		this.super_dialog.contentLayout.add(nameSection, {
			x_fill: false,
			x_align: St.Align.START,
			y_align: St.Align.START
		});
		if ( Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('categories') ) {
			this.super_dialog.contentLayout.add(categoriesSection, {
				x_fill: false,
				x_align: St.Align.START,
				y_align: St.Align.START
			});
		}

		if (this._folder == null) {
			this.super_dialog.setButtons([
				{ action: this.destroy.bind(this),
				label: _("Cancel"),
				key: Clutter.Escape },
	
				{ action: this._apply.bind(this),
				label: _("Create"),
				key: Clutter.Return }
			]);
		} else {
			this.super_dialog.setButtons([
				{ action: this.destroy.bind(this),
				label: _("Cancel"),
				key: Clutter.Escape },
	
				{ action: this._deleteFolder.bind(this),
				label: _("Delete"),
				key: Clutter.Delete },
	
				{ action: this._apply.bind(this),
				label: _("Apply"),
				key: Clutter.Return }
			]);
		}

		this._nameEntryText.connect('key-press-event', (o, e) => {
			let symbol = e.get_key_symbol();

			if (symbol == Clutter.Return || symbol == Clutter.KP_Enter) {
				this.super_dialog.popModal();
				this._apply();
			}
		});
	}

	// build the section of the UI handling the folder's name and returns it.
	_buildNameSection () {
		let nameSection = new St.BoxLayout({
			style: 'spacing: 5px;',
			vertical: true,
			x_expand: true,
			natural_width_set: true,
			natural_width: 350,
		});

		let nameLabel = new St.Label({
			text: _("Folder's name:"),
			style: 'font-weight: bold;',
		});
		nameSection.add(nameLabel, { y_align: St.Align.START });

		this._nameEntry = new St.Entry({
			x_expand: true,
		});
		this._nameEntryText = null; ///???
		this._nameEntryText = this._nameEntry.clutter_text;

		nameSection.add(this._nameEntry, { y_align: St.Align.START });
		ShellEntry.addContextMenu(this._nameEntry);
		this.super_dialog.setInitialKeyFocus(this._nameEntryText);

		if (this._folder != null) {
			this._nameEntryText.set_text(this._folder.get_string('name'));
		}

		return nameSection;
	}

	// build the section of the UI handling the folder's categories and returns it.
	_buildCategoriesSection () {
		let categoriesSection = new St.BoxLayout({
			style: 'spacing: 5px;',
			vertical: true,
			x_expand: true,
			natural_width_set: true,
			natural_width: 350,
		});

		let categoriesLabel = new St.Label({
			text: _("Categories:"),
			style: 'font-weight: bold;',
		});
		categoriesSection.add(categoriesLabel, {
			x_fill: false,
			x_align: St.Align.START,
			y_align: St.Align.START,
		});

		let categoriesBox = new St.BoxLayout({
			style: 'spacing: 5px;',
			vertical: false,
			x_expand: true,
		});

		// at the left, how to add categories
		let addCategoryBox = new St.BoxLayout({
			style: 'spacing: 5px;',
			vertical: true,
			x_expand: true,
		});

		this._categoryEntry = new St.Entry({
			can_focus: true,
			x_expand: true,
			hint_text: _("Other category?"),
			secondary_icon: new St.Icon({
				icon_name: 'list-add-symbolic',
				icon_size: 16,
				style_class: 'system-status-icon',
				y_align: Clutter.ActorAlign.CENTER,
			}),
		});
		ShellEntry.addContextMenu(this._categoryEntry, null);
		this._categoryEntry.connect('secondary-icon-clicked', this._addCategory.bind(this));

		this._categoryEntryText = null; ///???
		this._categoryEntryText = this._categoryEntry.clutter_text;
		this._catSelectButton = new SelectCategoryButton(this);

		addCategoryBox.add(this._catSelectButton.actor, { y_align: St.Align.CENTER });
		addCategoryBox.add(this._categoryEntry, { y_align: St.Align.START });
		categoriesBox.add(addCategoryBox, {
			x_fill: true,
			x_align: St.Align.START,
			y_align: St.Align.START,
		});

		// at the right, a list of categories
		this.listContainer = new St.BoxLayout({
			vertical: true,
			x_expand: true,
		});
		this.noCatLabel = new St.Label({ text: _("No category") });
		this.listContainer.add_actor(this.noCatLabel);
		categoriesBox.add(this.listContainer, {
			x_fill: true,
			x_align: St.Align.END,
			y_align: St.Align.START,
		});

		categoriesSection.add(categoriesBox, {
			x_fill: true,
			x_align: St.Align.START,
			y_align: St.Align.START,
		});

		// Load categories is necessary even if no this._folder,
		// because it initializes the value of this._categories
		this._loadCategories();

		return categoriesSection;
	}

	open () {
		this.super_dialog.open();
	}

	// returns if a folder id already exists
	_alreadyExists (folderId) {
		for(var i = 0; i < FOLDER_LIST.length; i++) {
			if (FOLDER_LIST[i] == folderId) {
//				this._showError( _("This appfolder already exists.") );
				return true;
			}
		}
		return false;
	}

	destroy () {
		if ( Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('debug') ) {
			log('[AppfolderDialog v2] destroying dialog');
		}
		this._catSelectButton.destroy(); // TODO ?
		this.super_dialog.destroy(); //XXX crée des erreurs reloues ???
	}

	// Generates a valid folder id, which as no space, no dot, no slash, and which
	// doesn't already exist.
	_folderId (newName) {
		let tmp0 = newName.split(" ");
		let folderId = "";
		for(var i = 0; i < tmp0.length; i++) {
			folderId += tmp0[i];
		}
		tmp0 = folderId.split(".");
		folderId = "";
		for(var i = 0; i < tmp0.length; i++) {
			folderId += tmp0[i];
		}
		tmp0 = folderId.split("/");
		folderId = "";
		for(var i = 0; i < tmp0.length; i++) {
			folderId += tmp0[i];
		}
		if(this._alreadyExists(folderId)) {
			folderId = this._folderId(folderId+'_');
		}
		return folderId;
	}

	// creates a folder from the data filled by the user (with no properties)
	_create () {
		let folderId = this._folderId(this._nameEntryText.get_text());

		FOLDER_LIST.push(folderId);
		FOLDER_SCHEMA.set_strv('folder-children', FOLDER_LIST);

		this._folder = new Gio.Settings({
			schema_id: 'org.gnome.desktop.app-folders.folder',
			path: '/org/gnome/desktop/app-folders/folders/' + folderId + '/'
		});
	//	this._folder.set_string('name', this._nameEntryText.get_text()); //superflu
	//	est-il nécessaire d'initialiser la clé apps à [] ??
		this._addToFolder();
	}

	// sets the name to the folder
	_applyName () {
		let newName = this._nameEntryText.get_text();
		this._folder.set_string('name', newName); // génère un bug ?
		return Clutter.EVENT_STOP;
	}

	// loads categories, as set in gsettings, to the UI
	_loadCategories () {
		if (this._folder == null) {
			this._categories = [];
		} else {
			this._categories = this._folder.get_strv('categories');
			if ((this._categories == null) || (this._categories.length == 0)) {
				this._categories = [];
			} else {
				this.noCatLabel.visible = false;
			}
		}
		this._categoriesButtons = [];
		for (var i = 0; i < this._categories.length; i++) {
			this._addCategoryBox(i);
		}
	}

	_addCategoryBox (i) {
		let aCategory = new AppCategoryBox(this, i);
		this.listContainer.add_actor(aCategory.super_box);
	}

	// adds a category to the UI (will be added to gsettings when pressing "apply" only)
	_addCategory (entry, new_cat_name) {
		if (new_cat_name == null) {
			new_cat_name = this._categoryEntryText.get_text();
		}
		if (this._categories.indexOf(new_cat_name) != -1) {
			return;
		}
		if (new_cat_name == '') {
			return;
		}
		this._categories.push(new_cat_name);
		this._categoryEntryText.set_text('');
		this.noCatLabel.visible = false;
		this._addCategoryBox(this._categories.length-1);
	}

	// adds all categories to gsettings
	_applyCategories () {
		this._folder.set_strv('categories', this._categories);
		return Clutter.EVENT_STOP;
	}

	// Apply everything by calling methods above, and reload the view
	_apply () {
		if (this._app != null) {
			this._create();
		//	this._addToFolder();
		}
		this._applyCategories();
		this._applyName();
		this.destroy();
		//-----------------------
		Main.overview.viewSelector.appDisplay._views[1].view._redisplay();
		if ( Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('debug') ) {
			log('[AppfolderDialog v2] reload the view');
		}
	}

	// initializes the folder with its first app. This is not optional since empty
	// folders are not displayed. TODO use the equivalent method from extension.js
	_addToFolder () {
		let content = this._folder.get_strv('apps');
		content.push(this._app);
		this._folder.set_strv('apps', content);
	}

	// Delete the folder, using the extension.js method
	_deleteFolder () {
		if (this._folder != null) {
			Extension.deleteFolder(this._id);
		}
		this.destroy();
	}
};

//------------------------------------------------

// Very complex way to have a menubutton for displaying a menu with standard
// categories. Button part.
class SelectCategoryButton {
	constructor (dialog) {
		this._dialog = dialog;

		let catSelectBox = new St.BoxLayout({
			vertical: false,
			x_expand: true,
		});
		let catSelectLabel = new St.Label({
			text: _("Select a category…"),
			x_align: Clutter.ActorAlign.START,
			y_align: Clutter.ActorAlign.CENTER,
			x_expand: true,
		});
		let catSelectIcon = new St.Icon({
			icon_name: 'pan-down-symbolic',
			icon_size: 16,
			style_class: 'system-status-icon',
			x_expand: false,
			x_align: Clutter.ActorAlign.END,
			y_align: Clutter.ActorAlign.CENTER,
		});
		catSelectBox.add(catSelectLabel, { y_align: St.Align.MIDDLE });
		catSelectBox.add(catSelectIcon, { y_align: St.Align.END });
		this.actor = new St.Button ({
			x_align: Clutter.ActorAlign.CENTER,
			y_align: Clutter.ActorAlign.CENTER,
			child: catSelectBox,
			style_class: 'button',
			style: 'padding: 5px 5px;',
			x_expand: true,
			y_expand: false,
			x_fill: true,
			y_fill: true,
		});
		this.actor.connect('button-press-event', this._onButtonPress.bind(this));

		this._menu = null;
		this._menuManager = new PopupMenu.PopupMenuManager(this);
	}

	popupMenu () {
		this.actor.fake_release();
		if (!this._menu) {
			this._menu = new SelectCategoryMenu(this, this._dialog);
			this._menu.super_menu.connect('open-state-changed', (menu, isPoppedUp) => {
				if (!isPoppedUp) {
					this.actor.sync_hover();
					this.emit('menu-state-changed', false);
				}
			});
			this._menuManager.addMenu(this._menu.super_menu);
		}
		this.emit('menu-state-changed', true);
		this.actor.set_hover(true);
		this._menu.popup();
		this._menuManager.ignoreRelease();
		return false;
	}

	_onButtonPress (actor, event) {
		this.popupMenu();
		return Clutter.EVENT_STOP;
	}

	destroy () {
		if (this._menu) {
			this._menu.destroy();
		}
		this.actor.destroy();
	}
};
Signals.addSignalMethods(SelectCategoryButton.prototype);

//------------------------------------------------

// Very complex way to have a menubutton for displaying a menu with standard
// categories. Menu part.
class SelectCategoryMenu {
	constructor (source, dialog) {
		this.super_menu = new PopupMenu.PopupMenu(source.actor, 0.5, St.Side.RIGHT);
		this._source = source;
		this._dialog = dialog;
		this.super_menu.actor.add_style_class_name('app-well-menu');
		this._source.actor.connect('destroy', this.super_menu.destroy.bind(this));

		// We want to keep the item hovered while the menu is up //XXX used ??
		this.super_menu.blockSourceEvents = true;

		Main.uiGroup.add_actor(this.super_menu.actor);
		
		// This is a really terrible hack to overwrite _redisplay without
		// actually inheriting from PopupMenu.PopupMenu
		this.super_menu._redisplay = this._redisplay;
		this.super_menu._dialog = this._dialog;
	}

	_redisplay () {
		this.removeAll();
		let mainCategories = ['AudioVideo', 'Audio', 'Video', 'Development',
		        'Education', 'Game', 'Graphics', 'Network', 'Office', 'Science',
		                                       'Settings', 'System', 'Utility'];
		for (var i=0; i<mainCategories.length; i++) {
			let labelItem = mainCategories[i] ;
			let item = new PopupMenu.PopupMenuItem( labelItem );
			item.connect('activate', () => {
				this._dialog._addCategory(null, labelItem);
			});
			this.addMenuItem(item);
		}
	}

	popup (activatingButton) {
		this.super_menu._redisplay();
		this.super_menu.open();
	}

	destroy () {
		this.super_menu.close(); //FIXME error in the logs but i don't care
		this.super_menu.destroy();
	}
};
Signals.addSignalMethods(SelectCategoryMenu.prototype);

//----------------------------------------

// This custom widget is a deletable row, displaying a category name.
class AppCategoryBox {
	constructor (dialog, i) {
		this.super_box = new St.BoxLayout({
			vertical: false,
			style_class: 'appCategoryBox',
		});
		this._dialog = dialog;
		this.catName = this._dialog._categories[i];
		this.super_box.add_actor(new St.Label({
			text: this.catName,
			y_align: Clutter.ActorAlign.CENTER,
			x_align: Clutter.ActorAlign.CENTER,
		}));
		this.super_box.add_actor( new St.BoxLayout({ x_expand: true }) );
		this.deleteButton = new St.Button({
			x_expand: false,
			y_expand: true,
			style_class: 'appCategoryDeleteBtn',
			y_align: Clutter.ActorAlign.CENTER,
			x_align: Clutter.ActorAlign.CENTER,
			child: new St.Icon({
				icon_name: 'edit-delete-symbolic',
				icon_size: 16,
				style_class: 'system-status-icon',
				x_expand: false,
				y_expand: true,
				style: 'margin: 3px;',
				y_align: Clutter.ActorAlign.CENTER,
				x_align: Clutter.ActorAlign.CENTER,
			}),
		});
		this.super_box.add_actor(this.deleteButton);
		this.deleteButton.connect('clicked', this.removeFromList.bind(this));
	}

	removeFromList () {
		this._dialog._categories.splice(this._dialog._categories.indexOf(this.catName), 1);
		if (this._dialog._categories.length == 0) {
			this._dialog.noCatLabel.visible = true;
		}
		this.destroy();
	}

	destroy () {
		this.deleteButton.destroy();
		this.super_box.destroy();
	}
};


