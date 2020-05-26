/*
    Copyright (c) 2017 Fabius <fabio@mereu.info>
    Released under the MIT license

    Window Corner Preview Gnome Extension

    Purpose: It adds a menu to the GNOME main panel from which you can turn the
             preview of any desktop window on.
             It can help you watch a movie or a video while studying or working.

    This is a fork of https://github.com/Exsul/float-youtube-for-gnome
        by "Enelar" Kirill Berezin which was originally forked itself
        from https://github.com/Shou/float-mpv by "Shou" Benedict Aas.

    Contributors:
        Scott Ames https://github.com/scottames
        Jan Tojnar https://github.com/jtojnar
*/

"use strict";

// Global modules
const Lang = imports.lang;
const Main = imports.ui.main;
const Mainloop = imports.mainloop;

// Internal modules
const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Preview = Me.imports.preview;
const Indicator = Me.imports.indicator;
const Settings = Me.imports.settings;
const Signaling = Me.imports.signaling;
const Bundle = Me.imports.bundle;
const Polygnome = Me.imports.polygnome;

const WindowCornerPreview = Preview.WindowCornerPreview;
const WindowCornerIndicator = Indicator.WindowCornerIndicator;
const WindowCornerSettings = Settings.WindowCornerSettings;
const SignalConnector = Signaling.SignalConnector;

const getWindowSignature = Bundle.getWindowSignature;
const getWindowHash = Bundle.getWindowHash;
const getMetawindows = Polygnome.getMetawindows;
const getWorkspaceWindowsArray = Polygnome.getWorkspaceWindowsArray;
const getWorkspaces = Polygnome.getWorkspaces;

function onZoomChanged() {
    settings.initialZoom = this.zoom;
}

function onCropChanged() {
    settings.initialLeftCrop = this.leftCrop;
    settings.initialRightCrop = this.rightCrop;
    settings.initialTopCrop = this.topCrop;
    settings.initialBottomCrop = this.bottomCrop;
}

function onCornerChanged() {
    settings.initialCorner = this.corner;
}

function onWindowChanged(preview, window) {
    settings.lastWindowHash = getWindowHash(preview.visible && window);
}

function onSettingsChanged(settings, property) {
    if (["focusHidden"].indexOf(property) > -1) {
        // this = preview
        this[property] = settings[property];
    }
}

function previewLastWindow(preview) {

    const lastWindowHash = settings.lastWindowHash;

    if (! lastWindowHash) return;

    const signals = new SignalConnector();

    let done, timer;

    function shouldBePreviewed(anyWindow) {

        if (!done && lastWindowHash === getWindowHash(anyWindow)) {

            done = true;
            signals.disconnectAll();

            if (timer) {
                Mainloop.source_remove(timer);
                timer = null;
            }

            // I don't know exactly the reason, but some windows
            // do not get shown properly without putting this on async
            // The thumbnail seems not to be ready yet
            Mainloop.timeout_add(100, function () {
                preview.window = anyWindow;
                preview.show();
            });
        }
    }

    // If the Extension is firstly activated the window list is empty [] and will
    // be filled in shortly, instead if it's enabled later (like via Tweak tool)
    // the array is already filled
    const windows = getMetawindows();
    if (windows.length) {
        windows.forEach(function (window) {
            shouldBePreviewed(window);
        });
    }
    else {

        getWorkspaces().forEach(function (workspace) {
            signals.tryConnectAfter(workspace, "window-added", function (workspace, window) {
                shouldBePreviewed(window);
            });
        });

        const TIMEOUT = 10000;
        timer = Mainloop.timeout_add(TIMEOUT, function () {
            // In case the last window previewed could not be found, stop listening
            done = true;
            signals.disconnectAll();
        });
    }
}

let preview, menu;
let settings, signals;

function init() {
    settings = new WindowCornerSettings();
    signals = new SignalConnector();
}

function enable() {
    preview = new WindowCornerPreview();
    signals.tryConnect(settings, "changed", Lang.bind(preview, onSettingsChanged));
    signals.tryConnect(preview, "zoom-changed", Lang.bind(preview, onZoomChanged));
    signals.tryConnect(preview, "crop-changed", Lang.bind(preview, onCropChanged));
    signals.tryConnect(preview, "corner-changed", Lang.bind(preview, onCornerChanged));
    signals.tryConnect(preview, "window-changed", Lang.bind(preview, onWindowChanged));

    // Initialize props
    preview.zoom = settings.initialZoom;
    preview.leftCrop = settings.initialLeftCrop;
    preview.rightCrop = settings.initialRightCrop;
    preview.topCrop = settings.initialTopCrop;
    preview.bottomCrop = settings.initialBottomCrop;
    preview.focusHidden = settings.focusHidden;
    preview.corner = settings.initialCorner;

    menu = new WindowCornerIndicator();
    menu.preview = preview;

    menu.enable();
    Main.panel.addToStatusArea("WindowCornerIndicator", menu);

    // The last window being previewed is reactivate
    previewLastWindow(preview);
 }

function disable() {
    signals.disconnectAll();
    // Save the last window on (or off)
    onWindowChanged.call(null, preview, preview.window);
    preview.passAway();
    menu.disable();
    menu.destroy();
    preview = null;
    menu = null;
}
