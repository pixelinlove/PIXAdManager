//
//  PIXAdManagerAdapterAdMob.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 10/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterAdMob.h"
#import "PIXAdManagerAdapter.h"
@import GoogleMobileAds;

#if __has_include(<FBAudienceNetwork/FBAdSettings.h>)
    #import <FBAudienceNetwork/FBAdSettings.h>
    #define HAS_INCLUDE_FBADSETTINGS
#endif

#if __has_include(<DTBiOSSDK/DTBiOSSDK.h>) && __has_include(<APSAdMobUtils.h>)
    #import <DTBiOSSDK/DTBiOSSDK.h>
    #import <APSAdMobUtils.h>
    #define HAS_INCLUDE_AMAZONAPS
#endif

static NSString * const kMediationAdapter = @"AdMob";

@interface PIXAdManagerAdapterAdMob () <PIXAdManagerAdapter, GADBannerViewDelegate>

@property (nonatomic, strong, readwrite) GADBannerView *adView;
@property (nonatomic, assign, readwrite) BOOL isInitialized;
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, assign) BOOL FBTrackingEnabled;
@property (nonatomic, copy) NSString *amazonAPSApp;
@property (nonatomic, copy) NSString *amazonAPSSlotID;
@property (nonatomic, assign) BOOL amazonAPSConfigured;
@property (nonatomic, assign) BOOL shouldLoadAd;
@property (nonatomic, strong) UITapGestureRecognizer *debugGestureRecognizer;

@end

@implementation PIXAdManagerAdapterAdMob

@synthesize isInitialized = _isInitialized;
@synthesize delegate = _delegate;

- (NSString *)name {
    return kMediationAdapter;
}

- (void)configureWithConfiguration:(NSDictionary *)configuration {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.configuration = configuration;
    self.adUnitID = self.configuration[kAdManagerConfigurationAdUnitKey];

    id adSizeValue = self.configuration[kAdManagerConfigurationAdSizeKey];
    self.adSize = [adSizeValue isKindOfClass:[NSString class]] ? CGSizeFromString(adSizeValue) : CGSizeZero;

    id FBTrackingEnabledValue = self.configuration[kAdManagerConfigurationFBTrackingEnabledKey];
    self.FBTrackingEnabled = [FBTrackingEnabledValue respondsToSelector:@selector(boolValue)] ? [FBTrackingEnabledValue boolValue] : NO;

    id amazonAPSAppValue = self.configuration[kAdManagerConfigurationAmazonAPSAppKey];
    id amazonAPSSlotIDValue = self.configuration[kAdManagerConfigurationAmazonAPSSlotIDKey];
    self.amazonAPSApp = [amazonAPSAppValue isKindOfClass:[NSString class]] ? amazonAPSAppValue : nil;
    self.amazonAPSSlotID = [amazonAPSSlotIDValue isKindOfClass:[NSString class]] ? amazonAPSSlotIDValue : nil;
    self.amazonAPSConfigured = self.amazonAPSApp.length > 0 &&
                               self.amazonAPSSlotID.length > 0 &&
                               [[NSUUID alloc] initWithUUIDString:self.amazonAPSApp] != nil &&
                               [[NSUUID alloc] initWithUUIDString:self.amazonAPSSlotID] != nil;
    
    #if DEBUG
        NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.configuration);
        NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.adUnitID);
        NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.amazonAPSApp);
        NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.amazonAPSSlotID);
    #endif
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), NSStringFromCGSize(self.adSize));
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.FBTrackingEnabled ? @"Y" : @"N");
    
    #ifdef HAS_INCLUDE_FBADSETTINGS
        [FBAdSettings setAdvertiserTrackingEnabled:self.FBTrackingEnabled];
    #endif
    
    #ifdef HAS_INCLUDE_AMAZONAPS
    if (self.amazonAPSConfigured) {
        [[DTBAds sharedInstance] setAppKey:self.amazonAPSApp]; //@"d72716b8-271b-416f-9554-7240e15734ca"
        DTBAdNetworkInfo *dtbAdNetworkInfo = [[DTBAdNetworkInfo alloc] initWithNetworkName:DTBADNETWORK_ADMOB];
        [[DTBAds sharedInstance] setAdNetworkInfo:dtbAdNetworkInfo];
    } else if (self.amazonAPSApp.length > 0 || self.amazonAPSSlotID.length > 0) {
        NSLog(@"[AdManager][%@] > *** WARNING *** > Amazon APS configuration is incomplete or invalid", self.name);
    }
    #endif
    
    // AdMob initialisation
    GADMobileAds *ads = [GADMobileAds sharedInstance];
    [ads startWithCompletionHandler:^(GADInitializationStatus *status) {
        // Optional: Log each adapter's initialization latency.
        NSDictionary *adapterStatuses = [status adapterStatusesByClassName];
        for (NSString *adapter in adapterStatuses) {
            GADAdapterStatus *adapterStatus = adapterStatuses[adapter];
            NSLog(@"[AdManager][%@] > SDK initialization > Adapter Name: %@, Description: %@, Latency: %f", self.name, adapter, adapterStatus.description, adapterStatus.latency);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[AdManager][%@] > SDK initialized ", self.name);
            self->_isInitialized = YES;
            if (self.shouldLoadAd) {
                [self adapterViewLoadAd];
            }
        });
    }];
}

