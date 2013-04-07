//
//  SSPreferences.m
//  SoundSource
//
//  Created by Quentin Carnicelli on 8/12/07.
//  Copyright 2007 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "SSPreferences.h"

@implementation SSPreferences

- (void)_invalideOpensAtLoginCache
{
	_opensAtLogin = -1;
}

static void _loginItemsDidChange(LSSharedFileListRef inList, void *context)
{
	SSPreferences* prefs = (SSPreferences*)context;
	[prefs _invalideOpensAtLoginCache];
}

- (id)init
{
	if( (self = [super init]) != nil )
	{
		_loginItemsSharedList = LSSharedFileListCreate( NULL, kLSSharedFileListSessionLoginItems, 0 );
		LSSharedFileListAddObserver( _loginItemsSharedList, CFRunLoopGetMain(), kCFRunLoopCommonModes, _loginItemsDidChange, self ); 
		[self _invalideOpensAtLoginCache];
	}
	
	return self;
}

- (void)dealloc
{
	if( _loginItemsSharedList )
	{
		LSSharedFileListRemoveObserver( _loginItemsSharedList, CFRunLoopGetMain(), kCFRunLoopCommonModes, _loginItemsDidChange, self );
	
		CFRelease( _loginItemsSharedList );
		_loginItemsSharedList = nil;
	}

	[super dealloc];
}

- (NSString*)_bundleID
{
	return [[NSBundle bundleForClass: [self class]] bundleIdentifier];
}

- (void)_storeValue: (id)val forKey: (NSString*)key
{
	NSDictionary* defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName: [self _bundleID]];
	NSMutableDictionary* newDefaults = [defaults mutableCopy];
	
	if( newDefaults == nil )
		newDefaults = [NSMutableDictionary dictionary];
	
	[newDefaults setObject: val forKey: key];
	[[NSUserDefaults standardUserDefaults] setPersistentDomain: newDefaults forName: [self _bundleID]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)_loadValueForKey: (NSString*)key
{
	NSDictionary* defaults = [[NSUserDefaults standardUserDefaults] persistentDomainForName: [self _bundleID]];
	return [defaults objectForKey: key];
}

- (void)setAudioFollowsJack: (BOOL)flag
{
	[self _storeValue: [NSNumber numberWithBool: flag] forKey: @"audioFollowsJack"];
}

- (BOOL)audioFollowsJack
{
	return [[self _loadValueForKey: @"audioFollowsJack"] boolValue];
}


#pragma mark -

- (LSSharedFileListItemRef)_copySharedFileListItemForBundle
{
	CFArrayRef loginItems;
	UInt32 seed;
	NSURL* ourURL;
	LSSharedFileListItemRef foundItem;

	if( !_loginItemsSharedList )
		return nil;

	loginItems = LSSharedFileListCopySnapshot( _loginItemsSharedList, &seed );
	if( !loginItems )
		return nil;

	ourURL = [(NSURL*)CFBundleCopyBundleURL( CFBundleGetMainBundle() ) autorelease];
	
	foundItem = nil;

	for( id item in (NSArray*)loginItems )
	{
		OSStatus err;
		CFURLRef url;
		
		err = LSSharedFileListItemResolve( (LSSharedFileListItemRef)item, kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes, &url, NULL );
		if( err || !url )
			continue;
		
		if( [(NSURL*)url isEqual: ourURL] )
		{
			foundItem = (LSSharedFileListItemRef)CFRetain(item);
			CFRelease( url );
			break;
		}
		else
		{
			CFRelease( url );
		}
	}
	
	CFRelease( loginItems );
	
	return foundItem;
}

- (void)setOpenAtLogin: (BOOL)flag
{
		LSSharedFileListItemRef item;

	if( !_loginItemsSharedList )
		return;
		
	if( flag == [self openAtLogin] )
		return;
	
	if( flag ) //Adding
	{
		NSDictionary* properties;
		
		properties = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool:YES] forKey:@"com.apple.loginitem.HideOnLaunch"];
		
		item = LSSharedFileListInsertItemURL(	_loginItemsSharedList,
												kLSSharedFileListItemLast,
												NULL,
												NULL,
												(CFURLRef)[(NSURL*)CFBundleCopyBundleURL( CFBundleGetMainBundle() ) autorelease],
												(CFDictionaryRef)properties,
												NULL );
												
		if( item )
			CFRelease( item );
	}
	else //Removing
	{
		item = [self _copySharedFileListItemForBundle];

		LSSharedFileListItemRemove( _loginItemsSharedList, item );

		if( item )
		{
			CFRelease( item );
		}
	}

	[self _invalideOpensAtLoginCache];
}

- (BOOL)openAtLogin
{
	if( _opensAtLogin == -1 )
	{
		LSSharedFileListItemRef item = [self _copySharedFileListItemForBundle];
		
		_opensAtLogin = item ? 1 : 0;
		
		if( item )
			CFRelease(item);
	}
	
	return _opensAtLogin == 1;
}

@end
