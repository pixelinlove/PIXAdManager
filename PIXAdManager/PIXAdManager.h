//
//  PIXAdManager.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    AdManagerAdapterNone = 0,
    AdManagerAdapterMoPub, // MoPub is no longer available. Adapters are no longer available.
    AdManagerAdapterAdMob,
    AdManagerAdapterAppLovin
} AdManagerAdapter;


@class PIXAdManager;

// PIXAdManagerDelegate declaration
@protocol PIXAdManagerDelegate <NSObject>

@required

- (UIViewController *)viewControllerForAdManager;

@optional

- (void)adManagerDidLoadAd;
- (void)adManagerDidFailToLoadAd;
- (void)adManagerDidFailToLoadAdWithError:(NSError *)error;
- (void)adManagerDidPauseAd;

@end

// PIXAdManager singleton class definition
@interface PIXAdManager : NSObject

@property (nonatomic, strong, readonly) UIView *adView;
@property (nonatomic, copy, readonly) NSString *adapterName;
@property (nonatomic, weak) id<PIXAdManagerDelegate> delegate;

+ (PIXAdManager *)sharedManager;

/**
 Initializes the selected mediation adapter.

 Important: adapter initialization may start third-party ad SDKs. When your app uses a consent flow,
 call this only after consent has completed and ad requests are allowed. For PIXConsentManager-based
 integrations, that means waiting for startConsentFlowIfNeeded:fromPresentingViewController:completion:
 to complete and checking canRequestAds before initializing or loading ads.
 */
- (void)initializeWithMediationAdapter:(AdManagerAdapter)adapter andConfiguration:(NSDictionary *)configuration;
- (void)applicationNotificationsEnabled:(BOOL)enabled;

- (void)adViewSetupSize;

- (void)loadAd;
- (void)pauseAd;

- (void)debugEnabledWithConfiguration:(NSDictionary *)configuration;

@end
