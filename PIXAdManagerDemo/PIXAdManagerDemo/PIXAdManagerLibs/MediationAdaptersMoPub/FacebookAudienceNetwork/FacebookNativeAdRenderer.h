//
//  FacebookNativeAdRenderer.h
//  MoPubSDK
//
//  Copyright © 2019 MoPub. All rights reserved.
//

#import <Foundation/Foundation.h>

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDK/MoPub.h>)
#import <MoPubSDK/MoPub.h>
#else
#import "MPNativeAdRenderer.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@class MPNativeAdRendererConfiguration;
@class MPStaticNativeAdRendererSettings;

@interface FacebookNativeAdRenderer : NSObject <MPNativeAdRenderer>

@property (nonatomic, readonly) MPNativeViewSizeHandler viewSizeHandler;

+ (MPNativeAdRendererConfiguration *)rendererConfigurationWithRendererSettings:(id<MPNativeAdRendererSettings>)rendererSettings;

@end

NS_ASSUME_NONNULL_END
