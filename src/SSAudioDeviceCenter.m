//
//  SSAudioDeviceCenter.m
//  SoundSource
//
//  Created by Quentin Carnicelli on 3/23/06.
//  Copyright 2006 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "SSAudioDeviceCenter.h"

#import <Carbon/Carbon.h>
#import <CoreAudio/CoreAudio.h>
#import <IOKit/audio/IOAudioTypes.h>
#include <sys/types.h>
#include <sys/sysctl.h>


@interface SSAudioDeviceCenter (Private)
static OSStatus devicePropertyChanged( AudioDeviceID deviceID, UInt32 inChannel, Boolean isInput,
									   AudioDevicePropertyID inPropertyID, void *inClientData );
@end

@implementation SSAudioDevice

- (id)initWithAudioDeviceID: (AudioDeviceID)deviceID source: (OSType)source isInput: (BOOL)flag
{
	if( deviceID == kAudioDeviceUnknown )
	{
		[self release];
		return nil;
	}

	if( (self = [super init]) != nil )
	{
		_deviceID = deviceID;
		_sourceType = source;
		_isInput = flag;
	}
	
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (NSString*)description
{
	return [NSString stringWithFormat: @"<%@: %@ (%d)>", [self class], [self name], (unsigned int)[self coreAudioDeviceID]];
}

- (BOOL)isEqual: (SSAudioDevice*)device
{
	return ([self coreAudioDeviceID] == [device coreAudioDeviceID]) &&
		   ([self coreAudioSourceType] == [device coreAudioSourceType]) &&
		   ([self coreAudioIsInput] == [device coreAudioIsInput]);
}

- (NSComparisonResult)compare: (SSAudioDevice*)device
{
	return [[self name] caseInsensitiveCompare: [device name]];
}

- (NSString*)name
{
	OSStatus err;
	UInt32 size;
	NSString* deviceName = nil;
	NSString* sourceName = nil;

	{
		size = sizeof(deviceName);
		err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDeviceNameCFString, &size, &deviceName);
		if( err  )
			deviceName = nil;
	}

	if( _sourceType != 0 )
	{
		AudioValueTranslation trans;

		trans.mInputData		= &_sourceType;
		trans.mInputDataSize	= sizeof(_sourceType);
		trans.mOutputData		= &sourceName;
		trans.mOutputDataSize	= sizeof(sourceName);
		size = sizeof(AudioValueTranslation);
		err = AudioDeviceGetProperty( [self coreAudioDeviceID] , 0, [self coreAudioIsInput], kAudioDevicePropertyDataSourceNameForIDCFString, &size, &trans);
		if( err )
			sourceName = nil;
	}
	
	if( sourceName && ![sourceName isEqual: deviceName] )
	{
        // If >1 source on device, use DeviceName: SourceName (doesn't match Sound prefpane, but is much easier to understand)
		if( !AudioDeviceGetPropertyInfo([self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDataSources, &size, NULL) )
		{
			if( size > sizeof(UInt32) )
				return [NSString stringWithFormat: @"%@: %@", deviceName, sourceName];
		}
	}

	return sourceName ? sourceName : deviceName;
}

- (BOOL)canBeDefaultDevice
{
	OSStatus err;
	UInt32 canBe;
	UInt32 size = sizeof(canBe);
	
	err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDeviceCanBeDefaultDevice, &size, &canBe);

	return (err == noErr) && (canBe == 1);
}

- (BOOL)canBeDefaultSystemDevice
{
	OSStatus err;
	UInt32 canBe;
	UInt32 size = sizeof(canBe);
	
	err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDeviceCanBeDefaultSystemDevice, &size, &canBe);

	return (err == noErr) && (canBe == 1);
}

- (AudioDeviceID)coreAudioDeviceID
{
	return _deviceID;
}

- (OSType)coreAudioSourceType
{
	return _sourceType;
}

