//
//  main.m
//  soundsource
//
//  Created by Nicholas Riley on 3/20/13.
//
//

#import <Foundation/Foundation.h>
#import "SSAudioDeviceCenter.h"

static void printAudioDevices(char *title, float volume, NSArray *audioDevices, SSAudioDevice *selected) {
    printf("%s ", title);
    if (volume == NAN) {
        printf("(selected device has no volume adjustment)");
    } else {
        printf("(volume %.3f)", volume);
    }
    printf(":\n");

    audioDevices = [audioDevices sortedArrayUsingSelector: @selector(compare:)];
    for (SSAudioDevice *device in audioDevices) {
        printf("%c %s\n", [device isEqual:selected] ? '*' : ' ', [[device name] UTF8String]);
    }
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

void usage(const char *argv0) {
    fprintf(stderr, "usage: %s [-ios] [device]\n", argv0);
    fprintf(stderr, "   or: %s [-IOS] volume\n", argv0);
    fprintf(stderr, "  -i         display selected audio input device\n");
    fprintf(stderr, "  -o         display selected audio output device\n");
    fprintf(stderr, "  -s         display output device used for alert sounds, sound effects\n");
    fprintf(stderr, "  -i device  set selected audio input device\n");
    fprintf(stderr, "  -o device  set selected audio output device\n");
    fprintf(stderr, "  -s device  set output device used for alert sounds, sound effects\n");
    fprintf(stderr, "  -I         display selected audio input device's volume\n");
    fprintf(stderr, "  -O         display selected audio output device's volume\n");
    fprintf(stderr, "  -S         display alert sounds/sound effects volume\n");
    fprintf(stderr, "  -I volume  set selected audio input device's volume\n");
    fprintf(stderr, "  -O volume  set selected audio output device's volume\n");
    fprintf(stderr, "  -S volume  set alert sounds/sound effects volume\n");
    fprintf(stderr, "With no arguments, displays available/selected (*) devices and volumes.\n");
    exit(1);
}

int main(int argc, const char * argv[]) {

    @autoreleasepool {
        SSAudioDeviceCenter *deviceCenter = [[SSAudioDeviceCenter alloc] init];

        if (argc < 2) {
            printAudioDevices("Output", [deviceCenter outputVolume],
                              [deviceCenter outputDevices],
                              [deviceCenter selectedOutputDevice]);
            printAudioDevices("Input", [deviceCenter inputVolume],
                              [deviceCenter inputDevices],
                              [deviceCenter selectedInputDevice]);
            printAudioDevices("System", [deviceCenter systemVolume],
                              [NSArray arrayWithObject:[deviceCenter selectedSystemDevice]],
                              [deviceCenter selectedSystemDevice]);
            return 0;
        }
        if (argc > 3 || strlen(argv[1]) != 2 || argv[1][0] != '-') {
            usage(argv[0]);
        }

        char option = argv[1][1];
        SSAudioDevice *device = nil;
        float volume = NAN;

        if (argc == 2) {
            switch (option) {
                case 'i': device = [deviceCenter selectedInputDevice]; break;
                case 'o': device = [deviceCenter selectedOutputDevice]; break;
                case 's': device = [deviceCenter selectedSystemDevice]; break;
                case 'I': volume = [deviceCenter inputVolume]; break;
                case 'O': volume = [deviceCenter outputVolume]; break;
                case 'S': volume = [deviceCenter systemVolume]; break;
                default:
                    usage(argv[0]);
            }
            if (device == nil) {
                if (volume != NAN) {
                    printf("%.3f\n", volume);
                    return 0;
                }
                fprintf(stderr, "%s: can't get selected information\n", argv[0]);
                return 1;
            }
            puts([[device name] UTF8String]);
            return 0;
        }

        if (option >= 'i') {
            NSString *deviceName = trimWhitespace([[NSString alloc] initWithUTF8String:argv[2]]);
            device = audioDeviceWithName(
                    option == 'i' ? [deviceCenter inputDevices] : [deviceCenter outputDevices], deviceName);
            [deviceName release];
            if (device == nil) {
                fprintf(stderr, "%s: can't set selected audio device\n", argv[0]);
                return 1;
            }
        } else {
            char *end;
            volume = strtof(argv[2], &end);
            if (end == NULL || *end != '\0' || volume < 0 || volume > 1)
                usage(argv[0]);
        }
        switch (option) {
            case 'i': [deviceCenter setSelectedInputDevice:device]; break;
            case 'o': [deviceCenter setSelectedOutputDevice:device]; break;
            case 's': [deviceCenter setSelectedSystemDevice:device]; break;
            case 'I': [deviceCenter setInputVolume:volume]; break;
            case 'O': [deviceCenter setOutputVolume:volume]; break;
            case 'S': [deviceCenter setSystemVolume:volume]; break;
            default:
                usage(argv[0]);
        }
    }
    return 0;
}