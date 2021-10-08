//
//  PIXAdManager.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManager.h"
#import "PIXAdManagerAdapter.h"

#if DEBUG
    // Import Libraries and SDK necessary to setup DEBUG Mode
    #import <AdSupport/ASIdentifierManager.h>
    #if __has_include(<MoPubSDK/MoPub.h>)
        #import <MoPubSDK/MoPub.h>
    #endif
    #if __has_include(<GoogleMobileAds/GoogleMobileAds.h>)
        @import GoogleMobileAds;
    #endif
    #if __has_include(<FBAudienceNetwork/FBAdSettings.h>)
        #import <FBAudienceNetwork/FBAdSettings.h>
    #endif
#endif


@interface PIXAdManager ()

@property (nonatomic, strong) id<PIXAdManagerAdapter> adapter;

@end

@implementation PIXAdManager

+ (PIXAdManager *)sharedManager {
    static PIXAdManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (NSString *)adapterName {
    return self.adapter.name;
}

- (void)initializeWithMediationAdapter:(AdManagerAdapter)adapter andConfiguration:(NSDictionary *)configuration {
//    if (_initialisedMediationAdapter != 0) {
//        //TODO: Raise error. Mediation Adapter already initialised and can't be changed.
//        [NSException raise:NSInternalInconsistencyException
//                    format:@"PIXAdManager can be initialised only once"];
//        return;
//    }

    Class adapterClass = NSClassFromString([self classNameForAdapter:adapter]);
    if (adapterClass == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > Can't find required adapter class");
        return;
    }
    self.adapter = (id<PIXAdManagerAdapter>)[[adapterClass alloc] init];
    self.adapter.delegate = self;
    
    [self.adapter initWithConfiguration:configuration];
    [self.adapter adapterViewInit];
    
}

- (NSString *)classNameForAdapter:(AdManagerAdapter)adapter {
    NSString *className = nil;
    if (adapter == AdManagerAdapterMoPub) {
        className = @"PIXAdManagerAdapterMoPub";
    }
    if (adapter == AdManagerAdapterAdMob) {
        className = @"PIXAdManagerAdapterAdMob";
    }
    return className;
}

- (UIView *)adView {
    return (UIView *)self.adapter.adView;
}

- (void)adViewSetupSize {
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    [self.adapter adapterViewAdjustSize];
}

- (void)loadAd {
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    
    UIView *adView = self.adapter.adView;
    if (adView.superview == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > AdView needs to be attached to the superView before loading an ad");
    }
    
    [self.adapter adapterViewLoadAd];
}

- (void)pauseAd {
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    [self.adapter adapterViewStopAd];
    [self.delegate adManagerDidPauseAd];
}

#pragma mark - Application notifications handling

- (void)applicationNotificationsEnabled:(BOOL)enabled {
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (enabled) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationNotificationForAdManager:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationNotificationForAdManager:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationNotificationForAdManager:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
}

- (void)applicationNotificationForAdManager:(NSNotification *)notification {
    if (notification.name == UIApplicationDidBecomeActiveNotification) {
        NSLog(@"[AdManager] > Application Did Become Active - Banner will refresh");
        [self loadAd];
    }
    
    if (notification.name == UIApplicationWillResignActiveNotification) {
        NSLog(@"[AdManager] > Application Will Resign Active - Banner will hide");
        [self pauseAd];
    }
}

#pragma mark - Adapter delegate calls

- (void)adapterDidLoadAd:(nonnull UIView *)ad {
    [self.delegate adManagerDidLoadAd:ad];
}

- (void)adapterDidFailToLoadAdWithError:(nullable NSError *)error {
    [self.delegate adManagerDidFailWithError:error];
}

- (UIViewController *)viewControllerForAdapter {
    return [self.delegate viewControllerForAdManager];
}

#pragma mark - Debugging

- (void)debugEnabledWithConfiguration:(NSDictionary *)configuration {
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    NSLog(@"[AdManager] > *** WARNING *** > Debug mode enabled");

#if DEBUG
    NSLog(@"[AdManager] > IDFA: %@", [ASIdentifierManager sharedManager].advertisingIdentifier);
    
    NSDictionary *testDevices = [configuration objectForKey:@"testDevices"];
    
    // MoPub debug options
    
    // AdMob debug options
    if ([GADMobileAds class] && [testDevices objectForKey:@"admob"]) {
        GADMobileAds *ads = [GADMobileAds sharedInstance];
        [ads requestConfiguration].testDeviceIdentifiers = [testDevices objectForKey:@"admob"];
    }
    
    // Facebook Audience Network debug options
    if ([FBAdSettings class] && [testDevices objectForKey:@"facebook"]) {
        // [FBAdSettings clearTestDevices];
        [FBAdSettings addTestDevices:[testDevices objectForKey:@"facebook"]];
    }
#endif
    
    [self.adapter adapterViewDebug];
}

@end