- (OSType)selectedCoreAudioSourceType
{
	OSStatus err;
	OSType sourceType;
	UInt32 size = sizeof(sourceType);
	
	err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyDataSource, &size, &sourceType);
	if( err )
		sourceType = 0;
	return sourceType;
}

- (BOOL)coreAudioIsInput
{
	return _isInput;
}

- (unsigned)coreAudioTransportType
{
	OSStatus err;
	UInt32 trans;
	UInt32 size = sizeof(trans);
	
	err = AudioDeviceGetProperty( [self coreAudioDeviceID], 0, [self coreAudioIsInput], kAudioDevicePropertyTransportType, &size, &trans);
	if( err )
		return 0;
	return trans;
}

@end

#pragma mark -

@implementation SSAudioDeviceCenter

// stuff from AudioServices we can't include directly because we need 10.4 compatibility
static OSStatus (*AudioHardwareServiceGetPropertyDataPtr)(AudioObjectID                       inObjectID,
														  const AudioObjectPropertyAddress* inAddress,
														  UInt32 inQualifierDataSize,
														  const void* inQualifierData,
														  UInt32* ioDataSize,
														  void* outData);
static OSStatus (*AudioHardwareServiceSetPropertyDataPtr)(AudioObjectID inObjectID,
														  const AudioObjectPropertyAddress* inAddress,
														  UInt32 inQualifierDataSize,
														  const void* inQualifierData,
														  UInt32 inDataSize,
														  const void* inData);
static Boolean (*AudioHardwareServiceHasPropertyPtr)(AudioObjectID inObjectID,
													 const AudioObjectPropertyAddress* inAddress);

+ (void)initialize
{
	NSURL *url = [NSURL fileURLWithPath: @"/System/Library/Frameworks/AudioToolbox.framework"];
	CFBundleRef bundle = CFBundleCreate( NULL, (CFURLRef)url );
	if( bundle )
	{
		AudioHardwareServiceGetPropertyDataPtr = CFBundleGetFunctionPointerForName( bundle, CFSTR("AudioHardwareServiceGetPropertyData") );
		AudioHardwareServiceSetPropertyDataPtr = CFBundleGetFunctionPointerForName( bundle, CFSTR("AudioHardwareServiceSetPropertyData") );
		AudioHardwareServiceHasPropertyPtr = CFBundleGetFunctionPointerForName( bundle, CFSTR("AudioHardwareServiceHasProperty") );
	}
}

- (id)init
{
	if( (self = [super init]) != nil )
	{
	}
	
	return self;
}

- (void)dealloc
{
	AudioDeviceRemovePropertyListener( 0, 0, 0, kAudioDevicePropertyDataSource, devicePropertyChanged );

	[super dealloc];
}

- (NSArray*)_allDevicesWithDeviceID: (AudioDeviceID)deviceID isInput: (BOOL)isInput
{
	NSMutableArray* objList = [NSMutableArray array];
	UInt32			size;
	int				i, count;
	OSType			*list;
	SSAudioDevice	*device;

	if( !AudioDeviceGetPropertyInfo(deviceID, 0, isInput, kAudioDevicePropertyDataSources, &size, NULL) )
	{
		count	= size / sizeof(OSType);
		if( count )
		{
			list	= alloca(size);
			if( !AudioDeviceGetProperty(deviceID, 0, isInput, kAudioDevicePropertyDataSources, &size, list))
			{
				for (i = 0; i < count; i++)
				{
					device = [[SSAudioDevice alloc] initWithAudioDeviceID: deviceID source: list[i] isInput: isInput];
					[objList addObject: device];
					[device release];
				}
			}
		}
	}

	if( ![objList count] )
	{
		device = [[SSAudioDevice alloc] initWithAudioDeviceID: deviceID source: 0 isInput: isInput];
		[objList addObject: device];
		[device release];
	}
	
	return objList;
}

