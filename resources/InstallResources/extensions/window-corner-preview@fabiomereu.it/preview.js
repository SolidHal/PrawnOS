"use strict";

// Global modules
const Lang = imports.lang;
const Main = imports.ui.main;
const St = imports.gi.St;
const Tweener = imports.ui.tweener;
const Clutter = imports.gi.Clutter;
const Signals = imports.signals;

// Internal modules
const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();
const Polygnome = Me.imports.polygnome;
const Signaling = Me.imports.signaling;

const DisplayWrapper = Polygnome.DisplayWrapper;
const SignalConnector = Signaling.SignalConnector;

// At the moment magnification hasn't been tested and it's clumsy
const SETTING_MAGNIFICATION_ALLOWED = false;

const CORNER_TOP_LEFT = 0;
const CORNER_TOP_RIGHT = 1;
const CORNER_BOTTOM_RIGHT = 2;
const CORNER_BOTTOM_LEFT = 3;
const DEFAULT_CORNER = CORNER_TOP_RIGHT;

var MIN_ZOOM = 0.10; // User shouldn't be able to make the preview too small or big, as it may break normal experience
var MAX_ZOOM = 0.75;
var DEFAULT_ZOOM = 0.20;

var MAX_CROP_RATIO = 0.85;
var DEFAULT_CROP_RATIO = 0.0;

const SCROLL_ACTOR_MARGIN = 0.2; // scrolling: 20% external margin to crop, 80% to zoom
const SCROLL_ZOOM_STEP = 0.01; // 1% zoom for step
const SCROLL_CROP_STEP = 0.0063; // cropping step when user scrolls

// Animation constants
const TWEEN_OPACITY_FULL = 255;
const TWEEN_OPACITY_SEMIFULL = Math.round(TWEEN_OPACITY_FULL * 0.90);
const TWEEN_OPACITY_HALF = Math.round(TWEEN_OPACITY_FULL * 0.50);
const TWEEN_OPACITY_TENTH = Math.round(TWEEN_OPACITY_FULL * 0.10);
const TWEEN_OPACITY_NULL = 0;

const TWEEN_TIME_SHORT = 0.25;
const TWEEN_TIME_MEDIUM = 0.6;
const TWEEN_TIME_LONG = 0.80;

const GTK_MOUSE_LEFT_BUTTON = 1;
const GTK_MOUSE_MIDDLE_BUTTON = 2;
const GTK_MOUSE_RIGHT_BUTTON = 3;

const GDK_SHIFT_MASK = 1;
const GDK_CONTROL_MASK = 4;
const GDK_MOD1_MASK = 8;
const GDK_ALT_MASK = GDK_MOD1_MASK; // Most cases

