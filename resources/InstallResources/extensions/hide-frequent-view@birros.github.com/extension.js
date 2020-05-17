const Main = imports.ui.main;

function get_current_view_index () {
  let current_view_index = 0;
  let views = Main.overview.viewSelector.appDisplay._views;
  for (let i = 0; i < views.length; i++) {
    let pseudo_class = views[i].control.get_style_pseudo_class();
    if (pseudo_class && pseudo_class.indexOf("checked") !== -1) {
      current_view_index = i;
    }
  }
  return current_view_index;
}

let previous_view_index;

function init() {
  previous_view_index = 0;
}

function enable() {
  // save current view index to restore when this extensions is disabled
  previous_view_index = get_current_view_index();
  // hide controls : Frequent/All buttons
  Main.overview.viewSelector.appDisplay._controls.hide()
  // switch to All apps view
  Main.overview.viewSelector.appDisplay._showView(1)
}

function disable() {
  // switch to the saved view index
  Main.overview.viewSelector.appDisplay._showView(previous_view_index)
  // show controls
  Main.overview.viewSelector.appDisplay._controls.show()
}