- (NSArray*)_loadDeviceList: (BOOL)isInput
{
	NSMutableArray* deviceList = [NSMutableArray array];
	UInt32			size;
	int				i, count;
	AudioDeviceID*	list;
	NSArray*		tmpList;

	if (AudioHardwareGetPropertyInfo(kAudioHardwarePropertyDevices, &size, NULL))
		return nil;

	count	= size / sizeof(AudioDeviceID);
	list	= (AudioDeviceID *) alloca(count * sizeof(AudioDeviceID));
	if (AudioHardwareGetProperty(kAudioHardwarePropertyDevices, &size, list))
		return nil;

	for (i = 0; i < count; i++)
	{
		if (!AudioDeviceGetPropertyInfo(list[i], 0, isInput, kAudioDevicePropertyStreamConfiguration,  &size, NULL))
		{
			AudioBufferList* bufferList = (AudioBufferList*)malloc(size);
			
			if (!AudioDeviceGetProperty(list[i], 0, isInput, kAudioDevicePropertyStreamConfiguration, &size, bufferList))
			{
				if (bufferList->mNumberBuffers)
				{
					tmpList = [self _allDevicesWithDeviceID: list[i] isInput: isInput];
					if( tmpList )
						[deviceList addObjectsFromArray: tmpList];
				}
			}
		
			free( bufferList );
		}
	}

	return deviceList;
}

- (NSArray*)inputDevices
{
	return [self _loadDeviceList: YES];
}

- (NSArray*)outputDevices
{
	return [self _loadDeviceList: NO];
}

- (SSAudioDevice*)deviceWithID: (AudioDeviceID)deviceID isInput: (BOOL)isInput
{
	NSArray* deviceList = isInput ? [self inputDevices] : [self outputDevices];
	NSEnumerator* deviceEnum = [deviceList objectEnumerator];
	SSAudioDevice* device;
	
	while( (device = [deviceEnum nextObject]) != nil )
	{
		if ([device coreAudioDeviceID] == deviceID) {
            OSType selectedSourceType = [device selectedCoreAudioSourceType];
            while ([device coreAudioSourceType] != selectedSourceType) {
                if ((device = [deviceEnum nextObject]) == nil)
                    return nil; // ran out of devices while looking
            }
			return device;
        }
	}

	return nil;
}

- (NSArray*)devicesWithTransportType: (unsigned)type isInput: (BOOL)isInput
{
	NSArray* deviceList = isInput ? [self inputDevices] : [self outputDevices];
	NSEnumerator* deviceEnum = [deviceList objectEnumerator];
	SSAudioDevice* device;
	NSMutableArray* matches = [NSMutableArray array];
	
	while( (device = [deviceEnum nextObject]) != nil )
	{
		if( [device coreAudioTransportType] == type )
			[matches addObject: device];
	}
	
	return matches;
}

#pragma mark -

- (OSStatus)_setDefaultDeviceOfClass: (OSType)type to: (SSAudioDevice*)device
{
	AudioDeviceID deviceID = [device coreAudioDeviceID];
	OSStatus err;

	if( device == nil || deviceID == kAudioDeviceUnknown )
		return paramErr;

	err = AudioHardwareSetProperty(type, sizeof(deviceID), &deviceID);
	if( err )
	{
		NSLog( @"AudioHardwareSetProperty(%@) Error: %d", NSFileTypeForHFSTypeCode(type), (int)err );
	}

    OSType sourceType = [device coreAudioSourceType];
    if( sourceType != [device selectedCoreAudioSourceType] )
    {
        AudioObjectPropertyAddress propertyAddress = {
            .mSelector = kAudioDevicePropertyDataSource,
            .mScope = (type == kAudioHardwarePropertyDefaultInputDevice) ? kAudioDevicePropertyScopeInput : kAudioDevicePropertyScopeOutput,
            .mElement = kAudioObjectPropertyElementMaster
        };
        err = AudioObjectSetPropertyData(deviceID, &propertyAddress, 0, NULL, sizeof(sourceType), &sourceType);
        if( err )
        {
            NSLog( @"AudioObjectSetPropertyData(%@) Error: %d", NSFileTypeForHFSTypeCode(sourceType), (int)err );
        }
    }
	
	return err;
}

