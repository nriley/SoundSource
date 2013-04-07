//
//  SSAppController.m
//  SoundSource
//
//  Created by Quentin Carnicelli on 8/24/09.
//  Copyright 2009 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "SSAppController.h"
#import "SSAboutBox.h"
#import "SSAudioDeviceCenter.h"
#import "SSMenuVolumeSliderView.h"
#import "SSPreferences.h"
#import "SSLegacy.h"


@implementation SSAppController

- (void)_setupModel
{
	_prefs = [[SSPreferences alloc] init];

	_deviceCenter = [[SSAudioDeviceCenter alloc] init];
	
	if( [_deviceCenter supportsAudioFollowsJack] )
		[_deviceCenter setAudioFollowsJack: [_prefs audioFollowsJack]];

	if( [SSLegacy uninstallMenuExtra] ) 
		[_prefs setOpenAtLogin: YES]; //We uninstalled old SS, probably want this
}

+ (NSImage*)_loadImageNamed: (NSString*)name
{
	NSString *path;
	NSImage* image = nil;

	path = [[NSBundle bundleForClass: self] pathForImageResource:name];
	if( path )
		image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	return image;
}

+ (NSImage*)_headphonesImage: (BOOL)highlighted
{
	static NSImage* bgImage = nil;
	static NSImage* bgImageAlt = nil;
	
	/* Leopard or later system */
	if( bgImage == nil )
	{
		{
			NSImage* newImg = [NSImage imageNamed: @"menuIconBlack"];
			bgImage = [[NSImage alloc] initWithSize: NSMakeSize( [newImg size].width, [newImg size].height+1.5 )];
			[bgImage lockFocus];
            [newImg drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
			// [newImg compositeToPoint: NSZeroPoint operation: NSCompositeSourceOver];
			[bgImage unlockFocus];
		}

		{
			NSImage* newImg = [NSImage imageNamed: @"menuIconAlt"];
			bgImageAlt = [[NSImage alloc] initWithSize: NSMakeSize( [newImg size].width, [newImg size].height+1.5 )];
			[bgImageAlt lockFocus];
            [newImg drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeSourceOver fraction: 1.0];
			// [newImg compositeToPoint: NSZeroPoint operation: NSCompositeSourceOver];
			[bgImageAlt unlockFocus];
		}

		//bgImage = [[self _loadImageNamed: @"menuIconBlack"] retain];
		//[bgImage setTemplate: YES]; // Leopard only
		
		//bgImageAlt = [[self _loadImageNamed: @"menuIconAlt"] retain];
		//[bgImageAlt setTemplate: YES]; // Leopard only
	}

	return highlighted ? bgImageAlt : bgImage;
}

- (void)_setupView
{
	_statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength: 25.0f] retain]; //No, I -don't- know where 25 came from...

	{
		[_statusItem setImage: [[self class] _headphonesImage: NO]];
		[_statusItem setAlternateImage: [[self class] _headphonesImage: YES]];
		[_statusItem setHighlightMode: YES];
	}
	
	{
		NSMenu* menu = [[NSMenu alloc] initWithTitle: @"SoundSource status item"];
		[menu setDelegate: self];
		[_statusItem setMenu: menu];
		[menu release];
	}
}

- (void)applicationDidFinishLaunching: (NSNotification*)note
{
	[self _setupModel];
	[self _setupView];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[_prefs release];
	_prefs = nil;

	[_deviceCenter release];
	_deviceCenter = nil;
	
	[_statusItem autorelease];
	_statusItem = nil;
}

#pragma mark -

- (IBAction)hitOpenAbout: (id)sender
{
	[[NSApplication sharedApplication] activateIgnoringOtherApps: YES];
	[[SSAboutBox sharedAboutBox] showWindow: self];
}

- (IBAction)hitOpenSoundPrefs: (id)sender
{
	[[NSWorkspace sharedWorkspace] openFile: @"/System/Library/PreferencePanes/Sound.prefPane"];
}

- (IBAction)hitOpenAMS: (id)sender
{
	[[NSWorkspace sharedWorkspace]
		launchAppWithBundleIdentifier: @"com.apple.audio.AudioMIDISetup"
		options: NSWorkspaceLaunchDefault
		additionalEventParamDescriptor: nil
		launchIdentifier: nil];
}

- (IBAction)hitSelectInputDevice: (id)sender
{
	SSAudioDevice* device = [sender representedObject];
	if( device && [device isKindOfClass: [SSAudioDevice class]] )
		[_deviceCenter setSelectedInputDevice: device];
}

- (IBAction)hitSelectOutputDevice: (id)sender
{
	SSAudioDevice* device = [sender representedObject];
	if( device && [device isKindOfClass: [SSAudioDevice class]] )
		[_deviceCenter setSelectedOutputDevice: device];
}

- (IBAction)hitSelectSystemDevice: (id)sender
{
	SSAudioDevice* device = [sender representedObject];
	if( device && [device isKindOfClass: [SSAudioDevice class]] )
		[_deviceCenter setSelectedSystemDevice: device];
}

- (IBAction)hitAudioFollowsJack: (id)sender
{
	[_prefs setAudioFollowsJack: ![_prefs audioFollowsJack]];
	[_deviceCenter setAudioFollowsJack: [_prefs audioFollowsJack]];
}