var WindowCornerPreview = new Lang.Class({

    Name: "WindowCornerPreview.preview",

    _init: function() {

        this._corner = DEFAULT_CORNER;
        this._zoom = DEFAULT_ZOOM;

        this._leftCrop = DEFAULT_CROP_RATIO;
        this._rightCrop = DEFAULT_CROP_RATIO;
        this._topCrop = DEFAULT_CROP_RATIO;
        this._bottomCrop = DEFAULT_CROP_RATIO;

        // The following properties are documented on _adjustVisibility()
        this._naturalVisibility = false;
        this._focusHidden = true;

        this._container = null;
        this._window = null;

        this._windowSignals = new SignalConnector();
        this._environmentSignals = new SignalConnector();

        this._handleZoomChange = null;
    },

    _onClick: function(actor, event) {
        let button = event.get_button();
        let state = event.get_state();

        // CTRL + LEFT BUTTON activate the window on top
        if (button === GTK_MOUSE_LEFT_BUTTON && (state & GDK_CONTROL_MASK)) {
            this._window.activate(global.get_current_time());
        }

        // Otherwise move the preview to another corner
        else {
            switch (button) {
                case GTK_MOUSE_RIGHT_BUTTON:
                    this.corner += 1;
                    break;

                case GTK_MOUSE_MIDDLE_BUTTON:
                    this.corner += -1;
                    break;

                default: // GTK_MOUSE_LEFT_BUTTON:
                    this.corner += 2;
            }
            this.emit("corner-changed");
        }
    },

    _onScroll: function(actor, event) {
        let scroll_direction = event.get_scroll_direction();

        let direction;
        switch (scroll_direction) {

            case Clutter.ScrollDirection.UP:
            case Clutter.ScrollDirection.LEFT:
                direction = +1.0
                break;

            case Clutter.ScrollDirection.DOWN:
            case Clutter.ScrollDirection.RIGHT:
                direction = -1.0
                break;

            default:
                direction = 0.0;
        }

        if (! direction) return; // Clutter.EVENT_PROPAGATE;

        // On mouse over it's normally pretty transparent, but user needs to see more for adjusting it
        Tweener.addTween(this._container, {
            opacity: TWEEN_OPACITY_SEMIFULL,
            time: TWEEN_TIME_SHORT,
            transition: "easeOutQuad"
        });

        // Coords are absolute, screen related
        let [mouseX, mouseY] = event.get_coords();

        // _container absolute rect
        let [actorX1, actorY1] = this._container.get_transformed_position();
        let [actorWidth, actorHeight] = this._container.get_transformed_size();
        let actorX2 = actorX1 + actorWidth;
        let actorY2 = actorY1 + actorHeight;

        // Distance of pointer from each side
        let deltaLeft = Math.abs(actorX1 - mouseX);
        let deltaRight = Math.abs(actorX2 - mouseX);
        let deltaTop = Math.abs(actorY1 - mouseY);
        let deltaBottom = Math.abs(actorY2 - mouseY);

        let sortedDeltas = [{
                property: "leftCrop",
                pxDistance: deltaLeft,
                comparedDistance: deltaLeft / actorWidth,
                direction: -direction
            },
            {
                property: "rightCrop",
                pxDistance: deltaRight,
                comparedDistance: deltaRight / actorWidth,
                direction: -direction
            },
            {
                property: "topCrop",
                pxDistance: deltaTop,
                comparedDistance: deltaTop / actorHeight,
                direction: -direction /* feels more natural */
            },
            {
                property: "bottomCrop",
                pxDistance: deltaBottom,
                comparedDistance: deltaBottom / actorHeight,
                direction: -direction
            }
        ];
        sortedDeltas.sort(function(a, b) {
            return a.pxDistance - b.pxDistance
        });
        let deltaMinimum = sortedDeltas[0];

        // Scrolling inside the preview triggers the zoom
        if (deltaMinimum.comparedDistance > SCROLL_ACTOR_MARGIN) {
            this.zoom += direction * SCROLL_ZOOM_STEP;
            this.emit("zoom-changed");
        }

        // Scrolling along the margins triggers the cropping instead
        else {
            this[deltaMinimum.property] += deltaMinimum.direction * SCROLL_CROP_STEP;
            this.emit("crop-changed");
        }
    },

    _onEnter: function(actor, event) {
        let [x, y, state] = global.get_pointer();

        // SHIFT: ignore standard behavior
        if (state & GDK_SHIFT_MASK) {
            return; // Clutter.EVENT_PROPAGATE;
        }

        Tweener.addTween(this._container, {
            opacity: TWEEN_OPACITY_TENTH,
            time: TWEEN_TIME_MEDIUM,
            transition: "easeOutQuad"
        });
    },

    _onLeave: function() {
        Tweener.addTween(this._container, {
            opacity: TWEEN_OPACITY_FULL,
            time: TWEEN_TIME_MEDIUM,
            transition: "easeOutQuad"
        });
    },

    _onParamsChange: function() {
        // Zoom or crop properties changed
        if (this.enabled) this._setThumbnail();
    },

    _onWindowUnmanaged: function() {
        this.disable();
        this._window = null;
        // gnome-shell --replace will cause this event too
        this.emit("window-changed", null);
    },

    _adjustVisibility: function(options) {
        options = options || {};

        /*
            [Boolean] this._naturalVisibility:
                        true === show the preview whenever is possible;
                        false === don't show it in any case
            [Boolean] this._focusHidden:
                        true === hide in case the mirrored window should be active

            options = {
                onComplete: [function] to call once the process is done.
                            It's called even if visibility was already set as requested

                noAnimate: [Boolean] to skip animation. If switching from window A to window B,
                             for example, the preview gets first destroyed (so hidden) then recreated.
                             This would lead to a fade-out + fade-in, which is not what most users like.
                             noAnimate === true avoids that.
            };
        */

        if (! this._container) {
            if (options.onComplete) options.onComplete();
            return;
        }

        // Hide when overView is shown, or source window is on top, or user related reasons
        let canBeShownOnFocus = (! this._focusHidden) || (global.display.focus_window !== this._window);

        let calculatedVisibility = this._window &&
            this._naturalVisibility &&
            canBeShownOnFocus &&
            (! Main.overview.visibleTarget);

        let calculatedOpacity = (calculatedVisibility) ? TWEEN_OPACITY_FULL : TWEEN_OPACITY_NULL;

        // Already OK (hidden / shown), no change needed
        if ((calculatedVisibility === this._container.visible) && (calculatedOpacity === this._container.get_opacity())) {
            if (options.onComplete) options.onComplete();
        }

        // Quick set (show or hide), but don't animate
        else if (options.noAnimate) {
            this._container.set_opacity(calculatedOpacity)
            this._container.visible = calculatedVisibility;
            if (options.onComplete) options.onComplete();
        }

        // Animation needed (either from less to more opacity or viceversa)
        else {
            this._container.reactive = false;
            if (! this._container.visible) {
                this._container.set_opacity(TWEEN_OPACITY_NULL);
                this._container.visible = true;
            }

            Tweener.addTween(this._container, {
                opacity: calculatedOpacity,
                time: TWEEN_TIME_SHORT,
                transition: "easeOutQuad",
                onComplete: Lang.bind(this, function() {
                    this._container.visible = calculatedVisibility;
                    this._container.reactive = true;
                    if (options.onComplete) options.onComplete();
                })
            });
        }
    },

    _onNotifyFocusWindow: function() {
        this._adjustVisibility();
    },

    _onOverviewShowing: function() {
        this._adjustVisibility();
    },

    _onOverviewHiding: function() {
        this._adjustVisibility();
    },

    _onMonitorsChanged: function() {
        // TODO multiple monitors issue, the preview doesn't stick to the right monitor
        log("Monitors changed");
    },

    // Align the preview along the chrome area
    _setPosition: function() {

        if (! this._container) {
            return;
        }

        let posX, posY;

        let rectMonitor = Main.layoutManager.getWorkAreaForMonitor(DisplayWrapper.getScreen().get_current_monitor());

        let rectChrome = {
            x1: rectMonitor.x,
            y1: rectMonitor.y,
            x2: rectMonitor.width + rectMonitor.x - this._container.get_width(),
            y2: rectMonitor.height + rectMonitor.y - this._container.get_height()
        };

        switch (this._corner) {

            case CORNER_TOP_LEFT:
                posX = rectChrome.x1;
                posY = rectChrome.y1;
                break;

            case CORNER_BOTTOM_LEFT:
                posX = rectChrome.x1;
                posY = rectChrome.y2;
                break;

            case CORNER_BOTTOM_RIGHT:
                posX = rectChrome.x2;
                posY = rectChrome.y2;
                break;

            default: // CORNER_TOP_RIGHT:
                posX = rectChrome.x2;
                posY = rectChrome.y1;
        }
        this._container.set_position(posX, posY);
    },

    // Create a window thumbnail and adds it to the container
    _setThumbnail: function() {

        if (! this._container) return;

        this._container.foreach(function(actor) {
            actor.destroy();
        });

        if (! this._window) return;

        let mutw = this._window.get_compositor_private();

        if (! mutw) return;

        let windowTexture = mutw.get_texture();
        let [windowWidth, windowHeight] = windowTexture.get_size();

        /* To crop the window texture, for now I've found that:
           1. Using a clip rect on Clutter.clone will hide the outside portion but also will KEEP the space along it
           2. The Clutter.clone is stretched to fill all of its room when it's painted, so the transparent area outside
                cannot be easily left out by only adjusting the actor size (empty space only gets reproportioned).

           My current workaround:
           - Define a margin rect by using some proportional [0.0 - 1.0] trimming values for left, right, ... Zero: no trimming 1: all trimmed out
           - Set width and height of the Clutter.clone based on the crop rect and apply a translation to anchor it the top left margin
                (set_clip_to_allocation must be set true on the container to get rid of the translated texture overflow)
           - Ratio of the cropped texture is different from the original one, so this must be compensated with Clutter.clone scale_x/y parameters

           Known issues:
           - Strongly cropped textual windows like terminals get a little bit blurred. However, I was told this feature
                 was useful for framed videos to peel off, particularly. So shouldn't affect that much.

           Hopefully, some kind guy will soon explain to me how to clone just a portion of the source :D
        */

        // Get absolute margin values for cropping
        let margins = {
            left: windowWidth * this.leftCrop,
            right: windowWidth * this.rightCrop,
            top: windowHeight * this.topCrop,
            bottom: windowHeight * this.bottomCrop,
        };

        // Calculate the size of the cropped rect (based on the 100% window size)
        let croppedWidth = windowWidth - (margins.left + margins.right);
        let croppedHeight = windowHeight - (margins.top + margins.bottom);

        // To mantain a similar thumbnail size whenever the user selects a different window to preview,
        // instead of zooming out based on the window size itself, it takes the window screen as a standard unit (= 100%)
        let rectMonitor = Main.layoutManager.getWorkAreaForMonitor(DisplayWrapper.getScreen().get_current_monitor());
        let targetRatio = rectMonitor.width * this.zoom / windowWidth;

        // No magnification allowed (KNOWN ISSUE: there's no height control if used, it still needs optimizing)
        if (! SETTING_MAGNIFICATION_ALLOWED && targetRatio > 1.0) {
            targetRatio = 1.0;
            this._zoom = windowWidth / rectMonitor.width; // do NOT set this.zoom (the encapsulated prop for _zoom) or it will be looping!
        }

        let thumbnail = new Clutter.Clone({ // list parameters https://www.roojs.org/seed/gir-1.2-gtk-3.0/seed/Clutter.Clone.html
            source: windowTexture,
            reactive: false,

            magnification_filter: Clutter.ScalingFilter.NEAREST, //NEAREST, //TRILINEAR,

            translation_x: -margins.left * targetRatio,
            translation_y: -margins.top * targetRatio,

            // Compensating scales due the different ratio of the cropped window texture
            scale_x: windowWidth / croppedWidth,
            scale_y: windowHeight / croppedHeight,

            width: croppedWidth * targetRatio,
            height: croppedHeight * targetRatio,

            margin_left: 0,
            margin_right: 0,
            margin_bottom: 0,
            margin_top: 0

        });

        this._container.add_actor(thumbnail);

        this._setPosition();
    },

    // xCrop properties normalize their opposite counterpart, so that margins won't ever overlap
    set leftCrop(value) {
        // [0, MAX] range
        this._leftCrop = Math.min(MAX_CROP_RATIO, Math.max(0.0, value));
        // Decrease the opposite margin if necessary
        this._rightCrop = Math.min(this._rightCrop, MAX_CROP_RATIO - this._leftCrop);
        this._onParamsChange();
    },

    set rightCrop(value) {
        this._rightCrop = Math.min(MAX_CROP_RATIO, Math.max(0.0, value));
        this._leftCrop = Math.min(this._leftCrop, MAX_CROP_RATIO - this._rightCrop);
        this._onParamsChange();
    },

    set topCrop(value) {
        this._topCrop = Math.min(MAX_CROP_RATIO, Math.max(0.0, value));
        this._bottomCrop = Math.min(this._bottomCrop, MAX_CROP_RATIO - this._topCrop);
        this._onParamsChange();
    },

    set bottomCrop(value) {
        this._bottomCrop = Math.min(MAX_CROP_RATIO, Math.max(0.0, value));
        this._topCrop = Math.min(this._topCrop, MAX_CROP_RATIO - this._bottomCrop);
        this._onParamsChange();
    },

    get leftCrop() {
        return this._leftCrop;
    },

    get rightCrop() {
        return this._rightCrop;
    },

    get topCrop() {
        return this._topCrop;
    },

    get bottomCrop() {
        return this._bottomCrop;
    },

    set zoom(value) {
        this._zoom = Math.min(MAX_ZOOM, Math.max(MIN_ZOOM, value));
        this._onParamsChange();
    },

    get zoom() {
        return this._zoom;
    },

    set focusHidden(value) {
        this._focusHidden = !!value;
        this._adjustVisibility();
    },

    get focusHidden() {
        return this._focusHidden;
    },

    set corner(value) {
        this._corner = (value %= 4) < 0 ? (value + 4) : (value);
        this._setPosition();
    },

    get corner() {
        return this._corner;
    },

    get enabled() {
        return !!this._container;
    },

    get visible() {
        return this._container && this._window && this._naturalVisibility;
    },

    show: function(onComplete) {
        this._naturalVisibility = true;
        this._adjustVisibility({
            onComplete: onComplete
        });
    },

    hide: function(onComplete) {
        this._naturalVisibility = false;
        this._adjustVisibility({
            onComplete: onComplete
        });
    },

    toggle: function(onComplete) {
        this._naturalVisibility = !this._naturalVisibility;
        this._adjustVisibility({
            onComplete: onComplete
        });
    },

    passAway: function() {
        this._naturalVisibility = false;
        this._adjustVisibility({
            onComplete: Lang.bind(this, this.disable)
        });
    },

    get window() {
        return this._window;
    },

    set window(metawindow) {

        this.enable();

        this._windowSignals.disconnectAll();

        this._window = metawindow;

        if (metawindow) {
            this._windowSignals.tryConnect(metawindow, "unmanaged", Lang.bind(this, this._onWindowUnmanaged));
            // Version 3.10 does not support size-changed
            this._windowSignals.tryConnect(metawindow, "size-changed", Lang.bind(this, this._setThumbnail));
            this._windowSignals.tryConnect(metawindow, "notify::maximized-vertically", Lang.bind(this, this._setThumbnail));
            this._windowSignals.tryConnect(metawindow, "notify::maximized-horizontally", Lang.bind(this, this._setThumbnail));
        }

        this._setThumbnail();

        this.emit("window-changed", metawindow);
    },

    enable: function() {

        if (this._container) return;

        let isSwitchingWindow = this.enabled;

        this._environmentSignals.tryConnect(Main.overview, "showing", Lang.bind(this, this._onOverviewShowing));
        this._environmentSignals.tryConnect(Main.overview, "hiding", Lang.bind(this, this._onOverviewHiding));
        this._environmentSignals.tryConnect(global.display, "notify::focus-window", Lang.bind(this, this._onNotifyFocusWindow));
        this._environmentSignals.tryConnect(DisplayWrapper.getMonitorManager(), "monitors-changed", Lang.bind(this, this._onMonitorsChanged));

        this._container = new St.Button({
            style_class: "window-corner-preview"
        });
        // Force content not to overlap, allowing cropping
        this._container.set_clip_to_allocation(true);

        this._container.connect("enter-event", Lang.bind(this, this._onEnter));
        this._container.connect("leave-event", Lang.bind(this, this._onLeave));
        // Don't use button-press-event, as set_position conflicts and Gtk would react for enter and leave event of ANY item on the chrome area
        this._container.connect("button-release-event", Lang.bind(this, this._onClick));
        this._container.connect("scroll-event", Lang.bind(this, this._onScroll));

        this._container.visible = false;
        Main.layoutManager.addChrome(this._container);

        return;
        // isSwitchingWindow = false means user only changed window, but preview was on, so does not animate
        this._adjustVisibility({
            noAnimate: isSwitchingWindow
        });
    },

    disable: function() {

        this._windowSignals.disconnectAll();
        this._environmentSignals.disconnectAll();

        if (! this._container) return;

        Main.layoutManager.removeChrome(this._container);
        this._container.destroy();
        this._container = null;
    }
})

Signals.addSignalMethods(WindowCornerPreview.prototype);
