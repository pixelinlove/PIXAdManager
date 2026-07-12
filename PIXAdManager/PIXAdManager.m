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


@interface PIXAdManager () <PIXAdManagerAdapterDelegate>

@property (nonatomic, strong) id<PIXAdManagerAdapter> adapter;

- (void)assertMainThread;
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

- (void)assertMainThread {
    NSAssert([NSThread isMainThread], @"PIXAdManager UI and SDK operations must run on the main thread");
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
    [self assertMainThread];

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

    if (![adapterClass conformsToProtocol:@protocol(PIXAdManagerAdapter)]) {
        NSLog(@"[AdManager] > *** WARNING *** > Adapter class does not conform to PIXAdManagerAdapter: %@", className);
        return;
    }

    if (![self isConfigurationValid:configuration forAdapter:adapter]) {
        return;
    }

    if ([self.adapter isKindOfClass:adapterClass]) {
        NSLog(@"[AdManager] > Adapter already initialized: %@", self.adapter.name);
        return;
    }

    id<PIXAdManagerAdapter> newAdapter = (id<PIXAdManagerAdapter>)[[adapterClass alloc] init];
    if (newAdapter == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > Unable to create adapter: %@", className);
        return;
    }

    if (self.adapter) {
        NSLog(@"[AdManager] > Switching adapter from %@ to %@", self.adapter.name, className);
        [self.adapter adapterViewStopAd];
        self.adapter.delegate = nil;
        [self.adapter.adView removeFromSuperview];
    }

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
    [self assertMainThread];
    return (UIView *)self.adapter.adView;
}

- (void)adViewSetupSize {
    [self assertMainThread];
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    [self.adapter adapterViewAdjustSize];
}

- (void)loadAd {
    [self assertMainThread];
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));

    if (self.adapter == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > An adapter must be initialized before loading an ad");
        return;
    }

    UIView *adView = self.adapter.adView;
    if (adView == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > The initialized adapter did not provide an ad view");
        return;
    }

    if (adView.superview == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > AdView needs to be attached to the superView before loading an ad");
        return;
    }

    [self.adapter adapterViewLoadAd];
}

- (void)pauseAd {
    [self assertMainThread];
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    [self.adapter adapterViewStopAd];
    if ([self.delegate respondsToSelector:@selector(adManagerDidPauseAd)]) {
        [self.delegate adManagerDidPauseAd];
    }
}

#pragma mark - Application notifications handling

- (void)applicationNotificationsEnabled:(BOOL)enabled {
    [self assertMainThread];
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (enabled) {
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
    [self assertMainThread];

    if ([notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        NSLog(@"[AdManager] > Application Did Become Active - Banner will refresh");
        [self loadAd];
    } else if ([notification.name isEqualToString:UIApplicationWillResignActiveNotification]) {
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

- (void)adapterDidFailToLoadAdWithError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(adManagerDidFailToLoadAdWithError:)]) {
        [self.delegate adManagerDidFailToLoadAdWithError:error];
    } else {
        [self adapterDidFailToLoadAd];
    }
}

- (UIViewController *)viewControllerForAdapter {
    return [self.delegate viewControllerForAdManager];
}

#pragma mark - Debugging

- (void)debugEnabledWithConfiguration:(NSDictionary *)configuration {
#if DEBUG
    [self assertMainThread];
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    NSLog(@"[AdManager] > *** WARNING *** > Debug mode enabled");

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

    [self.adapter adapterViewDebug];
#endif
}

@end
