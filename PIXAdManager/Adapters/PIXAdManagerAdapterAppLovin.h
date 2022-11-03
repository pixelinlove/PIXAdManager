//
//  PIXAdManagerAdapterAppLovin.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 26/12/2021.
//  Copyright © 2021 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapter.h"
#import <AppLovinSDK/AppLovinSDK.h>

#if __has_include(<FBAudienceNetwork/FBAdSettings.h>)
    #import <FBAudienceNetwork/FBAdSettings.h>
    #define HAS_INCLUDE_FBADSETTINGS
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PIXAdManagerAdapterAppLovin : NSObject <PIXAdManagerAdapter, MAAdViewAdDelegate>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong) MAAdView *adView;
@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, weak) id<PIXAdManagerAdapterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
