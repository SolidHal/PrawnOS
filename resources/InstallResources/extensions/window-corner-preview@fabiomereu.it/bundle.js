"use strict";

function normalizeRange(denormal, min, max, step) {
    if (step !== undefined) denormal = Math.round(denormal / step) * step;
    // To a range 0-1
    return (denormal - min) / (max - min);
};

function deNormalizeRange(normal, min, max, step) {
    // from [0, 1] to MIN - MAX
    let denormal = (max - min) * normal + min;
    if (step !== undefined) denormal = Math.round(denormal / step) * step;
    return denormal;
};

// Truncate too long window titles on the menu
function spliceTitle(text, max) {
    text = text || "";
    max = max || 25;
    if (text.length > max) {
        return text.substr(0, max - 2) + "...";
    }
    else {
        return text;
    }
};

function getWindowSignature(metawindow) {
    return "".concat(
        metawindow.get_pid(),
        metawindow.get_wm_class(),
        metawindow.get_title()//,
    //    metawindow.get_stable_sequence()
    );
}

function getWindowHash(metawindow) {
    return metawindow ? sdbm(getWindowSignature(metawindow)).toString(36) : "";
}

// https://github.com/sindresorhus/sdbm
function sdbm(string) {

    let hash = 0;

    for (let i = 0; i < string.length; i++) {
        hash = string.charCodeAt(i) + (hash << 6) + (hash << 16) - hash;
    }

    // Convert it to an unsigned 32-bit integer
	return hash >>> 0;
}
