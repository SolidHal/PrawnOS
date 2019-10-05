# PrawnOS Documentation

Some additional documentation for PrawnOS that wouldn't fit in the README

## Useful XFCE4 keybindings and libinput-gestures:
### Gestures:
#### Config file: /etc/libinput-gestures.conf
* four finger swipe left:    Switch to left workspace
* four finger swipe right:   Switch to right worksace

### Keybindings

#### Configure under Settings->Window Manager->Keyboard
* control+alt+left:           move window to left workspace
* control+alt+right:          move window to right workspace

* control+bracketleft ([):    tile widow to the left
* control+bracketright (]):   tile window to the right
* control+up:                 maximize window

* alt+tab:                    app switcher

#### Configure under Settings->Keyboard->Application Shortcuts
* alt+space :                 App launcher (spotlight-esque)
* control+alt+l:              Lock screen
* Brightness scripts are also called here and can be remapped here or in ~/.Xmodmap

#### Configured using ~/.Xmodmap
* "search" key:                Mode switch aka m_s (function key)

* m_s + backspace:             delete
* m_s + up:                    page up
* m_s + down:                  page down
* m_s + left:                  home
* m_s + right:                 end
* m_s + period:                insert

* "brightness up key":         increase backlight
* "brightness down key":       decrease backlight
* "volume mute":               mute volume
* "volume down":               decrease volume
* "volume up":                 increase volume

* m_s + "brightness up key":   F7
* m_s + "brightness down key": F6
* m_s + "volume mute key":     F8
* m_s + "volume down key":     F9
* m_s + "volume up key":       F10

#### Configured using ~/.xinputrc
* alt+left                     left a word
* alt+right                    right a word
