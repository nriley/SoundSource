SoundSource
===========

This project contains a version of Rogue Amoeba's SoundSource
with an added command line tool for switching audio devices
and setting volume.

The command line tool has no man page yet, but here's a simple
example of how to use it:

    % soundsource
    Output (volume 0.001):
    * Andrea PureAudio USB-SA Headset
      Furrball II
      Internal Speakers
      ZoomSwitch USB Adapter
    Input (volume 0.926):
      Andrea PureAudio USB-SA Headset: External Line Connector
      Andrea PureAudio USB-SA Headset: External SPDIF Interface
    * Andrea PureAudio USB-SA Headset: Microphone
      Line In
      ZoomSwitch USB Adapter
    System (volume 1.000):
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
[on my blog](http://njr.sabi.net/2014/06/21/soundsource-a-few-examples/).
