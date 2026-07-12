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
    #if __has_include(<GoogleMobileAds/GoogleMobileAds.h>)
        @import GoogleMobileAds;
        #define HAS_INCLUDE_ADMOB
    #endif
    #if __has_include(<FBAudienceNetwork/FBAdSettings.h>)
        #import <FBAudienceNetwork/FBAdSettings.h>
        #define HAS_INCLUDE_FACEBOOK
    #endif
    #if __has_include(<DTBiOSSDK/DTBiOSSDK.h>)
        #import <DTBiOSSDK/DTBiOSSDK.h>
        #define HAS_INCLUDE_AMAZONAPS
    #endif
#endif


@interface PIXAdManager ()

@property (nonatomic, strong) id<PIXAdManagerAdapter> adapter;

- (BOOL)isConfigurationValid:(NSDictionary *)configuration forAdapter:(AdManagerAdapter)adapter;

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
    NSString *adapterName = @"None";
    if (self.adapter) {
        adapterName = self.adapter.name;
    }
    return adapterName;
}

- (BOOL)isConfigurationValid:(NSDictionary *)configuration forAdapter:(AdManagerAdapter)adapter {
    if (![configuration isKindOfClass:[NSDictionary class]]) {
        NSLog(@"[AdManager] > *** WARNING *** > Adapter configuration is missing or invalid");
        return NO;
    }

    NSArray<NSString *> *requiredKeys = @[];
    switch (adapter) {
        case AdManagerAdapterAdMob:
            requiredKeys = @[kAdManagerConfigurationAdUnitKey];
            break;
        case AdManagerAdapterAppLovin:
            requiredKeys = @[kAdManagerConfigurationSDKKeyKey, kAdManagerConfigurationAdUnitKey];
            break;
        default:
            return NO;
    }

    for (NSString *key in requiredKeys) {
        id value = configuration[key];
        if (![value isKindOfClass:[NSString class]] ||
            [[(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0) {
            NSLog(@"[AdManager] > *** WARNING *** > Missing or invalid configuration value: %@", key);
            return NO;
        }
    }

    return YES;
}

- (void)initializeWithMediationAdapter:(AdManagerAdapter)adapter andConfiguration:(NSDictionary *)configuration {
    NSString *className = [self classNameForAdapter:adapter];
    if (className == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > No class available for this adapter");
        return;
    }
    Class adapterClass = NSClassFromString(className);
    if (adapterClass == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > Can't find required adapter file: %@.h", className);
        return;
    }

    if (![self isConfigurationValid:configuration forAdapter:adapter]) {
        return;
    }

    if ([self.adapter isKindOfClass:adapterClass]) {
        NSLog(@"[AdManager] > Adapter already initialized: %@", self.adapter.name);
        return;
    }

    if (self.adapter) {
        NSLog(@"[AdManager] > Switching adapter from %@ to %@", self.adapter.name, className);
        [self.adapter adapterViewStopAd];
        self.adapter.delegate = nil;
        [self.adapter.adView removeFromSuperview];
    }

    id<PIXAdManagerAdapter> newAdapter = (id<PIXAdManagerAdapter>)[[adapterClass alloc] init];
    self.adapter = newAdapter;
    newAdapter.delegate = self;

    [newAdapter initWithConfiguration:configuration];
    [newAdapter adapterViewInit];
}

- (NSString *)classNameForAdapter:(AdManagerAdapter)adapter {
    NSString *className = nil;
    switch (adapter) {
        case AdManagerAdapterAdMob:
            className = @"PIXAdManagerAdapterAdMob";
            break;
        case AdManagerAdapterAppLovin:
            className = @"PIXAdManagerAdapterAppLovin";
            break;
        default:
            NSLog(@"[AdManager] > *** WARNING *** > This adapter does not exist");
            break;
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
    if ([self.delegate respondsToSelector:@selector(adManagerDidPauseAd)]) {
        [self.delegate adManagerDidPauseAd];
    }
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

- (void)adapterDidLoadAd {
    if ([self.delegate respondsToSelector:@selector(adManagerDidLoadAd)]) {
        [self.delegate adManagerDidLoadAd];
    }
}

- (void)adapterDidFailToLoadAd {
    if ([self.delegate respondsToSelector:@selector(adManagerDidFailToLoadAd)]) {
        [self.delegate adManagerDidFailToLoadAd];
    }
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
    
    // AdMob debug options
    #ifdef HAS_INCLUDE_ADMOB
    if ([GADMobileAds class] && [testDevices objectForKey:@"admob"]) {
        GADMobileAds *ads = [GADMobileAds sharedInstance];
        [ads requestConfiguration].testDeviceIdentifiers = [testDevices objectForKey:@"admob"];
    }
    #endif
    
    // Facebook Audience Network debug options
    #ifdef HAS_INCLUDE_FACEBOOK
    if ([FBAdSettings class] && [testDevices objectForKey:@"facebook"]) {
        // [FBAdSettings clearTestDevices];
        [FBAdSettings addTestDevices:[testDevices objectForKey:@"facebook"]];
    }
    #endif

    #ifdef HAS_INCLUDE_AMAZONAPS
        [[DTBAds sharedInstance] setLogLevel:DTBLogLevelAll];
        [[DTBAds sharedInstance] setTestMode:YES];
    #endif

#endif
    
    [self.adapter adapterViewDebug];
}

@end
