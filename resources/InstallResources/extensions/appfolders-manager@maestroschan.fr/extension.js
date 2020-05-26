// extension.js
// GPLv3

const Clutter = imports.gi.Clutter;
const Gio = imports.gi.Gio;
const St = imports.gi.St;
const Main = imports.ui.main;
const AppDisplay = imports.ui.appDisplay;
const PopupMenu = imports.ui.popupMenu;
const Meta = imports.gi.Meta;
const Mainloop = imports.mainloop;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Convenience = Me.imports.convenience;

const AppfolderDialog = Me.imports.appfolderDialog;
const DragAndDrop = Me.imports.dragAndDrop;

const Gettext = imports.gettext.domain('appfolders-manager');
const _ = Gettext.gettext;

let FOLDER_SCHEMA;
let FOLDER_LIST;

let INIT_TIME;

function init () {
	Convenience.initTranslations();
	INIT_TIME = getTimeStamp();
}

function getTimeStamp () {
	let today = new Date();
	let str = today.getDate() + '' + today.getHours() + '' + today.getMinutes()
	                                                  + '' + today.getSeconds();
	return parseInt(str);
}

//------------------------------------------------------------------------------
/* do not edit this section */

function injectToFunction(parent, name, func) {
	let origin = parent[name];
	parent[name] = function() {
		let ret;
		ret = origin.apply(this, arguments);
			if (ret === undefined)
				ret = func.apply(this, arguments);
			return ret;
		}
	return origin;
}

function removeInjection(object, injection, name) {
	if (injection[name] === undefined)
		delete object[name];
	else
		object[name] = injection[name];
}

var injections=[];

//------------------------------------------------------------------------------

