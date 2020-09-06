//
//  wbrbView.m
//  wbrb
//
//  Created by Jean THOMAS on 06/09/2020.
//  Copyright © 2020 Jean THOMAS. All rights reserved.
//

#import "wbrbView.h"
#import "LTScreenCaptureHelper.h"
#import "ColorDegradationFilter.h"

@implementation wbrbView {
    NSImage *finalRender;
}

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (self) {
        [self setAnimationTimeInterval:1];
    }
    
    LTScreenCaptureHelper *captureHelper = [[LTScreenCaptureHelper alloc] init];
    NSImage *screenshot = [captureHelper screenAsImage];
    
    NSData *screenshotData = [screenshot TIFFRepresentation];
    CIImage *ciScreenshot = [CIImage imageWithData:screenshotData];
    CIFilter *degradationFilter = [ColorDegradationFilter filterWithName:@"ColorDegradation"];
    [degradationFilter setValue:ciScreenshot forKey:@"inputImage"];
    CIImage *outputImage = [degradationFilter valueForKey: @"outputImage"];
    NSImage *degradedScreenshot = [[NSImage alloc] initWithSize:[outputImage extent].size];
    NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:outputImage];
    [degradedScreenshot addRepresentation:rep];
    
    finalRender = [[NSImage alloc] initWithSize:[degradedScreenshot size]];
    [finalRender lockFocus];
    CGRect newImageRect = CGRectZero;
    newImageRect.size = [finalRender size];
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSImage *wbrb = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"wbrb" ofType:@"png"]];
    
    [degradedScreenshot drawInRect:newImageRect];
    [wbrb drawAtPoint:NSMakePoint(50,50) fromRect:NSZeroRect operation:NSCompositingOperationSourceOver
             fraction:1];
    
    [finalRender unlockFocus];
    
    return self;
}

- (void)startAnimation
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *jinglePath = [bundle pathForResource:@"jingle" ofType:@"aiff"];
    NSSound *jingle = [[NSSound alloc] initWithContentsOfFile:jinglePath byReference:NO];
    [jingle play];
    [super startAnimation];
}

-(BOOL)isOpaque
{
    return YES;
}

- (void)stopAnimation
{
    [super stopAnimation];
}

- (void)drawRect:(NSRect)rect
{
    NSRect screenRect = self.frame;
    [finalRender drawInRect:screenRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
}

- (void)animateOneFrame
{
    self.needsDisplay = YES;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (NSWindow*)configureSheet
{
    return nil;
}

@end
