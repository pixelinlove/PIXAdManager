//
//  PIXAdManagerAdapterAdMob.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 10/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapter.h"
@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface PIXAdManagerAdapterAdMob : NSObject <PIXAdManagerAdapter, GADBannerViewDelegate>

@property (nonatomic, copy, readonly) NSString *adapterName;
@property (nonatomic, weak) id<PIXAdManagerAdapterDelegate> adapterDelegate;
@property (nonatomic, strong, readonly) UIView *adapterAdView;

@end

NS_ASSUME_NONNULL_END