/* this function injects items (1 or 2 submenus) in AppIconMenu's _redisplay method. */
function injectionInAppsMenus() {
	injections['_redisplay'] = injectToFunction(AppDisplay.AppIconMenu.prototype, '_redisplay', function() {
		if (Main.overview.viewSelector.getActivePage() == 2
		                   || Main.overview.viewSelector.getActivePage() == 3) {
			//ok
		} else {
			return;
		}

		this._appendSeparator(); //TODO injecter ailleurs dans le menu?
		
		let mainAppView = Main.overview.viewSelector.appDisplay._views[1].view;
		FOLDER_LIST = FOLDER_SCHEMA.get_strv('folder-children');
		
		//------------------------------------------------------------------
		
		let addto = new PopupMenu.PopupSubMenuMenuItem(_("Add to"));
		
		let newAppFolder = new PopupMenu.PopupMenuItem('+ ' + _("New AppFolder"));
		newAppFolder.connect('activate', () => {
			this._source._menuManager._grabHelper.ungrab({ actor: this.actor });
			// XXX broken scrolling ??
			// We can't popdown the folder immediately because the
			// AppDisplay.AppFolderPopup.popdown() method tries to ungrab
			// the global focus from the folder's popup actor, which isn't
			// having the focus since the menu is still open. Menus' animation
			// last ~0.25s so we will wait 0.30s before doing anything.
			let a = Mainloop.timeout_add(300, () => {
				if (mainAppView._currentPopup) {
					mainAppView._currentPopup.popdown();
				}
				createNewFolder(this._source);
				mainAppView._redisplay();
				Mainloop.source_remove(a);
			});
		});
		addto.menu.addMenuItem(newAppFolder);
		
		for (var i = 0 ; i < FOLDER_LIST.length ; i++) {
			let _folder = FOLDER_LIST[i];
			let shouldShow = !isInFolder( this._source.app.get_id(), _folder );
			let iFolderSchema = folderSchema(_folder);
			let item = new PopupMenu.PopupMenuItem( AppDisplay._getFolderName(iFolderSchema) );
			if ( Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('debug') ) {
				shouldShow = true; //TODO ??? et l'exclusion ?
			}
			if(shouldShow) {
				item.connect('activate', () => {
					this._source._menuManager._grabHelper.ungrab({ actor: this.actor });
					// XXX broken scrolling ??
					// We can't popdown the folder immediatly because the
					// AppDisplay.AppFolderPopup.popdown() method tries to
					// ungrab the global focus from the folder's popup actor,
					// which isn't having the focus since the menu is still
					// open. Menus' animation last ~0.25s so we will wait 0.30s
					// before doing anything.
					let a = Mainloop.timeout_add(300, () => {
						if (mainAppView._currentPopup) {
							mainAppView._currentPopup.popdown();
						}
						addToFolder(this._source, _folder);
						mainAppView._redisplay();
						Mainloop.source_remove(a);
					});
				});
				addto.menu.addMenuItem(item);
			}
		}
		this.addMenuItem(addto);
		
		//----------------------------------------------------------------------
		
		let removeFrom = new PopupMenu.PopupSubMenuMenuItem(_("Remove from"));
		let shouldShow2 = false;
		for (var i = 0 ; i < FOLDER_LIST.length ; i++) {
			let _folder = FOLDER_LIST[i];
			let appId = this._source.app.get_id();
			let shouldShow = isInFolder(appId, _folder);
			let iFolderSchema = folderSchema(_folder);
			let item = new PopupMenu.PopupMenuItem( AppDisplay._getFolderName(iFolderSchema) );
			
			if ( Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('debug') ) {
				shouldShow = true; //FIXME ??? et l'exclusion ?
			}
			
			if(shouldShow) {
				item.connect('activate', () => {
					this._source._menuManager._grabHelper.ungrab({ actor: this.actor });
					// XXX broken scrolling ??
					// We can't popdown the folder immediatly because the
					// AppDisplay.AppFolderPopup.popdown() method tries to
					// ungrab the global focus from the folder's popup actor,
					// which isn't having the focus since the menu is still
					// open. Menus' animation last ~0.25s so we will wait 0.30s
					// before doing anything.
					let a = Mainloop.timeout_add(300, () => {
						if (mainAppView._currentPopup) {
							mainAppView._currentPopup.popdown();
						}
						removeFromFolder(appId, _folder);
						mainAppView._redisplay();
						Mainloop.source_remove(a);
					});
				});
				removeFrom.menu.addMenuItem(item);
				shouldShow2 = true;
			}
		}
		if (shouldShow2) {
			this.addMenuItem(removeFrom);
		}
	});
}

//------------------------------------------------

function injectionInIcons() {
	// Right-click on a FolderIcon launches a new AppfolderDialog
	AppDisplay.FolderIcon = class extends AppDisplay.FolderIcon {
		constructor (id, path, parentView) {
			super(id, path, parentView);
			if (!this.isCustom) {
				this.actor.connect('button-press-event', this._onButtonPress.bind(this));
			}
			this.isCustom = true;
		}

		_onButtonPress (actor, event) {
			let button = event.get_button();
			if (button == 3) {
				let tmp = new Gio.Settings({
					schema_id: 'org.gnome.desktop.app-folders.folder',
					path: '/org/gnome/desktop/app-folders/folders/' + this.id + '/'
				});
				let dialog = new AppfolderDialog.AppfolderDialog(tmp, null, this.id);
				dialog.open();
			}
			return Clutter.EVENT_PROPAGATE;
		}
	};

	// Dragging an AppIcon triggers the DND mode
	AppDisplay.AppIcon = class extends AppDisplay.AppIcon {
		constructor (app, params) {
			super(app, params);
			if (!this.isCustom) {
				this._draggable.connect('drag-begin', this.onDragBeginExt.bind(this));
				this._draggable.connect('drag-cancelled', this.onDragCancelledExt.bind(this));
				this._draggable.connect('drag-end', this.onDragEndExt.bind(this));
			}
			this.isCustom = true;
		}

		onDragBeginExt () {
			if (Main.overview.viewSelector.getActivePage() != 2) {
				return;
			}
			this._removeMenuTimeout(); // why ?
			Main.overview.beginItemDrag(this);
			DragAndDrop.OVERLAY_MANAGER.on_drag_begin();
		}

		onDragEndExt () {
			Main.overview.endItemDrag(this);
			DragAndDrop.OVERLAY_MANAGER.on_drag_end();
		}

		onDragCancelledExt () {
			Main.overview.cancelledItemDrag(this);
			DragAndDrop.OVERLAY_MANAGER.on_drag_cancelled();
		}
	};
}