- (SSAudioDevice*)_defaultDeviceOfClass: (OSType)type
{
	SSAudioDevice*	device;
	AudioDeviceID	deviceID = kAudioDeviceUnknown;
	UInt32			size;
	
	size	= sizeof(deviceID);
	if( AudioHardwareGetProperty(type, &size, &deviceID) != noErr )
		return nil;
	if( deviceID == kAudioDeviceUnknown )
		return nil;

	device = [self deviceWithID: deviceID isInput: (type == kAudioHardwarePropertyDefaultInputDevice)];
	return device;
}

- (void)setSelectedInputDevice: (SSAudioDevice*)device
{
	[self _setDefaultDeviceOfClass: kAudioHardwarePropertyDefaultInputDevice to: device];
}

- (SSAudioDevice*)selectedInputDevice
{
	return [self _defaultDeviceOfClass: kAudioHardwarePropertyDefaultInputDevice];
}

- (void)setSelectedOutputDevice: (SSAudioDevice*)device
{
	[self _setDefaultDeviceOfClass: kAudioHardwarePropertyDefaultOutputDevice to: device];
}

- (SSAudioDevice*)selectedOutputDevice
{
	return [self _defaultDeviceOfClass: kAudioHardwarePropertyDefaultOutputDevice];
}

- (void)setSelectedSystemDevice: (SSAudioDevice*)device
{
	[self _setDefaultDeviceOfClass: kAudioHardwarePropertyDefaultSystemOutputDevice to: device];
}

- (SSAudioDevice*)selectedSystemDevice
{
	return [self _defaultDeviceOfClass: kAudioHardwarePropertyDefaultSystemOutputDevice];
}

#pragma mark -

- (NSString *)_stringForCAError: (OSStatus)err
{
	return [(id)UTCreateStringForOSType( err ) autorelease];
}

