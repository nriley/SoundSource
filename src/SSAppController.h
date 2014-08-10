//
//  SSAppController.h
//  SoundSource
//
//  Created by Quentin Carnicelli on 8/24/09.
//  Copyright 2009 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SSPreferences;
@class SSAudioDeviceCenter;

@interface SSAppController : NSObject <NSMenuDelegate>
{
	NSStatusItem*		_statusItem;
	SSPreferences*		_prefs;
	SSAudioDeviceCenter* _deviceCenter;
}

@end