//------------------------------------------------------------------------------
//---------------------------------- Generic -----------------------------------
//--------------------------------- functions ----------------------------------
//------------------------------------------------------------------------------
/* These functions perform the requested actions but do not care about popdowning
 * open menu/open folder, nor about hiding/showing/activating dropping areas, nor
 * about redisplaying the view.
 */
function removeFromFolder (app_id, folder_id) {
	let folder_schema = folderSchema(folder_id);
	if ( isInFolder(app_id, folder_id) ) {
		let pastContent = folder_schema.get_strv('apps');
		let presentContent = [];
		for(var i=0; i<pastContent.length; i++){
			if(pastContent[i] != app_id) {
				presentContent.push(pastContent[i]);
			}
		}
		folder_schema.set_strv('apps', presentContent);
	} else {
		let content = folder_schema.get_strv('excluded-apps');
		content.push(app_id);
		folder_schema.set_strv('excluded-apps', content);
	}
	return true;
}

//------------------------------------------------------------------------------

function deleteFolder (folder_id) {
	Meta.later_add(Meta.LaterType.BEFORE_REDRAW, () => {
		let tmp = [];
		FOLDER_LIST = FOLDER_SCHEMA.get_strv('folder-children');
		for(var j=0;j < FOLDER_LIST.length;j++){
			if(FOLDER_LIST[j] != folder_id) {
				tmp.push(FOLDER_LIST[j]);
			}
		}
		
		FOLDER_LIST = tmp;
		FOLDER_SCHEMA.set_strv('folder-children', FOLDER_LIST);
		
		// ?? XXX (ne fonctionne pas mieux hors du meta.later_add)
		if ( Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('total-deletion') ) {
			let folder_schema = folderSchema (folder_id);
			folder_schema.reset('apps'); // génère un bug volumineux ?
			folder_schema.reset('categories'); // génère un bug volumineux ?
			folder_schema.reset('excluded-apps'); // génère un bug volumineux ?
			folder_schema.reset('name'); // génère un bug volumineux ?
		}
	});
	
	return true;
}

//------------------------------------------------------------------------------

function mergeFolders (folder_staying_id, folder_dying_id) { //unused XXX
	
	let folder_dying_schema = folderSchema (folder_dying_id);
	let folder_staying_schema = folderSchema (folder_staying_id);
	let newerContent = folder_dying_schema.get_strv('categories');
	let presentContent = folder_staying_schema.get_strv('categories');
	for(var i=0;i<newerContent.length;i++){
		if(presentContent.indexOf(newerContent[i]) == -1) {
			presentContent.push(newerContent[i]);
		}
	}
	folder_staying_schema.set_strv('categories', presentContent);
	
	newerContent = folder_dying_schema.get_strv('excluded-apps');
	presentContent = folder_staying_schema.get_strv('excluded-apps');
	for(var i=0;i<newerContent.length;i++){
		if(presentContent.indexOf(newerContent[i]) == -1) {
			presentContent.push(newerContent[i]);
		}
	}
	folder_staying_schema.set_strv('excluded-apps', presentContent);
	
	newerContent = folder_dying_schema.get_strv('apps');
	presentContent = folder_staying_schema.get_strv('apps');
	for(var i=0;i<newerContent.length;i++){
		if(presentContent.indexOf(newerContent[i]) == -1) {
//		if(!isInFolder(newerContent[i], folder_staying_id)) {
			presentContent.push(newerContent[i]);
			//TODO utiliser addToFolder malgré ses paramètres chiants
		}
	}
	folder_staying_schema.set_strv('apps', presentContent);
	deleteFolder(folder_dying_id);
	return true;
}

