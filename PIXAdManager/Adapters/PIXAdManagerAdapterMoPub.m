//
//  PIXAdManagerAdapterMoPub.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterMoPub.h"

static NSString * const kMediationAdapter = @"MoPub";
static NSString * const kTestindAdUnitID = @"0ac59b0996d947309c33f59d6676399f";

@interface PIXAdManagerAdapterMoPub ()

@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *adUnitID;

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
    
    NSString *configurationAdUnitID = self.configuration[@"adUnitID"];
    self.adUnitID = configurationAdUnitID ? configurationAdUnitID : kTestindAdUnitID;
    
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

- (void)adapterViewAdjustSizeToSuperView {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    UIView *superView = self.adView.superview;
    if (superView == nil) {
        NSLog(@"[AdManager] > *** WARNING *** AdView needs to be attached to the superView before loading an ad");
    }
    
    [self.adView.widthAnchor constraintEqualToAnchor:superView.widthAnchor].active = YES;
    [self.adView.heightAnchor constraintEqualToConstant:kMPPresetMaxAdSize50Height.height].active = YES;
    
    [superView layoutIfNeeded];
}

- (void)adapterViewLoadAd {
    NSLog(@"[AdManager][%@] > %@ > Initialized? %@", self.name, NSStringFromSelector(_cmd), self.isInitialized ? @"Yes" : @"No");
    
    if (self.isInitialized) {
        [self.adView loadAdWithMaxAdSize:kMPPresetMaxAdSize50Height];
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
    [self.delegate adapterDidLoadAd:view];
}

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
    [self.delegate adapterDidFailToLoadAdWithError:error];
}

#pragma mark - Debug methods

- (void)adapterViewDebug {
    // Implement MoPub Testing suite if available.
}

@end
