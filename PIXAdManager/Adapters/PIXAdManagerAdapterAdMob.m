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

@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *adUnitID;

@end

@implementation PIXAdManagerAdapterAdMob

@dynamic isInitialized;

- (NSString *)name {
    return kMediationPartner;
}

- (UIView *)adapterAdView {
    if (!self.adView) {
        self.adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
        self.adView.delegate = self;
        self.adView.adUnitID = self.adUnitID;
    }
    return self.adView;
}

- (void)initWithConfiguration:(NSDictionary *)configuration {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.configuration = configuration;
    
    NSString *configurationAdUnitID = self.configuration[@"adUnitID"];
    self.adUnitID = configurationAdUnitID ? configurationAdUnitID : kTestindAdUnitID;
    
    // AdMob initialisation
    GADMobileAds *ads = [GADMobileAds sharedInstance];
    [ads startWithCompletionHandler:^(GADInitializationStatus *status) {
        // Optional: Log each adapter's initialization latency.
        NSDictionary *adapterStatuses = [status adapterStatusesByClassName];
        for (NSString *adapter in adapterStatuses) {
            GADAdapterStatus *adapterStatus = adapterStatuses[adapter];
            NSLog(@"[LogMe][AdMob] > SDK initialization > Adapter Name: %@, Description: %@, Latency: %f", adapter, adapterStatus.description, adapterStatus.latency);
        }
        NSLog(@"[LogMe][AdMob] > SDK initialization complete");
        self.isInitialized = YES;
    }];
}

- (void)adViewInit {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    self.adView.delegate = self;
    self.adView.adUnitID = self.adUnitID;
    self.adView.rootViewController = [self.delegate viewControllerForPresentingModalView];
}

- (void)adViewAdjustSizeToView:(UIView *)view {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    CGRect frame = view.frame;
    // Here safe area is taken into account, hence the view frame is used after the view has been laid out.
    if (@available(iOS 11.0, *)) {
        frame = UIEdgeInsetsInsetRect(view.frame, view.safeAreaInsets);
    }
    CGFloat viewWidth = frame.size.width;
    self.adView.adSize = GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth);
}

- (void)adViewLoadAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    if (self.isInitialized) {
        [self.adView loadRequest:[GADRequest request]];
        self.adView.autoloadEnabled = YES;
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self adViewLoadAd];
        });
    }
}

- (void)adViewStopAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.adView.autoloadEnabled = NO;
}

// GADBannerView delegate calls

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), bannerView);
    [self.delegate adapterDidLoadAd:bannerView];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
    [self.delegate adapterDidFailToLoadAdWithError:error];
}

@end
