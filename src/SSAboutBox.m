//
//  SSAboutBox.m
//  SoundSource
//
//  Created by Quentin Carnicelli on 1/4/05.
//  Copyright 2005 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "SSAboutBox.h"


@implementation SSAboutBox

static SSAboutBox* _sharedAboutBox = nil;

+ (SSAboutBox*)sharedAboutBox
{
	if( _sharedAboutBox == nil )
		_sharedAboutBox = [[self alloc] init];
	return _sharedAboutBox;
}

- (id)init
{
	return [self initWithWindowNibName: @"AboutBox"];
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	[[self window] center];
	
	NSBundle* bundle = [NSBundle bundleForClass: [self class]];
	NSString* path = [bundle pathForResource: @"ReadMe" ofType: @"rtfd"];

	if( path )
		[mReadMeText readRTFDFromFile: path];
}

@end
