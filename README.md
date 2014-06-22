SoundSource
===========

This project contains a version of Rogue Amoeba's SoundSource
with an added command line tool for switching audio devices.

The command line tool has no help, decent error handling or man
page yet, but here's a simple example of how to use it:

    % soundsource
    Output (volume 0.1):
      BT-Headphones Stereo
      C-Media USB Headphone Set  
      CALLPOD DRAGON
    * Furrball
      Internal Speakers
      Motorola S9-HD Stereo
      scala-500
      Soundflower (16ch)
      Soundflower (2ch)
    Input (volume 0.5):
    * C-Media USB Headphone Set  
      CALLPOD DRAGON
      Line In
      scala-500
      Soundflower (16ch)
      Soundflower (2ch)
    System (volume 1.0):
    * Internal Speakers
    % soundsource -i
    C-Media USB Headphone Set  
    % soundsource -o
    Furrball
    % soundsource -s
    Internal Speakers
    % soundsource -o 'C-Media USB Headphone Set'
    % soundsource -o
    C-Media USB Headphone Set  

A few examples of using `soundsource` in scripts are
[on my blog](http://njr.sabi.net/2014/06/21/soundsource-a-few-examples/).
