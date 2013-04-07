//
//  SSPreferences.h
//  SoundSource
//
//  Created by Quentin Carnicelli on 8/12/07.
//  Copyright 2007 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SSPreferences : NSObject
{
	LSSharedFileListRef	_loginItemsSharedList;

	int					_opensAtLogin;
}

- (void)setAudioFollowsJack: (BOOL)flag;
- (BOOL)audioFollowsJack;

- (void)setOpenAtLogin: (BOOL)flag;
- (BOOL)openAtLogin;

@end
