//
//  PIXAdManagerAdapterAdMob.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 10/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapter.h"
@import GoogleMobileAds;

#if __has_include(<FBAudienceNetwork/FBAdSettings.h>)
  #import <FBAudienceNetwork/FBAdSettings.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PIXAdManagerAdapterAdMob : NSObject <PIXAdManagerAdapter, GADBannerViewDelegate>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong) GADBannerView *adView;
@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, weak) id<PIXAdManagerAdapterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
