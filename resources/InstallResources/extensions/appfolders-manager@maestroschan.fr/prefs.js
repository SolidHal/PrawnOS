
const GObject = imports.gi.GObject;
const Gtk = imports.gi.Gtk;

const Gettext = imports.gettext.domain('appfolders-manager');
const _ = Gettext.gettext;

const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Convenience = Me.imports.convenience;

//-----------------------------------------------

const appfoldersManagerSettingsWidget = new GObject.Class({
	Name: 'appfoldersManager.Prefs.Widget',
	GTypeName: 'appfoldersManagerPrefsWidget',
	Extends: Gtk.Box,

	_init: function (params) {
		this.parent(params);
		this.margin = 30;
		this.spacing = 18;
		this.set_orientation(Gtk.Orientation.VERTICAL);

		this._settings = Convenience.getSettings('org.gnome.shell.extensions.appfolders-manager');
		this._settings.set_boolean('debug', this._settings.get_boolean('debug'));

		//----------------------------

		let labelMain = new Gtk.Label({
			label: _("Modifications will be effective after reloading the extension."),
			use_markup: true,
			wrap: true,
			halign: Gtk.Align.START
		});
		this.add(labelMain);

		let generalSection = this.add_section(_("Main settings"));
		let categoriesSection = this.add_section(_("Categories"));

		//----------------------------

//		let autoDeleteBox = this.build_switch('auto-deletion',
//		                               _("Delete automatically empty folders"));
		let deleteAllBox = this.build_switch('total-deletion',
		         _("Delete all related settings when an appfolder is deleted"));
		let menusBox = this.build_switch('extend-menus',
		       _("Use the right-click menus in addition to the drag-and-drop"));

//		this.add_row(autoDeleteBox, generalSection);
		this.add_row(deleteAllBox, generalSection);
		this.add_row(menusBox, generalSection);

		//-------------------------

		let categoriesBox = this.build_switch('categories', _("Use categories"));

		let categoriesLinkButton = new Gtk.LinkButton({
			label: _("More informations about \"additional categories\""),
			uri: "https://standards.freedesktop.org/menu-spec/latest/apas02.html"
		});

		this.add_row(categoriesBox, categoriesSection);
		this.add_row(categoriesLinkButton, categoriesSection);

		//-------------------------

		let aboutBox = new Gtk.Box({ orientation: Gtk.Orientation.HORIZONTAL, spacing: 10 });
		let about_label = new Gtk.Label({
			label: '(v' + Me.metadata.version.toString() + ')',
			halign: Gtk.Align.START
		});
		let url_button = new Gtk.LinkButton({
			label: _("Report bugs or ideas"),
			uri: Me.metadata.url.toString()
		});
		aboutBox.pack_start(url_button, false, false, 0);
		aboutBox.pack_end(about_label, false, false, 0);

		this.pack_end(aboutBox, false, false, 0);

		//-------------------------

		let desacLabel = new Gtk.Label({
			label: _("This extension can be deactivated once your applications are organized as wished."),
			wrap: true,
			halign: Gtk.Align.CENTER
		});
		this.pack_end(desacLabel, false, false, 0);
	},

	add_section: function (titre) {
		let section = new Gtk.Box({
			orientation: Gtk.Orientation.VERTICAL,
			margin: 6,
			spacing: 6,
		});

		let frame = new Gtk.Frame({
			label: titre,
			label_xalign: 0.1,
		});
		frame.add(section);
		this.add(frame);
		return section;
	},

	add_row: function (filledbox, section) {
		section.add(filledbox);
	},
	
	build_switch: function (key, label) {
		let rowLabel = new Gtk.Label({
			label: label,
			halign: Gtk.Align.START,
			wrap: true,
			visible: true,
		});
		
		let rowSwitch = new Gtk.Switch({ valign: Gtk.Align.CENTER });
		rowSwitch.set_state(this._settings.get_boolean(key));
		rowSwitch.connect('notify::active', (widget) => {
			this._settings.set_boolean(key, widget.active);
		});

		let rowBox = new Gtk.Box({
			orientation: Gtk.Orientation.HORIZONTAL,
			spacing: 15,
			margin: 6,
			visible: true,
		});
		rowBox.pack_start(rowLabel, false, false, 0);
		rowBox.pack_end(rowSwitch, false, false, 0);
		
		return rowBox;
	},
});

//-----------------------------------------------

function init() {
	Convenience.initTranslations();
}

//I guess this is like the "enable" in extension.js : something called each
//time he user try to access the settings' window
function buildPrefsWidget () {
	let widget = new appfoldersManagerSettingsWidget();
	widget.show_all();

	return widget;
}