- (IBAction)hitOpenAtLogin: (id)sender
{
	[_prefs setOpenAtLogin: ![_prefs openAtLogin]];
}

- (void)_menu: (NSMenu*)menu addAudioDevices: (NSArray*)devices selection: (SSAudioDevice*)selectedDevice action: (SEL)action
{
	NSMenuItem* menuItem;

	if( ![devices count] )
	{
		menuItem = (NSMenuItem*)[menu addItemWithTitle: @"<No Devices>" action: nil keyEquivalent: @""];
		[menuItem setIndentationLevel: 1];
	}
	else
	{
		NSEnumerator* deviceEnum;
		SSAudioDevice* device;
		NSString* deviceName;

		devices = [devices sortedArrayUsingSelector: @selector(compare:)];

		deviceEnum = [devices objectEnumerator];
		
		while( (device = [deviceEnum nextObject]) != nil )
		{
			deviceName = [device name];
			if( !deviceName )
				deviceName = @"(Untitled Device)";
			
			menuItem = (NSMenuItem*)[menu addItemWithTitle: deviceName action: action keyEquivalent: @""];
			[menuItem setTarget: self];
			[menuItem setRepresentedObject: device];
			[menuItem setState: [device isEqual: selectedDevice]];
			[menuItem setIndentationLevel: 1];

			if( action == @selector(hitSelectSystemDevice:) ) //:FIXME: Too ugly
				[menuItem setEnabled: [device canBeDefaultSystemDevice]];
			else
				[menuItem setEnabled: [device canBeDefaultDevice]];
		}
	}
}

- (void)_addSliderItemToMenu: (NSMenu*)menu kind: (int)kind
{
	if( floor(NSAppKitVersionNumber) > 824 /*NSAppKitVersionNumber10_4*/ )
	{
		NSMenuItem *item = (NSMenuItem*)[menu addItemWithTitle: @"" action: nil keyEquivalent: @""];
		SSMenuVolumeSliderView *view = [[SSMenuVolumeSliderView alloc] initWithFrame: NSMakeRect( 0, 0, 10, 18 ) deviceCenter: _deviceCenter];
		[view setAutoresizingMask: NSViewWidthSizable];
		[view setKind: kind];
		[(id)item setView: view];
		[view release];
	}
}

- (void)menuNeedsUpdate:(NSMenu*)menu
{
	NSMenuItem* menuItem;
		
	while( [menu numberOfItems] > 0 )
		[menu removeItemAtIndex: 0];
	
	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"Output" action: nil keyEquivalent: @""];
	[self _addSliderItemToMenu: menu kind: kSSMenuVolumeOutputKind];
	[self	_menu: menu
			addAudioDevices: [_deviceCenter outputDevices]
			selection: [_deviceCenter selectedOutputDevice]
			action: @selector(hitSelectOutputDevice:)];
	
	[menu addItem: [NSMenuItem separatorItem]];

	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"Input" action: nil keyEquivalent: @""];
	[self _addSliderItemToMenu: menu kind: kSSMenuVolumeInputKind];
	[self	_menu: menu
			addAudioDevices: [_deviceCenter inputDevices]
			selection: [_deviceCenter selectedInputDevice]
			action: @selector(hitSelectInputDevice:)];
	
	[menu addItem: [NSMenuItem separatorItem]];
	
	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"System" action: nil keyEquivalent: @""];
	[self _addSliderItemToMenu: menu kind: kSSMenuVolumeSystemKind];
	[self	_menu: menu
			addAudioDevices: [_deviceCenter outputDevices]
			selection: [_deviceCenter selectedSystemDevice]
			action: @selector(hitSelectSystemDevice:)];

	if( [_deviceCenter supportsAudioFollowsJack] )
	{
		[menu addItem: [NSMenuItem separatorItem]];
		menuItem = (NSMenuItem*)[menu addItemWithTitle: @"Auto-Switch to Headphones" action: @selector(hitAudioFollowsJack:) keyEquivalent: @""];
		[menuItem setState: [_deviceCenter audioFollowsJack]];
		[menuItem setTarget: self];
	}

	[menu addItem: [NSMenuItem separatorItem]];

	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"Open Sound Preferences..." action: @selector(hitOpenSoundPrefs:) keyEquivalent: @""];
	[menuItem setTarget: self];

	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"Open Audio MIDI Setup..." action: @selector(hitOpenAMS:) keyEquivalent: @""];
	[menuItem setTarget: self];
	[menu addItem: [NSMenuItem separatorItem]];

	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"About SoundSource" action: @selector(hitOpenAbout:) keyEquivalent: @""];
	[menuItem setTarget: self];

	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"Open SoundSource at Login" action: @selector(hitOpenAtLogin:) keyEquivalent: @""];
	[menuItem setState: [_prefs openAtLogin]];
	[menuItem setTarget: self];

	[menu addItem: [NSMenuItem separatorItem]];
	menuItem = (NSMenuItem*)[menu addItemWithTitle: @"Quit SoundSource" action: @selector(terminate:) keyEquivalent: @""];
	[menuItem setTarget: [NSApplication sharedApplication]];
}



@end

int main(int argc, char *argv[])
{
    return NSApplicationMain(argc,  (const char **) argv);
}
