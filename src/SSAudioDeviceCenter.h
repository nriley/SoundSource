//
//  SSAudioDeviceCenter.h
//  SoundSource
//
//  Created by Quentin Carnicelli on 3/23/06.
//  Copyright 2006 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>

@interface SSAudioDevice : NSObject
{
	AudioDeviceID	_deviceID;
	OSType			_sourceType;
	BOOL			_isInput;
}

- (id)initWithAudioDeviceID: (AudioDeviceID)deviceID source: (OSType)source isInput: (BOOL)flag;

- (BOOL)isEqual: (SSAudioDevice*)device;
- (NSComparisonResult)compare: (SSAudioDevice*)device;

- (NSString*)name;
- (BOOL)canBeDefaultDevice;
- (BOOL)canBeDefaultSystemDevice;

- (AudioDeviceID)coreAudioDeviceID;
- (BOOL)coreAudioIsInput;
- (OSType)coreAudioSourceType;
- (OSType)fetchCoreAudioSourceType;

@end

@interface SSAudioDeviceCenter : NSObject
{
	BOOL			_audioFollowsJack;
	AudioDeviceID	_previousDefaultDevice;
}

- (id)init;

- (NSArray*)inputDevices;
- (NSArray*)outputDevices;

- (SSAudioDevice*)deviceWithID: (AudioDeviceID)deviceID isInput: (BOOL)isInput;
- (NSArray*)devicesWithTransportType: (unsigned)type isInput: (BOOL)isInput;

- (void)setSelectedInputDevice: (SSAudioDevice*)device;
- (SSAudioDevice*)selectedInputDevice;
- (void)setSelectedOutputDevice: (SSAudioDevice*)device;
- (SSAudioDevice*)selectedOutputDevice;
- (void)setSelectedSystemDevice: (SSAudioDevice*)device;
- (SSAudioDevice*)selectedSystemDevice;

- (float)inputVolume;
- (void)setInputVolume: (float)vol;
- (float)outputVolume;
- (void)setOutputVolume: (float)vol;
- (float)systemVolume;
- (void)setSystemVolume: (float)vol;

- (BOOL)supportsAudioFollowsJack;
- (void)setAudioFollowsJack: (BOOL)flag;
- (BOOL)audioFollowsJack;

@end
