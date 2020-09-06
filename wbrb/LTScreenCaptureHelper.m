/**
 * Tae Won Ha
 * http://qvacua.com
 * https://github.com/qvacua
 *
 * See LICENSE
 */

#import <AppKit/AppKit.h>
#import "LTScreenCaptureHelper.h"


/**
 * The most of this class consists of
 * https://developer.apple.com/library/mac/#samplecode/SonOfGrab/Listings/Controller_m.html
 */

NSString *kAppNameKey = @"applicationName"; // Application Name & PID
NSString *kWindowOriginKey = @"windowOrigin";   // Window Origin as a string
NSString *kWindowSizeKey = @"windowSize";       // Window Size as a string
NSString *kWindowIDKey = @"windowID";           // Window ID
NSString *kWindowLevelKey = @"windowLevel"; // Window Level
NSString *kWindowOrderKey = @"windowOrder"; // The overall front-to-back ordering of the windows as returned by the window server

static inline uint32_t ChangeBits(uint32_t currentBits, uint32_t flagsToChange, BOOL setFlags) {
    if (setFlags) {    // Set Bits
        return currentBits | flagsToChange;
    } else {    // Clear Bits
        return currentBits & ~flagsToChange;
    }
}

static NSString *const qLoginWindowAppName = @"loginwindow";
static NSString *const qScreenSaverAppName = @"ScreenSaverEngine";

@implementation LTScreenCaptureHelper {
    CGRect imageBounds;
    CGWindowImageOption imageOptions;
    
    CGWindowListOption listOptions;
    CGWindowListOption singleWindowListOptions;
    
    NSMutableArray *windowArray;
}


- (id)init {
    self = [super init];
    if (self) {
        imageBounds = CGRectInfinite;
        imageOptions = kCGWindowImageDefault;
        
        listOptions = ChangeBits(listOptions, kCGWindowListExcludeDesktopElements, NO);
        listOptions = ChangeBits(listOptions, kCGWindowListOptionOnScreenOnly, YES);
        singleWindowListOptions = kCGWindowListOptionOnScreenBelowWindow;
        
        windowArray = [[NSMutableArray alloc] initWithCapacity:6];
    }
    
    return self;
}

- (NSImage *)screenAsImage {
    // Ask the window server for the list of windows.
    CFArrayRef windowListRef = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);
    NSArray *windowList = (__bridge NSArray*)windowListRef;
    
    // Copy the returned list, further pruned, to another list. This also adds some bookkeeping
    // information to the list as well as
    [windowArray removeAllObjects];
    int order = 0;
    for (id window in windowList) {
        // The flags that we pass to CGWindowListCopyWindowInfo will automatically filter out most undesirable windows.
        // However, it is possible that we will get back a window that we cannot read from, so we'll filter those out manually.
        int sharingState = [window[(id) kCGWindowSharingState] intValue];
        if (sharingState != kCGWindowSharingNone) {
            NSMutableDictionary *outputEntry = [NSMutableDictionary dictionary];
            
            // Grab the application name, but since it's optional we need to check before we can use it.
            NSString *applicationName = window[(id) kCGWindowOwnerName];
            if (applicationName != NULL) {
                // PID is required so we assume it's present.
                NSString *nameAndPID = [NSString stringWithFormat:@"%@ (%@)", applicationName, window[(id) kCGWindowOwnerPID]];
                outputEntry[kAppNameKey] = nameAndPID;
            } else {
                // The application name was not provided, so we use a fake application name to designate this.
                // PID is required so we assume it's present.
                NSString *nameAndPID = [NSString stringWithFormat:@"((unknown)) (%@)", window[(id) kCGWindowOwnerPID]];
                outputEntry[kAppNameKey] = nameAndPID;
            }
            
            // Grab the Window Bounds, it's a dictionary in the array, but we want to display it as a string
            CGRect bounds;
            CGRectMakeWithDictionaryRepresentation((CFDictionaryRef) window[(id) kCGWindowBounds], &bounds);
            NSString *originString = [NSString stringWithFormat:@"%.0f/%.0f", bounds.origin.x, bounds.origin.y];
            outputEntry[kWindowOriginKey] = originString;
            NSString *sizeString = [NSString stringWithFormat:@"%.0f*%.0f", bounds.size.width, bounds.size.height];
            outputEntry[kWindowSizeKey] = sizeString;
            
            // Grab the Window ID & Window Level. Both are required, so just copy from one to the other
            outputEntry[kWindowIDKey] = window[(id) kCGWindowNumber];
            outputEntry[kWindowLevelKey] = window[(id) kCGWindowLayer];
            
            // Finally, we are passed the windows in order from front to back by the window server
            // Should the user sort the window list we want to retain that order so that screen shots
            // look correct no matter what selection they make, or what order the items are in. We do this
            // by maintaining a window order key that we'll apply later.
            outputEntry[kWindowOrderKey] = @(order);
            order++;
            
            [windowArray addObject:outputEntry];
        }
    }
    CFRelease(windowListRef);
    
    __block CGWindowID bottomIrrelevantWindowId = 0;
    __block NSInteger maxWindowLevel = -1;
    __block NSInteger maxWindowOrder = -1;
    
    [windowArray enumerateObjectsUsingBlock:^(NSDictionary *windowInfo, NSUInteger index, BOOL *stop) {
        NSString *appName = windowInfo[kAppNameKey];
        NSInteger windowLevel = [windowInfo[kWindowLevelKey] integerValue];
        NSInteger windowOrder = [windowInfo[kWindowOrderKey] integerValue];
        
        NSRange loginWindowNameRange = [appName rangeOfString:qLoginWindowAppName];
        NSRange screenSaverNameRange = [appName rangeOfString:qScreenSaverAppName];
        
        if (loginWindowNameRange.location == NSNotFound && screenSaverNameRange.location == NSNotFound) {
            return;
        }
        
        if (windowLevel > maxWindowLevel || windowOrder > maxWindowOrder) {
            maxWindowLevel = windowLevel;
            bottomIrrelevantWindowId = (CGWindowID) [windowInfo[kWindowIDKey] intValue];
        }
    }];
    
    return [self everythingBelowImage:bottomIrrelevantWindowId];
}

- (NSImage *)everythingBelowImage:(CGWindowID)windowID {
    // Create an image from the passed in windowID with the single window option selected by the user.
    CGImageRef windowImage = CGWindowListCreateImage(imageBounds, singleWindowListOptions, windowID, imageOptions);
    NSImage *image = [self imageFromCGImageRef:windowImage];
    CGImageRelease(windowImage);
    
    return image;
}

- (NSImage *)imageFromCGImageRef:(CGImageRef)image {
    NSRect imageRect = NSMakeRect(0.0, 0.0, 0.0, 0.0);
    CGContextRef imageContext = nil;
    NSImage* newImage = nil; // Get the image dimensions.
    imageRect.size.height = CGImageGetHeight(image);
    imageRect.size.width = CGImageGetWidth(image);
    
    // Create a new image to receive the Quartz image data.
    newImage = [[NSImage alloc] initWithSize:imageRect.size];
    [newImage lockFocus];
    
    // Get the Quartz context and draw.
    imageContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    CGContextDrawImage(imageContext, *(CGRect*)&imageRect, image); [newImage unlockFocus];
    return newImage;
}

@end
