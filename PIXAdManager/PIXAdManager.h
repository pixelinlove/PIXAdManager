//
//  PIXAdManager.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PIXAdManagerAdapter.h"

typedef enum {
    MediationAdapterNone = 0,
    MediationAdapterMoPub,
    MediationAdapterAdMob
} MediationAdapter;


@class PIXAdManager;

// PIXAdManagerDelegate declaration
@protocol PIXAdManagerDelegate <NSObject>

@required

- (UIViewController *)viewControllerForAdManager;

@optional

- (void)adManagerDidLoadAd:(UIView *)adView;
- (void)adManagerDidFailWithError:(NSError *)error;
- (void)adManagerDidPauseAd;

@end

// PIXAdManager singleton class definition
@interface PIXAdManager : NSObject <PIXAdManagerAdapterDelegate>

@property (nonatomic, strong) UIView *adView;
@property (nonatomic, copy) NSString *mediationClass;
@property (nonatomic, weak) id<PIXAdManagerDelegate> delegate;

+ (PIXAdManager *)sharedManager;

- (void)initializeWithMediationAdapter:(MediationAdapter)adapter andConfiguration:(NSDictionary *)configuration;
- (void)applicationNotificationsEnabled:(BOOL)enabled;

- (void)adViewSetupSize;

- (void)loadAd;
- (void)pauseAd;

@end