//------------------------------------------------------------------------------

function createNewFolder (app_source) {
	let id = app_source.app.get_id();
	
	let dialog = new AppfolderDialog.AppfolderDialog(null , id);
	dialog.open();
	return true;
}

//------------------------------------------------------------------------------

function addToFolder (app_source, folder_id) {
	let id = app_source.app.get_id();
	let folder_schema = folderSchema (folder_id);
	
	//un-exclude the application if it was excluded TODO else don't do it at all
	let pastExcluded = folder_schema.get_strv('excluded-apps');
	let presentExcluded = [];
	for(let i=0; i<pastExcluded.length; i++){
		if(pastExcluded[i] != id) {
			presentExcluded.push(pastExcluded[i]);
		}
	}
	if (presentExcluded.length > 0) {
		folder_schema.set_strv('excluded-apps', presentExcluded);
	}
	
	//actually add the app
	let content = folder_schema.get_strv('apps');
	content.push(id);
	folder_schema.set_strv('apps', content); //XXX verbose errors
	
	//update icons in the ugliest possible way
	let icons = Main.overview.viewSelector.appDisplay._views[1].view.folderIcons;
	for (let i=0; i<icons.length; i++) {
		let size = icons[i].icon._iconBin.width;
		icons[i].icon.icon = icons[i]._createIcon(size);
		icons[i].icon._iconBin.child = icons[i].icon.icon;
	}
	return true;
}

//------------------------------------------------------------------------------

function isInFolder (app_id, folder_id) {
	let folder_schema = folderSchema(folder_id);
	let isIn = false;
	let content_ = folder_schema.get_strv('apps');
	for(var j=0; j<content_.length; j++) {
		if(content_[j] == app_id) {
			isIn = true;
		}
	}
	return isIn;
}

//------------------------------------------------------------------------------

function folderSchema (folder_id) {
	let a = new Gio.Settings({
		schema_id: 'org.gnome.desktop.app-folders.folder',
		path: '/org/gnome/desktop/app-folders/folders/' + folder_id + '/'
	});
	return a;
} // TODO et AppDisplay._getFolderName ??

//------------------------------------------------------------------------------
//------------------------------------------------------------------------------

function enable() {
	FOLDER_SCHEMA = new Gio.Settings({ schema_id: 'org.gnome.desktop.app-folders' });
	FOLDER_LIST = FOLDER_SCHEMA.get_strv('folder-children');

	injectionInIcons();
	if( Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager').get_boolean('extend-menus') ) {
		injectionInAppsMenus();
	}
	DragAndDrop.initDND();
	
	// Reload the view if the user load the extension at least a minute after
	// opening the session. XXX works like shit
	let delta = getTimeStamp() - INIT_TIME;
	if (delta < 0 || delta > 105) {
		Main.overview.viewSelector.appDisplay._views[1].view._redisplay();
	}
}

function disable() {
	AppDisplay.FolderIcon.prototype._onButtonPress = null;
	AppDisplay.FolderIcon.prototype.popupMenu = null;

	removeInjection(AppDisplay.AppIconMenu.prototype, injections, '_redisplay');

	// Overwrite my shit for FolderIcon
	AppDisplay.FolderIcon = class extends AppDisplay.FolderIcon {
		_onButtonPress (actor, event) {
			return Clutter.EVENT_PROPAGATE;
		}
	};

	// Overwrite my shit for AppIcon
	AppDisplay.AppIcon = class extends AppDisplay.AppIcon {
		onDragBeginExt () {}
		onDragEndExt () {}
		onDragCancelledExt () {}
	};

	DragAndDrop.OVERLAY_MANAGER.destroy();
}

//------------------------------------------------------------------------------
