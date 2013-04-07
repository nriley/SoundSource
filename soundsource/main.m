//
//  main.m
//  soundsource
//
//  Created by Nicholas Riley on 3/20/13.
//
//

#import <Foundation/Foundation.h>
#import "SSAudioDeviceCenter.h"

static void printAudioDevices(NSArray *audioDevices, SSAudioDevice *selected) {
    audioDevices = [audioDevices sortedArrayUsingSelector: @selector(compare:)];
    for (SSAudioDevice *device in audioDevices) {
        printf("%c %s\n", [device isEqual:selected] ? '*' : ' ', [[device name] UTF8String]);
    }
}

static void printAudioDevice(SSAudioDevice *device) {
    puts([[device name] UTF8String]);
}

static NSString *trimWhitespace(NSString *deviceName) {
    // There's extra whitespace padding after some device names.  Compensate for it.
    return [deviceName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static SSAudioDevice *audioDeviceWithName(NSArray *audioDevices, NSString *name) {
    for (SSAudioDevice *device in audioDevices) {
        if ([name compare:trimWhitespace([device name]) options:NSCaseInsensitiveSearch] == NSOrderedSame)
            return device;
    }
    return nil;
}

int main(int argc, const char * argv[]) {

    @autoreleasepool {
        SSAudioDeviceCenter *deviceCenter = [[SSAudioDeviceCenter alloc] init];

        if (argc < 2) {
            printf("Output (volume %.1f):\n", [deviceCenter outputVolume]);
            printAudioDevices([deviceCenter outputDevices],
                              [deviceCenter selectedOutputDevice]);
            printf("Input (volume %.1f):\n", [deviceCenter inputVolume]);
            printAudioDevices([deviceCenter inputDevices],
                              [deviceCenter selectedInputDevice]);
            printf("System (volume %.1f):\n", [deviceCenter systemVolume]);
            printAudioDevices([NSArray arrayWithObject:[deviceCenter selectedSystemDevice]],
                              [deviceCenter selectedSystemDevice]);
            return 0;
        }
        if (argc > 3 || strlen(argv[1]) != 2 || argv[1][0] != '-') {
            // XXX
            return 1;
        }

        char option = argv[1][1];
        SSAudioDevice *device = nil;

        if (argc == 2) {
            switch (option) {
                case 'i': device = [deviceCenter selectedInputDevice]; break;
                case 'o': device = [deviceCenter selectedOutputDevice]; break;
                case 's': device = [deviceCenter selectedSystemDevice]; break;
            }
            if (device == nil) {
                // XXX
                return 1;
            }
            puts([[device name] UTF8String]);
            return 0;
        }

        NSString *deviceName = trimWhitespace([[NSString alloc] initWithUTF8String:argv[2]]);
        device = audioDeviceWithName(
                option == 'i' ? [deviceCenter inputDevices] : [deviceCenter outputDevices], deviceName);
        [deviceName release];
        if (device == nil) {
            // XXX
            return 1;
        }
        switch (option) {
            case 'i': [deviceCenter setSelectedInputDevice:device]; break;
            case 'o': [deviceCenter setSelectedOutputDevice:device]; break;
            case 's': [deviceCenter setSelectedSystemDevice:device]; break;
            default:
                return 1; // XXX
        }
    }
    return 0;
}