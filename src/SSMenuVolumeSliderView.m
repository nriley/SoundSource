//
//  SSMenuVolumeSliderView.m
//  SoundSource
//
//  Created by Michael Ash on 2/25/08.
//  Copyright 2008 Rogue Amoeba Software, LLC. All rights reserved.
//

#import "SSMenuVolumeSliderView.h"

#import "SSAudioDeviceCenter.h"


@interface SSMenuVolumeSliderView (Private)

- (float)_getVolume;
- (void)_setVolume: (float)val;
- (NSRect)_sliderFrame;
- (NSDictionary *)_labelAttributes;
- (NSRect)_labelFrame;

@end


@implementation SSMenuVolumeSliderView

- (id)initWithFrame: (NSRect)frame deviceCenter: (SSAudioDeviceCenter *)deviceCenter
{
    if( (self = [super initWithFrame:frame]) )
	{
		_deviceCenter = deviceCenter;
		_label = @"Volume:";
    }
    return self;
}

- (void)dealloc
{
	[_sliderCell release];
	
	[super dealloc];
}

#pragma mark -

- (void)setKind: (int)kind
{
	_kind = kind;
}

#pragma mark -

- (void)drawRect:(NSRect)rect
{
	if( !_sliderCell )
	{
		_sliderCell = [[NSSliderCell alloc] init];
		[_sliderCell setMinValue: 0.0];
		[_sliderCell setMaxValue: 1.0];
		[_sliderCell setTarget: self];
		[_sliderCell setAction: @selector( _sliderMoved: )];
		[_sliderCell setContinuous: YES];
		
		float curVolume = [self _getVolume];
		if( isnan( curVolume ) )
		{
			[_sliderCell setFloatValue: 1.0];
			[_sliderCell setEnabled: NO];
		}
		else
		{
			[_sliderCell setFloatValue: curVolume];
			[_sliderCell setEnabled: YES];
		}
	}
	
	[_label drawAtPoint: [self _labelFrame].origin withAttributes: [self _labelAttributes]];
	[_sliderCell drawWithFrame: [self _sliderFrame] inView: self];
}

- (BOOL)acceptsFirstMouse: (NSEvent *)theEvent
{
	return YES;
}

- (void)mouseDown: (NSEvent *)event
{
	if( [_sliderCell isEnabled] )
		[_sliderCell trackMouse: event inRect: [self _sliderFrame] ofView: self untilMouseUp: YES];
}

- (void)mouseDragged: (NSEvent *)event
{
	if( ![_sliderCell isEnabled] )
		return;

	NSRect frame = [self _sliderFrame];
	float thickness = [_sliderCell knobThickness];
	
	double minVal = [_sliderCell minValue];
	double maxVal = [_sliderCell maxValue];
	double delta = maxVal - minVal;
	
	double val = [_sliderCell doubleValue];
	double proportion = (val - minVal) / delta;
	
	float minX = NSMinX( frame ) + proportion * (NSWidth( frame ) - thickness);
	
	NSRect knobRect = frame;
	knobRect.origin.x = minX;
	knobRect.size.width = thickness;
	
	NSPoint p = [event locationInWindow];
	p = [[event window] convertBaseToScreen: p];
	p = [[self window] convertScreenToBase: p];
	p = [self convertPoint: p fromView: nil];
	
	if( NSPointInRect( p, knobRect ) )
		[_sliderCell trackMouse: event inRect: frame ofView: self untilMouseUp: NO];
}

@end

@implementation SSMenuVolumeSliderView (Private)

- (float)_getVolume
{
	switch( _kind )
	{
		case kSSMenuVolumeInputKind:
			return [_deviceCenter inputVolume];
		case kSSMenuVolumeOutputKind:
			return [_deviceCenter outputVolume];
		case kSSMenuVolumeSystemKind:
			return [_deviceCenter systemVolume];
		default:
			NSLog( @"Can't get volume from unknown device kind %d", _kind );
			return NAN;
	}
}

- (void)_setVolume: (float)val
{
	switch( _kind )
	{
		case kSSMenuVolumeInputKind:
			[_deviceCenter setInputVolume: val];
			break;
		case kSSMenuVolumeOutputKind:
			[_deviceCenter setOutputVolume: val];
			break;
		case kSSMenuVolumeSystemKind:
			[_deviceCenter setSystemVolume: val];
			break;
		default:
			NSLog( @"Can't set volume from unknown device kind %d", _kind );
			break;
	}
}

- (NSRect)_sliderFrame
{
	const float minXMargin = 5.0;
	const float maxXMargin = 30.0;
	
	NSRect labelFrame = [self _labelFrame];
	NSRect r = [self bounds];
	r.origin.x = NSMaxX( labelFrame ) + minXMargin;
	r.size.width -= r.origin.x + maxXMargin;
	
	return r;
}

- (void)_sliderMoved: (id)sender
{
	[self _setVolume: [_sliderCell floatValue]];
}

- (NSDictionary *)_labelAttributes
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSFont menuFontOfSize: [NSFont systemFontSize] + 1], NSFontAttributeName,
			[NSColor disabledControlTextColor], NSForegroundColorAttributeName,
			nil];
}

- (NSRect)_labelFrame
{
	const float minXMargin = 30.0;
	
	NSRect r = [self bounds];
	r.size = [_label sizeWithAttributes: [self _labelAttributes]];
	r.origin.x = minXMargin;
	r.origin.y = ([self bounds].size.height - r.size.height) / 2.0 + 2;
	
	return r;
}

@end