// pass NaN to only get, not set, volume
// returns new volume when setting
// returns NaN on error or if the device doesn't support volume changes
// bits cribbed from http://www.cocoadev.com/index.pl?SoundVolume
// much code courtesy of eddienull
- (float)_getAndSetVolume: (float)newVolume forInput: (BOOL)isInput
{
	OSStatus					theError = noErr;
	AudioObjectPropertyAddress	theAddress = { 0, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMaster };
	AudioObjectID				theObject = 0;
	UInt32						theDataSize = 0;
	Float32						theVolume[2] = { 0, 0 };
	UInt32						theChannels[2] = { kAudioObjectPropertyElementMaster, kAudioObjectPropertyElementMaster };
	int							index = 0;
	
	if (!AudioHardwareServiceGetPropertyDataPtr ) //10.4 is unsupported
		return NAN;
	
	//	get default device's object
	if( isInput )
		theAddress.mSelector = kAudioHardwarePropertyDefaultInputDevice;
	else
		theAddress.mSelector = kAudioHardwarePropertyDefaultOutputDevice;
	
	theAddress.mScope = kAudioObjectPropertyScopeGlobal;
	theAddress.mElement = kAudioObjectPropertyElementMaster;
	theDataSize = sizeof(AudioObjectID);
	theError = AudioHardwareServiceGetPropertyDataPtr(kAudioObjectSystemObject, &theAddress, 0, NULL, &theDataSize, &theObject);
	if( theError )
	{
		NSLog(@"error %@ getting device object", [self _stringForCAError: theError]);
		return NAN;
	}
	
	if( isInput )
		theAddress.mScope = kAudioDevicePropertyScopeInput;
	else
		theAddress.mScope = kAudioDevicePropertyScopeOutput;
	
	// check to see if a master channel exists
	theAddress.mSelector = kAudioDevicePropertyVolumeScalar;
	theDataSize = sizeof(Float32);
	if(!AudioHardwareServiceHasPropertyPtr(theObject, &theAddress))
	{
		// no master channel, try to get preferred stereo channels
		// default values: if no preferred stereo channels, just set channel 1
		theChannels[0] = 1;
		theChannels[1] = 1;
		
		theAddress.mSelector = kAudioDevicePropertyPreferredChannelsForStereo;
		if(AudioHardwareServiceHasPropertyPtr(theObject, &theAddress))
		{
			theDataSize = sizeof(theChannels);
			theError = AudioHardwareServiceGetPropertyDataPtr(theObject, &theAddress, 0, NULL, &theDataSize, &theChannels);
			if( theError )
			{
				NSLog(@"error %@ getteing preferred stereo channels", [self _stringForCAError: theError]);
				return NAN;
			}
		}
	}
	
	// if it still doesn't work, just bail out, can't set the volume for this device
	{
		BOOL hasSettableChannel = NO;
		
		for(index = 0; index < 2; index++ )
		{
			theAddress.mSelector = kAudioDevicePropertyVolumeScalar;
			theAddress.mElement = theChannels[index];
			hasSettableChannel = AudioHardwareServiceHasPropertyPtr(theObject, &theAddress);
			if( hasSettableChannel )
				break;
		}

		if(!hasSettableChannel)
			return NAN;
	}
	
	// set the volume if it was requested
	if( !isnan( newVolume ) )
	{
		theAddress.mSelector = kAudioDevicePropertyVolumeScalar;
		theDataSize = sizeof(Float32);
		
		// do one set per channel
		// this will duplicate channels in some cases, but there's no harm
		// just some inefficiency
		for(index = 0; index < 2; index++ )
		{
			theAddress.mElement = theChannels[index];
			theError = AudioHardwareServiceSetPropertyDataPtr(theObject, &theAddress, 0, NULL, theDataSize, &newVolume);
			if( theError )
			{
				NSLog(@"error %@ setting device volume for channel %ud", [self _stringForCAError: theError], (unsigned int)theAddress.mElement);
				return NAN;
			}
		}
	}
	
	// finally get the current volume
	theAddress.mSelector = kAudioDevicePropertyVolumeScalar;
	theDataSize = sizeof(Float32);
	
	// do one get per channel and average the two
	// this can duplicate channels again, but again no harm
	for(index = 0; index < 2; index++ )
	{
		theAddress.mElement = theChannels[index];
		theError = AudioHardwareServiceGetPropertyDataPtr(theObject, &theAddress, 0, NULL, &theDataSize, &theVolume[index]);
		if( theError )
		{
			NSLog(@"error %@ getting device volume for channel %u", [self _stringForCAError: theError], (unsigned int)theAddress.mElement);
			return NAN;
		}
	}
	
	return (theVolume[0] + theVolume[1]) / 2.0;
}

- (float)inputVolume
{
	return [self _getAndSetVolume: NAN forInput: YES];
}

- (void)setInputVolume: (float)vol
{
	[self _getAndSetVolume: vol forInput: YES];
}

- (float)outputVolume
{
	return [self _getAndSetVolume: NAN forInput: NO];
}

- (void)setOutputVolume: (float)vol
{
	[self _getAndSetVolume: vol forInput: NO];
}

static const float kSystemVolumeConversionPower = 1.38;

- (float)systemVolume
{
	long level = 0;
	OSErr err = GetSysBeepVolume( &level );
	if( err )
	{
		NSLog( @"Getting alert volume got error %d", err );
		return NAN;
	}
	
	float volume = pow( (float)level / (1 << 24), kSystemVolumeConversionPower );
	return volume;
}

- (void)setSystemVolume: (float)vol
{
	vol = pow( vol, 1.0/kSystemVolumeConversionPower );
	OSErr err = SetSysBeepVolume( vol * (1 << 24) );
	if( err )
		NSLog( @"Setting alert volume got error %d", err );
}	

#pragma mark -

- (SSAudioDevice*)_headphoneDevice
{
	return nil;
}

