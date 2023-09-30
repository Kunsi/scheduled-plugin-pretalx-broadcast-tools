# pretalx-broadcast-tools plugin for the info-beamer 'scheduled-player' package

Please note this plugin requires you to install
[pretalx-broadcast-tools >= 2.1.0](https://github.com/Kunsi/pretalx-plugin-broadcast-tools)
to your pretalx instance. This plugin will not work with a vanilla
pretalx installation!

[Import this package to info-beamer.com](https://info-beamer.com/use?url=https%3A%2F%2Fgithub.com%2FKunsi%2Fscheduled-plugin-pretalx-broadcast-tools.git)

## Features

* show the next talk in the configured room
* show all future (not-yet-ended) talk in all rooms
* show the current conference day
* show the configured room name

The plugin will automatically fetch related information from pretalx
itself. This includes:

* event start date
* event end date
* track information and colours

## Screenshots

All talk information have been generated by
`python -m pretalx create_test_event`.

## Next talk

The screenshot shows the room name "Peru Room" on the top left, followed
by the current day information ("Day 1").

In the center, you see the "next talk" display option, showing the talk
title, the abstract and the speaker name next to the information about
when the talk will start, both as a time stamp and a "in xxx min"
information. Inbetween you see the track bar, which is a neon green shade.

On the bottom there's the same view, but this time the abstract and the
track bar is missing. The track name is visible as coloured text below
the speaker name.

[![Screenshot showing the above mentioned screen](next_thumb.jpg)](next_talk.jpg)

## All talks

On this screenshot you can see a listing of nine future talks. The design
follows the "next talk" view, but only shows "in xxx min" for talks less
than 30 minutes into the future, and the time stamp otherwise.

The room information and speaker names are condensed into one line.

[![Screenshot showing the above mentioned screen](all_thumb.jpg)](all_talks.jpg)
