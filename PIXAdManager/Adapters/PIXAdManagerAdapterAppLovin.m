//
//  PIXAdManagerAdapterAppLovin.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 26/12/2021.
//  Copyright © 2021 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterAppLovin.h"

static NSString * const kMediationAdapter = @"AppLovin";

@interface PIXAdManagerAdapterAppLovin ()

@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, assign) BOOL FBTrackingEnabled;

@end

@implementation PIXAdManagerAdapterAppLovin

@synthesize isInitialized = _isInitialized;

- (NSString *)name {
    return kMediationAdapter;
}

- (void)initWithConfiguration:(NSDictionary *)configuration {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.configuration = configuration;
    self.adUnitID = self.configuration[kAdManagerConfigurationAdUnitKey];
    self.adSize = CGSizeFromString(self.configuration[kAdManagerConfigurationAdSizeKey]);
    self.FBTrackingEnabled = [self.configuration[kAdManagerConfigurationFBTrackingEnabledKey] boolValue];
    
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.configuration);
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.adUnitID);
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), NSStringFromCGSize(self.adSize));
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.FBTrackingEnabled ? @"Y" : @"N");
    
    if (NSClassFromString(@"FBAdSettings") != nil) {
        [FBAdSettings setAdvertiserTrackingEnabled:self.FBTrackingEnabled];
    }
    
    // AppLovin initialisation
    // Please make sure to set the mediation provider value to @"max" to ensure proper functionality
    [ALSdk shared].mediationProvider = @"max";
    
    [[ALSdk shared] initializeSdkWithCompletionHandler:^(ALSdkConfiguration *configuration) {
        NSLog(@"[AdManager][%@] > SDK initialized ", self.name);
        self->_isInitialized = YES;
        // Start loading ads
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
    [self.adView.widthAnchor constraintEqualToConstant:adSize.width].active = YES;
    [self.adView.heightAnchor constraintEqualToConstant:adSize.height].active = YES;
    
    [superView layoutIfNeeded];
}

- (void)adapterViewLoadAd {
    NSLog(@"[AdManager][%@] > %@ > Initialized? %@", self.name, NSStringFromSelector(_cmd), self.isInitialized ? @"Yes" : @"No");
    
    if (self.isInitialized) {
        [self.adView loadAd];
        [self.adView startAutoRefresh];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self adapterViewLoadAd];
        });
    }
}

- (void)adapterViewStopAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    [self.adView stopAutoRefresh];
}

#pragma mark - Delegate methods

- (void)didLoadAd:(nonnull MAAd *)ad {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), ad);
    if ([self.delegate respondsToSelector:@selector(adapterDidLoadAd)]) {
        [self.delegate adapterDidLoadAd];
    }
}

- (void)didFailToLoadAdForAdUnitIdentifier:(nonnull NSString *)adUnitIdentifier withError:(nonnull MAError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error message]);
    if ([self.delegate respondsToSelector:@selector(adapterDidFailToLoadAd)]) {
        [self.delegate adapterDidFailToLoadAd];
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
    UITapGestureRecognizer *adViewDebugGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewDebugGesture:)];
    adViewDebugGestureRecognizer.numberOfTapsRequired = 3;
    [gestureTriggerView addGestureRecognizer:adViewDebugGestureRecognizer];
}

- (void)handleViewDebugGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [[ALSdk shared] showMediationDebugger];
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    NSLog(@"[AdManager][%@] > %@", self.name, NSStringFromSelector(_cmd));
}

@end