- (void)_devicePropertyChanged: (NSDictionary*)args
{
	AudioDeviceID deviceID = [[args objectForKey: @"device"] intValue];
	BOOL isInput = [[args objectForKey: @"isInput"] boolValue];
	AudioDeviceID currentDefaultDevice;
	OSType changedDeviceSource;
	AudioDeviceID newDefaultDevice;
	
	if( !_audioFollowsJack )
		return;

	changedDeviceSource = [[self deviceWithID: deviceID isInput: isInput] selectedCoreAudioSourceType];
	currentDefaultDevice = [[self selectedOutputDevice] coreAudioDeviceID];
	newDefaultDevice = 0;

	if( changedDeviceSource == kIOAudioOutputPortSubTypeHeadphones )
	{
		if( deviceID != currentDefaultDevice )
		{
			newDefaultDevice = deviceID;
			_previousDefaultDevice = currentDefaultDevice;
		}
	}
	else if( changedDeviceSource == kIOAudioOutputPortSubTypeInternalSpeaker )
	{
		if( deviceID == currentDefaultDevice )
		{
			newDefaultDevice = _previousDefaultDevice;
		}
	}
		
	if( newDefaultDevice )
	{
		SSAudioDevice* newDefaultDeviceObj = [self deviceWithID: newDefaultDevice isInput: isInput];
		[self setSelectedOutputDevice: newDefaultDeviceObj];
	}
}

static OSStatus devicePropertyChanged( AudioDeviceID deviceID, UInt32 inChannel, Boolean isInput,
									   AudioDevicePropertyID inPropertyID, void *inClientData )
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	SSAudioDeviceCenter* deviceCenter = (SSAudioDeviceCenter*)inClientData;
	NSDictionary* args;
	
	args = [NSDictionary dictionaryWithObjectsAndKeys: 
				[NSNumber numberWithInt: deviceID],  @"device",
				[NSNumber numberWithBool: isInput], @"isInput",
				[NSNumber numberWithInt: inPropertyID], @"property",
				nil];
	
	[deviceCenter performSelectorOnMainThread: @selector(_devicePropertyChanged:) withObject: args waitUntilDone: NO];
	
	[pool release];
	return noErr;
}

- (BOOL)supportsAudioFollowsJack
{
#if 1
	char hwNameStr[128];
	size_t hwNameLen = sizeof(hwNameStr);
	
	if( sysctlbyname( "hw.model", &hwNameStr, &hwNameLen, NULL, 0 ) == 0 )
	{
		NSString* hwName = [NSString stringWithCString: hwNameStr encoding: NSASCIIStringEncoding];
		
		if( [hwName hasPrefix: @"MacPro"] )
			return YES;
	}
	
	return NO;
#else
	return NO;
#endif
}

- (void)setAudioFollowsJack: (BOOL)flag
{
	BOOL isInput = NO;
	NSArray* deviceList = isInput ? [self inputDevices] : [self outputDevices];
	NSEnumerator* deviceEnum = [deviceList objectEnumerator];
	SSAudioDevice* device;
	OSStatus status;
	
	if( ![self supportsAudioFollowsJack] )
		return;
	
	_audioFollowsJack = flag;
	_previousDefaultDevice = [[self selectedOutputDevice] coreAudioDeviceID];

	while( (device = [deviceEnum nextObject]) != nil )
	{
		if( [device coreAudioTransportType] == kIOAudioDeviceTransportTypeBuiltIn )
		{
			if( flag )
			{
				status = AudioDeviceAddPropertyListener( [device coreAudioDeviceID], 0, [device coreAudioIsInput],
														  kAudioDevicePropertyDataSource, devicePropertyChanged, self);
			
				if( [device selectedCoreAudioSourceType] == kIOAudioOutputPortSubTypeHeadphones )
				{
					if( [device coreAudioDeviceID] != _previousDefaultDevice )
						[self setSelectedOutputDevice: device];
				}
			}
			else
				status = AudioDeviceRemovePropertyListener( [device coreAudioDeviceID], 0, [device coreAudioIsInput],
															kAudioDevicePropertyDataSource, devicePropertyChanged );
		}
	}
}

- (BOOL)audioFollowsJack
{
	return _audioFollowsJack;
}


@end
