//
//  PIXAdManagerAdapterAppLovin.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 26/12/2021.
//  Copyright © 2021 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterAppLovin.h"
#import "PIXAdManagerAdapter.h"
#import <AppLovinSDK/AppLovinSDK.h>

#if __has_include(<FBAudienceNetwork/FBAdSettings.h>)
    #import <FBAudienceNetwork/FBAdSettings.h>
    #define HAS_INCLUDE_FBADSETTINGS
#endif

static NSString * const kMediationAdapter = @"AppLovin";
static NSString * const kAppLovinErrorDomain = @"PIXAdManager.AppLovin";

@interface PIXAdManagerAdapterAppLovin () <PIXAdManagerAdapter, MAAdViewAdDelegate>

@property (nonatomic, strong, readwrite) MAAdView *adView;
@property (nonatomic, assign, readwrite) BOOL isInitialized;
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *sdkKey;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, assign) BOOL FBTrackingEnabled;
@property (nonatomic, assign) BOOL shouldLoadAd;
@property (nonatomic, strong) NSLayoutConstraint *adViewWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint *adViewHeightConstraint;
@property (nonatomic, strong) UITapGestureRecognizer *debugGestureRecognizer;

@end

@implementation PIXAdManagerAdapterAppLovin

@synthesize isInitialized = _isInitialized;
@synthesize delegate = _delegate;

- (NSString *)name {
    return kMediationAdapter;
}

- (void)configureWithConfiguration:(NSDictionary *)configuration {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.configuration = configuration;
    self.sdkKey = self.configuration[kAdManagerConfigurationSDKKeyKey];
    self.adUnitID = self.configuration[kAdManagerConfigurationAdUnitKey];

    id adSizeValue = self.configuration[kAdManagerConfigurationAdSizeKey];
    self.adSize = [adSizeValue isKindOfClass:[NSString class]] ? CGSizeFromString(adSizeValue) : CGSizeZero;

    id FBTrackingEnabledValue = self.configuration[kAdManagerConfigurationFBTrackingEnabledKey];
    self.FBTrackingEnabled = [FBTrackingEnabledValue respondsToSelector:@selector(boolValue)] ? [FBTrackingEnabledValue boolValue] : NO;
    
    #if DEBUG
        NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.configuration);
        NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.sdkKey);
        NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.adUnitID);
    #endif
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), NSStringFromCGSize(self.adSize));
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.FBTrackingEnabled ? @"Y" : @"N");
    
    #ifdef HAS_INCLUDE_FBADSETTINGS
        if (@available(iOS 17.0, *)) {
            // Audience Network reads the ATT status directly on iOS 17 and later.
        } else {
            [FBAdSettings setAdvertiserTrackingEnabled:self.FBTrackingEnabled];
        }
    #endif
    
    // AppLovin initialisation
    
    // Create the initialization configuration
    ALSdkInitializationConfiguration *initConfig = [ALSdkInitializationConfiguration configurationWithSdkKey:self.sdkKey builderBlock:^(ALSdkInitializationConfigurationBuilder *builder) {

      builder.mediationProvider = ALMediationProviderMAX;

      // Perform any additional configuration/setting changes
    }];
    
    [[ALSdk shared] initializeWithConfiguration:initConfig completionHandler:^(ALSdkConfiguration *sdkConfig) {
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

    self.adView = [[MAAdView alloc] initWithAdUnitIdentifier:self.adUnitID];
    self.adView.delegate = self;
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
    if (self.adViewWidthConstraint == nil) {
        self.adViewWidthConstraint = [self.adView.widthAnchor constraintEqualToConstant:adSize.width];
        self.adViewHeightConstraint = [self.adView.heightAnchor constraintEqualToConstant:adSize.height];
        [NSLayoutConstraint activateConstraints:@[self.adViewWidthConstraint, self.adViewHeightConstraint]];
    } else {
        self.adViewWidthConstraint.constant = adSize.width;
        self.adViewHeightConstraint.constant = adSize.height;
    }
    
    [superView layoutIfNeeded];
}

- (void)adapterViewLoadAd {
    NSLog(@"[AdManager][%@] > %@ > Initialized? %@", self.name, NSStringFromSelector(_cmd), self.isInitialized ? @"Yes" : @"No");

    self.shouldLoadAd = YES;

    if (self.isInitialized) {
        [self.adView loadAd];
        [self.adView startAutoRefresh];
    }
}

- (void)adapterViewStopAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));

    self.shouldLoadAd = NO;
    [self.adView stopAutoRefresh];
}

#pragma mark - Delegate methods

- (void)didLoadAd:(nonnull MAAd *)ad {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), ad);
    if (self.shouldLoadAd && [self.delegate respondsToSelector:@selector(adapterDidLoadAd)]) {
        [self.delegate adapterDidLoadAd];
    }
}

- (void)didFailToLoadAdForAdUnitIdentifier:(nonnull NSString *)adUnitIdentifier withError:(nonnull MAError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error message]);
    if (self.shouldLoadAd) {
        NSString *errorMessage = error.message ?: @"AppLovin failed to load an ad";
        NSError *adapterError = [NSError errorWithDomain:kAppLovinErrorDomain
                                                     code:(NSInteger)error.code
                                                 userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
        if ([self.delegate respondsToSelector:@selector(adapterDidFailToLoadAdWithError:)]) {
            [self.delegate adapterDidFailToLoadAdWithError:adapterError];
        } else if ([self.delegate respondsToSelector:@selector(adapterDidFailToLoadAd)]) {
            [self.delegate adapterDidFailToLoadAd];
        }
    }
}

- (void)didClickAd:(nonnull MAAd *)ad {}

- (void)didDisplayAd:(nonnull MAAd *)ad {}

- (void)didFailToDisplayAd:(nonnull MAAd *)ad withError:(nonnull MAError *)error {}

- (void)didHideAd:(nonnull MAAd *)ad {}

- (void)didCollapseAd:(nonnull MAAd *)ad {}

- (void)didExpandAd:(nonnull MAAd *)ad {}

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
        [[ALSdk shared] showMediationDebugger];
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.debugGestureRecognizer.view removeGestureRecognizer:self.debugGestureRecognizer];
    NSLog(@"[AdManager][%@] > %@", self.name, NSStringFromSelector(_cmd));
}

@end
