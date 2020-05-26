/* jshint esnext:true */

const Clutter = imports.gi.Clutter;
const GLib = imports.gi.GLib;
const Main = imports.ui.main;
const Mainloop = imports.mainloop;

const MAX_RECURSE_DEPTH = 3;

let signalConnections = [];
let dropdowns = [];


/**
 * Try hide a single dropdown actor.
 *
 * Return true on success.
 */
function _apply(actor)
{
    if (!actor.has_style_class_name || !actor.has_style_class_name('popup-menu-arrow'))
    {
        return false;
    }

    actor.hide();

    if (dropdowns.indexOf(actor) < 0)
    {
        let connection = {
            object: actor,
            id: actor.connect('destroy', function()
            {
                let index;

                index = signalConnections.indexOf(connection);
                if (index >= 0)
                {
                    signalConnections.splice(index, 1);
                }

                index = dropdowns.indexOf(actor);
                if (index >= 0)
                {
                    dropdowns.splice(index, 1);
                }
            })
        };
        signalConnections.push(connection);
        dropdowns.push(actor);
    }

    return true;
}

/**
 * Similar function to _recursiveApply(), but intended for containers.
 */
function _recursiveApplyInternal(actor, depth)
{
    if (typeof actor.get_children === 'undefined')
    {
        return false;
    }
    
    let children = actor.get_children();
    
    // If there are no children then it's possible that actor hasn't been fully initialized yet.
    // Shedule to check later.
    if (children.length == 0)
    {
        _scheduleApply(actor);
        return false;
    }

    // Check actor immediate children before using recursion
    if (children.map(child => _apply(child)).indexOf(true) >= 0)
    {
        return true;
    }

    // Check children recursively
    if (depth < MAX_RECURSE_DEPTH)
    {
        if (children.map(child => _recursiveApplyInternal(child, depth +1)).indexOf(true) >= 0)
        {
            return true;
        }
    }

    return false;
}

function _scheduleApply(actor)
{
    let actorAddedId, destroyId, timeoutId;
    actorAddedId = actor.connect('actor-added', function(child)
    {
        if (_recursiveApply(child))
        {
            actor.disconnect(actorAddedId);
            actor.disconnect(destroyId);
            Mainloop.source_remove(timeoutId);
            actorAddedId = destroyId = timeoutId = 0;
        }
    });
    destroyId = actor.connect('destroy', function()
    {
        if (timeoutId != 0) {
            Mainloop.source_remove(timeoutId);
            timeoutId = 0;
        }
    });
    timeoutId = Mainloop.idle_add(function()
    {
        actor.disconnect(actorAddedId);
        actor.disconnect(destroyId);
        actorAddedId = destroyId = timeoutId = 0;
        return GLib.SOURCE_REMOVE;
    });
}

function _recursiveApply(actor)
{
    return _apply(actor) || _recursiveApplyInternal(actor, 0);
}

function init()
{
	// no initialization required
}

function enable()
{
    let panelActor = Main.panel instanceof Clutter.Actor ? Main.panel : Main.panel.actor;

    panelActor.get_children().forEach(
        function(actor)
        {
            signalConnections.push({
                object: actor,
                id: actor.connect('actor-added', _recursiveApply)
            });

            actor.get_children().forEach(_recursiveApply);
        });
}

function disable()
{
    while (signalConnections.length > 0)
    {
        let connection = signalConnections.pop();
        connection.object.disconnect(connection.id);
    }

    while (dropdowns.length > 0)
    {
        let actor = dropdowns.pop();
        actor.show();
    }
}
