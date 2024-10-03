//
//  PIXAdManagerAdapter.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const kAdManagerConfigurationSDKKey = @"sdkKey";
static NSString *const kAdManagerConfigurationAdUnitKey = @"adUnitID";
static NSString *const kAdManagerConfigurationAdSizeKey = @"adSize";
static NSString *const kAdManagerConfigurationFBTrackingEnabledKey = @"FBTrackingEnabled";
static NSString *const kAdManagerConfigurationAmazonAPSAppKey = @"amazonAPSApp";
static NSString *const kAdManagerConfigurationAmazonAPSSlotIDKey = @"amazonAPSSlotID";

@protocol PIXAdManagerAdapterDelegate <NSObject>

@required
- (UIViewController *)viewControllerForAdapter;

@optional
- (void)adapterDidLoadAd;
- (void)adapterDidFailToLoadAd;

@end

@protocol PIXAdManagerAdapter <NSObject>

@required

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) UIView *adView;
@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, weak) id<PIXAdManagerAdapterDelegate> delegate;

- (void)initWithConfiguration:(NSDictionary *)configuration;
- (void)adapterViewInit;
- (void)adapterViewAdjustSize;
- (void)adapterViewLoadAd;
- (void)adapterViewStopAd;
- (void)adapterViewDebug;

@end

NS_ASSUME_NONNULL_END
