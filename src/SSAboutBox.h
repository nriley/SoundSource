//
//  SSAboutBox.h
//  SoundSource
//
//  Created by Quentin Carnicelli on 1/4/05.
//  Copyright 2005 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SSAboutBox : NSWindowController
{
	IBOutlet NSTextView*	mReadMeText;
}

+ (SSAboutBox*)sharedAboutBox;

@end
