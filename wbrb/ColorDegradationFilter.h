//
//  ColorDegradationFilter.h
//  wbrb
//
//  Created by Jean THOMAS on 06/09/2020.
//  Copyright © 2020 Jean THOMAS. All rights reserved.
//

#import <CoreImage/CoreImage.h>

@interface ColorDegradationFilter : CIFilter
{
    CIImage *inputImage;
}

@end
