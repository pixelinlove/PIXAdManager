//
//  PIXAdManagerAdapterAdMob.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 10/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterAdMob.h"

static NSString * const kMediationPartner = @"AdMob";
static NSString * const kTestindAdUnitID = @"ca-app-pub-3940256099942544/2934735716";

@interface PIXAdManagerAdapterAdMob ()

@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, strong) GADBannerView *adView;

@end

@implementation PIXAdManagerAdapterAdMob

- (NSString *)adapterName {
    return kMediationPartner;
}

- (UIView *)adapterAdView {
    if (!self.adView) {
        self.adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        self.adView.adUnitID = self.adUnitID;
        self.adView.delegate = self;
    }
    return self.adView;
}

- (void)initializeWithConfiguration:(nonnull NSDictionary *)configuration {
    
    NSString *configurationAdUnitID = configuration[@"adUnitID"];
    self.adUnitID = configurationAdUnitID ? configurationAdUnitID : kTestindAdUnitID;
    
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
    
}

- (void)loadAd {
    if (!self.adView.rootViewController) {
        self.adView.rootViewController = [self.adapterDelegate viewControllerForPresentingModalView];
    }
    [self.adView loadRequest:[GADRequest request]];
}

- (void)startRefreshing {
    self.adView.autoloadEnabled = YES;
}

- (void)stopRefreshing {
    self.adView.autoloadEnabled = NO;
}

- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    NSLog(@"[AdManager][AdMob] > %@ > %@", NSStringFromSelector(_cmd), adView);
    [self.adapterDelegate adapterDidLoadAd:adView];
}

- (void)adView:(GADBannerView *)adView didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"[AdManager][AdMob] > %@ > %@", NSStringFromSelector(_cmd), [error localizedDescription]);
    [self.adapterDelegate adapterDidFailToLoadAdWithError:error];
}

@end
