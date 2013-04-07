//
//  SSLegacy.m
//  SoundSource
//
//  Created by Quentin Carnicelli on 8/27/09.
//  Copyright 2009 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "SSLegacy.h"


@implementation SSLegacy

+ (BOOL)uninstallMenuExtra
{
	NSString* prefsPath;
	NSData* data;
	NSPropertyListFormat format;
	NSString* error;
	NSDictionary* suisDefaults;
	NSMutableArray* menuExtraList;
	BOOL matched;
	
	//Load SUIS prefs file
	prefsPath = [@"~/Library/Preferences/com.apple.systemuiserver.plist" stringByExpandingTildeInPath];
	
	data = [NSData dataWithContentsOfFile: prefsPath];
	if( !data )
		return NO;
	
	suisDefaults = [NSPropertyListSerialization propertyListFromData: data
						mutabilityOption: NSPropertyListMutableContainers format: &format errorDescription: &error];
	if( ![suisDefaults isKindOfClass: [NSDictionary class]] )
		return NO;
	
	//Find the list of loaded menu extras
	menuExtraList = [suisDefaults objectForKey: @"menuExtras"];
	if( ![menuExtraList isKindOfClass: [NSMutableArray class]] )
		return NO;
	
	matched = NO;
	for( id entry in [[menuExtraList copy] autorelease] )
	{
		if( [entry isKindOfClass: [NSString class]] )
		{
			if( [[entry lastPathComponent] isEqual: @"SoundSource.menu"] ) //If this is a SoundSource instance
			{
				[menuExtraList removeObject: entry]; //Remove it
				matched = YES;
			}
		}
	}

	if( !matched )
		return NO;
	
	data = [NSPropertyListSerialization dataFromPropertyList: suisDefaults format: format errorDescription: &error];
	if( data )
		[data writeToFile: prefsPath atomically: YES];
	
	[NSTask launchedTaskWithLaunchPath: @"/usr/bin/killall" arguments: [NSArray arrayWithObject: @"SystemUIServer"]];

	return YES;

}

@end
