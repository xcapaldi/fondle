# fondle
[![Code style: black](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)

`fondle` is a notification daemon designed for minimal window managers and status bars.
It works well with any system in which you would normally use a script to generate your status bar ([dwm](https://dwm.suckless.org/), [spectrwm](https://github.com/conformal/spectrwm), [lemonbar](https://github.com/LemonBoy/bar)) and was designed such that it can be implemented with minimal disturbance to your other configurations.

## why another notification daemon?

In most non-minimal window managers (XFCE, KDE, Gnome), notifications are implemented as small pop-up windows that appear for a few seconds before fading away.
They contain text, an icon and the user can often interact with them in some way.
They can convey all sort of information, ranging from new emails to battery status.
[Dunst](https://dunst-project.org/) is a very popular (and capable) notification daemon for minimal systems that uses the traditional popup style to notifications.
For some users, popups are overkill and distracting.
As far as I know, [statnot](https://github.com/halhen/statnot) was the first system to integrate notifications unobtrusively into the status bar.
[Qtile](http://www.qtile.org/) implemented a notification widget in their window manager which operates similarly.
[Rofication](https://github.com/DaveDavenport/Rofication) took this a step further by only displaying the number of notifications in the bar and relying on [rofi](https://github.com/davatorium/rofi) to display them when the user desires.
Each of the above systems has limitation (at least for my particular use-case): 

* Rofication is only currently implemented for i3-blocks (although implementations for other window managers is possible) and depends on rofi.
* Qtile's notify widget only works in Qtile.
* statnot was originally implemented for dwm and it proved sufficiently complex to modify it to work well in spectrwm to warrant a full rewrite.
   
`fondle` operates under a similar philosophy to [statnot](https://github.com/halhen/statnot) but tries to be more system agnostic.
In particular it has a few nice features:

### no configuration
`fondle` doesn't have any configuration file.
Like [dmenu](https://tools.suckless.org/dmenu/), all options are set when you start the service.
More involved configuration requires modification of the source code.

### format control
Each notification implemented with the [Desktop Notification standard](http://www.galago-project.org/specs/notification/) contains several fields with information about the notification (content, urgency, icon, etc.).
We only display the summary (effectively a header) and the body.
However, you can control what, if anything, should be prepended before the summary, what separates the summary and body, how many characters the body should be limited to, and what, if anything should be appended at the end of the body.
This makes it possible (with a compatible bar) to implement emojis and different colors for notifications in the bar.

```sh
🚩 battery status: low
``` 

### minimal modification of status script
`fondle` integrates with the status script you've already written to generate the status for your bar.
The only requirements are that the script echoes or prints the output and isn't inside a permanent while loop.
For most users this will mean they just have to remove the while loop from their script.
`fondle` can work with any script as long as you point it to the executable to run it (sh, bash, python, etc.).

### flexibility in output
Does your bar (lemonbar) want you pipe the output of your status script directly into it?
No problem.
Just tell `fondle` to echo it's output and pipe it into your bar directly.

Running dwm which requires you to use `xsetroot -name` to change the bar?
No problem.
Tell `fondle` to use `xsetroot -name` instead.

Don't have a bar at all and want your notifications in a terminal window?
`fondle` can do that too.

### notification logging
Each time you start `fondle`, it resets a simple notification log ("/tmp/notification.log") that you can manipulate using other tools.

At it's simplest, you can do something like this to display your most recent notifications chronologically:

```sh
tac /tmp/notifications.log | dmenu -l 50
```

### (hopefully) easily hackable
`fondle` has been implemented entirely in a few hundred lines of python with quite a few comments.
Hopefully it's quite easy to modify it to better suite your individual needs if you so desire.

## Installation
To install `fondle`, first install the required dependencies:

* [python 3.5+](http://www.python.org)
* dbus-python
* PyGObject
* gtk3 - (not for GUI support)

Follow the [PyGObject installation instructions](https://pygobject.readthedocs.io/en/latest/getting_started.html) for your system.
That should take care of most of your dependencies.

Next, adjust the target directories in the `config.mk` file to fit your setup.

To install, run as root:

```sh
make install
```

`fondle` should be the only notification tool running.
You can run the following to ensure `notification-daemon` is not running:

```sh
killall notification-daemon &> /dev/null
```
## Usage (examples below)

```
usage: fondle [-h] [-x EXECUTABLE] [-c COMMAND] [-t DEFAULT_TIMEOUT] [-m MAX_TIMEOUT] [-l MAX_LENGTH] [-u UPDATE_INTERVAL] [-r] [-s SEPARATOR] [-p PREPEND] [-a APPEND] [script]

positional arguments:
  script                script to generate status

optional arguments:
  -h, --help            show this help message and exit
  -x EXECUTABLE, --executable EXECUTABLE
                        executable (on PATH) to run the status script
                        (default: 'sh')
  -c COMMAND, --command COMMAND
                        shell command to update status (default: 'echo')
  -t DEFAULT_TIMEOUT, --default-timeout DEFAULT_TIMEOUT
                        default notification timeout (default: 3.0)
  -m MAX_TIMEOUT, --max-timeout MAX_TIMEOUT
                        max notification timeout (default: 5.0s)
  -l MAX_LENGTH, --max-length MAX_LENGTH
                        max display length of notification body
  -u UPDATE_INTERVAL, --update-interval UPDATE_INTERVAL
                        status update interval (default: 2.0)
  -r, --replace-status  replace the status information with notification
  -s SEPARATOR, --separator SEPARATOR
                        separator between summary and body of notification
                        (default: ': ')
  -p PREPEND, --prepend PREPEND
                        prepend before notification (default: '')
  -a APPEND, --append APPEND
                        append after notification (default: ' ')
```

### script
Path to any script which echoes or prints.
Script must not run in a loop for it's final output.
The script can be in any language as long as you specify the appropriate executable with the `--executable` flag.

### -x EXECUTABLE, --executable EXECUTABLE
This is the executable (which must be on PATH) with which the script should be run.
It defaults to `sh` but you can easily write your status script in python and change it to `python` (or any other language).

### -c COMMAND, --command COMMAND
`fondle` generates the full status bar as a combination of notifications and your status script.
That final output is a string which can be passed as the argument to any command.
By default this is set to `echo` which results in `echo my-bar-contents`.
If you're using dwm, you should change this to `xsetroot -name`.

### -t DEFAULT_TIMEOUT, --default-timeout DEFAULT_TIMEOUT
This is the default time a notification will be displayed.
It's set to `3.0` seconds by default.

### -m MAX_TIMEOUT, --max-timeout MAX_TIMEOUT
If a notification is received that has a very long timeout, this is max it is allowed to remain displayed.
It's set to `5.0` seconds by default.

### -l MAX_LENGTH, --max-length MAX_LENGTH
Notifications are displayed as `PREPEND + SUMMARY + SEPARATOR + BODY + APPEND`.
With default settings, a notification might look like this: `warning: battery is running low `.
This setting allows you to limit the length of the body of a notification.
This is mostly useful if you have limited bar space.
For example, limiting the body to `-l 7` would result in `warning: battery... `.
If you set `-l 0`, no body or separator will be displayed at all: `warning `.

### -u UPDATE_INTERVAL, --update-interval UPDATE_INTERVAL
This is the interval with which you want the status to update.
It defaults to `2.0` seconds.

### -r, --replace-status  replace the status information with notification
This is a flag which determines if the notification just pops up on your status bar or if it completely replaces your status when it is present.
statnot replaced the status entirely while qtile integrates it with the bar.
Here is an example without this flag: `warning: battery low | status text here`.
While with the `-r` flag: `warning: battery low`.
Of course, the status returns as soon as the notification expires.

### -s SEPARATOR, --separator SEPARATOR
This separates the summary and body of the notification.
By default it is `: `: `summary: body`.
If the `--max-length` is set to `0`, this separator is not used.

### -p PREPEND, --prepend PREPEND
This is a string that appears before the summary of the notification.
It defaults to an empty string.
You can use it to apply formatting options in spectrwm bar for example.

### -a APPEND, --append APPEND
This is a string that appears after the body of the notification.
It defaults to a single space: ` `.
You may want to change it to something like ` | `.

## Example usage
Depending on your setup, you can run `fondle` in a variety of ways.
Just as an example, we'll assume you have a script to generate your status stored in `.config/mybar.sh`.
We'll keep the options as simple as possible.

### dwm

```sh
fondle ~/.config/mybar.sh -c "xsetroot -name"
```

### spectrwm
spectrwm seems to require a shell script for its `bar_action` configuration option.
That's no problem.
We can create a simple script containing our options and then add that to the configuration:

```sh
#!/usr/bin/sh

fondle ~/.config/mybar.sh
```

spectrwm also supports using colors in the bar by setting `bar_action_expand = 1` in its configuration.
We can then add the spectrwm bar markup directly in our `fondle` options:

```sh
#!/usr/bin/sh

fondle ~/.config/mybar.sh --prepend '+@bg=1' --append '+@bg=0 '
```

Maybe you even want to use different markup for the summary and the body of the notification:

```sh
#!/usr/bin/sh

fondle ~/.config/mybar.sh --prepend '+@bg=1' --separator '+@bg=0: +@bg=2' --append '+@bg=0'
```

### lemonbar

```sh
fondle ~/.config/mybar.sh | lemonbar
```

### i3status
You can replace the i3status command entirely via the bar config:

```
bar {
    status_command fondle ~/.config/mybar.sh
}
```

I'm still testing the best way to combine the output of i3status with `fondle`.
For now, the best I can do is replace the output of i3status when you get a notification but the timing isn't correct.
To do this, you need to add `output_format = none` in your general block of the i3status configuration.
Then you can replace the i3status command in the bar config like this:

```
bar {
    status_command fondle & i3status
}
```

If you find a better way, let me know.

### xmobar
This is untested but I believe you can just pipe the output into xmobar like this:

```sh
fondle ~/.config/mybar.sh | xmobar -o -t "%StdinReader%" -c "[Run StdinReader]"
```

## Future work
### python-dbus-next
I'd love to reimplement the dbus communication with python-dbus-next.
Since it's a pure python implementation, it reduce the size of the dependencies and make it much easier to install.
Unfortunately, I'm still too inexperienced with the dbus interface to get this working right now.

### man
Write a proper manpage.

### notification tips
There are method of cleverly using notifications to display important information only when relevant with `fondle`.
I'll try to expand this section as soon as possible.

## License
Released under the GNU General Public License v3.0