- (void)adapterViewInit {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.adView = [[GADBannerView alloc] initWithAdSize:GADAdSizeBanner];
    self.adView.delegate = self;
    self.adView.adUnitID = self.adUnitID;
    self.adView.rootViewController = [self.delegate viewControllerForAdapter];
}

- (void)adapterViewAdjustSize {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    UIView *superView = self.adView.superview;
    if (superView == nil) {
        NSLog(@"[AdManager] > *** WARNING *** > AdView needs to be attached to the superView before loading an ad");
        return;
    }
    
    CGRect frame = superView.frame;
    // Here safe area is taken into account, hence the view frame is used after the view has been laid out.
    if (@available(iOS 11.0, *)) {
        frame = UIEdgeInsetsInsetRect(superView.frame, superView.safeAreaInsets);
    }
    
    // Assume full width and height
    CGSize adSize = CGSizeMake(frame.size.width, 50.0f);
    if (self.adSize.width > 0.0f) {
        adSize.width = MIN(adSize.width, self.adSize.width);
    }
    if (self.adSize.height > 0.0f) {
        adSize.height = MAX(adSize.height, self.adSize.height);
    }
    
    // AdView Size customisation logic
    self.adView.adSize = GADLargeAnchoredAdaptiveBannerAdSizeWithWidth(adSize.width);
    if (self.adSize.height > 0.0f) {
        self.adView.adSize = GADAdSizeFromCGSize(adSize);
    }
    
    [superView layoutIfNeeded];
}

- (void)adapterViewLoadAd {
    NSLog(@"[AdManager][%@] > %@ > Initialized? %@", self.name, NSStringFromSelector(_cmd), self.isInitialized ? @"Yes" : @"No");

    self.shouldLoadAd = YES;

    if (self.isInitialized) {
        GADRequest *request = [GADRequest request];

        #ifdef HAS_INCLUDE_AMAZONAPS
        if (self.amazonAPSConfigured) {
            NSString *slotId = self.amazonAPSSlotID; //@"842b59ef-2c34-4308-8be6-b38a6a912f26";
            [request registerAdNetworkExtras:[APSAdMobUtils extrasWithSlotUUID:slotId adFormat:APSAdFormatBanner]];
        }
        #endif

        [self.adView loadRequest:request];
        self.adView.autoloadEnabled = YES;
    }
}

- (void)adapterViewStopAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));

    self.shouldLoadAd = NO;
    self.adView.autoloadEnabled = NO;
}

#pragma mark - Delegate methods

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), bannerView);
    if (self.shouldLoadAd && [self.delegate respondsToSelector:@selector(adapterDidLoadAd)]) {
        [self.delegate adapterDidLoadAd];
    }
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
    if (self.shouldLoadAd) {
        if ([self.delegate respondsToSelector:@selector(adapterDidFailToLoadAdWithError:)]) {
            [self.delegate adapterDidFailToLoadAdWithError:error];
        } else if ([self.delegate respondsToSelector:@selector(adapterDidFailToLoadAd)]) {
            [self.delegate adapterDidFailToLoadAd];
        }
    }
}

#pragma mark - Debug methods

- (void)adapterViewDebug {
    UIView *gestureTriggerView = [self.delegate viewControllerForAdapter].view;
    if (gestureTriggerView == nil || self.debugGestureRecognizer != nil) {
        return;
    }

    self.debugGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewDebugGesture:)];
    self.debugGestureRecognizer.numberOfTapsRequired = 3;
    [gestureTriggerView addGestureRecognizer:self.debugGestureRecognizer];
}

- (void)handleViewDebugGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [[GADMobileAds sharedInstance] presentAdInspectorFromViewController:[self.delegate viewControllerForAdapter] completionHandler:^(NSError * _Nullable error) {
            if (error) {
                NSLog(@"[AdManager][%@] > %@ : Ad Inspector not loaded: %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
            }
        }];
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.debugGestureRecognizer.view removeGestureRecognizer:self.debugGestureRecognizer];
    NSLog(@"[AdManager][%@] > %@", self.name, NSStringFromSelector(_cmd));
}

@end
