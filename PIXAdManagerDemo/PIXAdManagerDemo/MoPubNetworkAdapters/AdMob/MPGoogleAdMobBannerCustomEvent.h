//
//  MPGoogleAdMobBannerCustomEvent.h
//  MoPub
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#if __has_include(<MoPub/MoPub.h>)
#import <MoPub/MoPub.h>
#elif __has_include(<MoPubSDKFramework/MoPub.h>)
#import <MoPubSDKFramework/MoPub.h>
#else
#import "MPInlineAdAdapter.h"
#import "MoPub.h"
#endif

#import "MPGoogleGlobalMediationSettings.h"

@interface MPGoogleAdMobBannerCustomEvent : MPInlineAdAdapter <MPThirdPartyInlineAdAdapter>
+(CGFloat) adWidth;
+(CGFloat) adHeight;

@end
