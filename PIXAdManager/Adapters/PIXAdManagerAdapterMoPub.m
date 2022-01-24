//
//  PIXAdManagerAdapterMoPub.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterMoPub.h"

static NSString * const kMediationAdapter = @"MoPub";

@interface PIXAdManagerAdapterMoPub ()

@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, assign) CGSize adSize;
@property (nonatomic, assign) BOOL FBTrackingEnabled;

@end

@implementation PIXAdManagerAdapterMoPub

- (BOOL)isInitialized {
    return [MoPub sharedInstance].isSdkInitialized;
}

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
    
    // MoPub initialisation
    MPMoPubConfiguration *sdkConfig = [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:self.adUnitID];

    [[MoPub sharedInstance] initializeSdkWithConfiguration:sdkConfig completion:^{
        NSLog(@"[AdManager][%@] > SDK initialized ", self.name);
    }];
}

- (void)adapterViewInit {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));

    self.adView = [[MPAdView alloc] initWithAdUnitId:self.adUnitID];
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
        [self.adView loadAdWithMaxAdSize:kMPPresetMaxAdSizeMatchFrame];
        [self.adView startAutomaticallyRefreshingContents];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self adapterViewLoadAd];
        });
    }
}

- (void)adapterViewStopAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    [self.adView stopAutomaticallyRefreshingContents];
}

#pragma mark - Delegate methods

- (UIViewController *)viewControllerForPresentingModalView {
    return [self.delegate viewControllerForAdapter];
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), view);
    if ([self.delegate respondsToSelector:@selector(adapterDidLoadAd)]) {
        [self.delegate adapterDidLoadAd];
    }
}

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
    if ([self.delegate respondsToSelector:@selector(adapterDidFailToLoadAd)]) {
        [self.delegate adapterDidFailToLoadAd];
    }
}

#pragma mark - Debug methods

- (void)adapterViewDebug {
    // Implement MoPub Testing suite if available.
}

#pragma mark - Dealloc

- (void)dealloc {
    NSLog(@"[AdManager][%@] > %@", self.name, NSStringFromSelector(_cmd));
}

@end
