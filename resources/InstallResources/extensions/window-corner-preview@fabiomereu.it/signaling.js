"use strict";

// Global modules
const Lang = imports.lang;

// Helper to disconnect more signals at once
var SignalConnector = new Lang.Class({

    Name: "WindowCornerPreview.SignalConnector",

    _init: function() {
        this._connections = [];
    },

    tryConnect: function(actor, signal, callback) {
        try {
            let handle = actor.connect(signal, callback);
            this._connections.push({
                actor: actor,
                handle: handle
            });
        }

        catch (e) {
            logError(e, "SignalConnector.tryConnect failed");
        }
    },

    tryConnectAfter: function(actor, signal, callback) {
        try {
            let handle = actor.connect_after(signal, callback);
            this._connections.push({
                actor: actor,
                handle: handle
            });
        }

        catch (e) {
            logError(e, "SignalConnector.tryConnectAfter failed");
        }
    },

    disconnectAll: function() {
        for (let i = 0; i < this._connections.length; i++) {
            try {
                let connection = this._connections[i];
                connection.actor.disconnect(connection.handle);
                this._connections[i] = null;
            }

            catch (e) {
                logError(e, "SignalConnector.disconnectAll failed");
            }
        }
        this._connections = [];
    }
});
