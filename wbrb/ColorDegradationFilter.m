//
//  ColorDegradationFilter.m
//  wbrb
//
//  Created by Jean THOMAS on 06/09/2020.
//  Copyright © 2020 Jean THOMAS. All rights reserved.
//

#import "ColorDegradationFilter.h"

@implementation ColorDegradationFilter

static CIKernel *colorDegradationKernel = nil;

-(id)init
{
    if (colorDegradationKernel == nil)
    {
        NSBundle *bundle = [NSBundle bundleForClass: [self class]];
        NSString *code = [NSString stringWithContentsOfFile:[bundle pathForResource:@"ColorDegradation" ofType:@"cikernel"]];
        NSArray *kernels = [CIKernel kernelsWithString:code];
        colorDegradationKernel = kernels[0];
    }
    
    return [super init];
}

-(CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage: inputImage];
    return [self apply: colorDegradationKernel, src, kCIApplyOptionDefinition, [src definition], nil];
}

+ (void)initialize
{
    [CIFilter registerFilterName: @"ColorDegradation"
                     constructor: self
                 classAttributes:
     @{kCIAttributeFilterDisplayName : @"Color Degradation",
       kCIAttributeFilterCategories : @[
               kCICategoryColorAdjustment, kCICategoryVideo,
               kCICategoryStillImage, kCICategoryInterlaced,
               kCICategoryNonSquarePixels]}
     ];
}

+ (CIFilter *)filterWithName: (NSString *)name
{
    CIFilter  *filter;
    filter = [[self alloc] init];
    return filter;
}

@end
