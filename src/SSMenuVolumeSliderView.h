//
//  SSMenuVolumeSliderView.h
//  SoundSource
//
//  Created by Michael Ash on 2/25/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


enum
{
	kSSMenuVolumeOutputKind,
	kSSMenuVolumeInputKind,
	kSSMenuVolumeSystemKind
};

@class SSAudioDeviceCenter;

@interface SSMenuVolumeSliderView : NSView
{
	SSAudioDeviceCenter*	_deviceCenter;
	int						_kind;
	NSString*				_label;
	NSSliderCell*			_sliderCell;
}

- (id)initWithFrame: (NSRect)frame deviceCenter: (SSAudioDeviceCenter *)deviceCenter;
- (void)setKind: (int)kind;

@end
