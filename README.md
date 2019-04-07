SoundSource
===========

This project contains a version of Rogue Amoeba's SoundSource 2.5
with an added command line tool for switching audio devices
and setting volume.

If you want a graphical version of SoundSource, you can get one from
[Rogue Amoeba](https://rogueamoeba.com/soundsource/).  Current
versions of Rogue Amoeba's SoundSource are commercial products, not
open source.

The command line tool has no man page yet, but here's a simple
example of how to use it:

    % soundsource -h
    usage: soundsource [-ios] [device]
       or: soundsource [-IOS] volume
       or: soundsource [-Mm]
      -i         display selected audio input device
      -o         display selected audio output device
      -s         display output device used for alert sounds, sound effects
      -i device  set selected audio input device
      -o device  set selected audio output device
      -s device  set output device used for alert sounds, sound effects
      -I         display selected audio input device's volume
      -O         display selected audio output device's volume
      -S         display alert sounds/sound effects volume
      -I volume  set selected audio input device's volume
      -O volume  set selected audio output device's volume
      -S volume  set alert sounds/sound effects volume
      -M         mute selected audio output device
      -m         unmute selected audio output device
    With no arguments, displays available/selected (*) devices and volumes.
    % soundsource
    Output (volume 0.001):
      AirPlay: Furrball
      AirPlay: Furrball II
    * Andrea PureAudio USB-SA Headset
      BW900 HS
      Internal Speakers
      Soundflower (16ch)
      Soundflower (2ch)
      ZoomSwitch USB Adapter
    Input (volume 0.926):
      Andrea PureAudio USB-SA Headset: External Line Connector
      Andrea PureAudio USB-SA Headset: External SPDIF Interface
    * Andrea PureAudio USB-SA Headset: Microphone
      BW900 HS
      Line In
      Soundflower (16ch)
      Soundflower (2ch)
      ZoomSwitch USB Adapter
    System (volume 0.989):
    * Internal Speakers
    % soundsource -i
    Andrea PureAudio USB-SA Headset: Microphone
    % soundsource -o
    Andrea PureAudio USB-SA Headset
    % soundsource -s
    Internal Speakers
    % soundsource -o 'Internal Speakers'
    % soundsource -o
    Internal Speakers
    % soundsource -O 0.8
    % soundsource -O    
    0.802

A few examples of using `soundsource` in scripts are
[on my blog](https://njr.sabi.net/2014/06/21/soundsource-a-few-examples/).
