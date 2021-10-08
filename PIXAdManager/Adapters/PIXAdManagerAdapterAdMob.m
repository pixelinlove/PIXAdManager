//
//  PIXAdManagerAdapterAdMob.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 10/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterAdMob.h"

static NSString * const kMediationAdapter = @"AdMob";

@interface PIXAdManagerAdapterAdMob ()

@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, assign) CGSize adSize;

@end

@implementation PIXAdManagerAdapterAdMob

@synthesize isInitialized = _isInitialized;

- (NSString *)name {
    return kMediationAdapter;
}

- (void)initWithConfiguration:(NSDictionary *)configuration {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.configuration = configuration;
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), configuration);
    
    self.adUnitID = self.configuration[kAdManagerConfigurationAdUnitKey];
    self.adSize = CGSizeFromString(self.configuration[kAdManagerConfigurationAdSizeKey]);
    
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), self.adUnitID);
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), NSStringFromCGSize(self.adSize));
    
    // AdMob initialisation
    GADMobileAds *ads = [GADMobileAds sharedInstance];
    [ads startWithCompletionHandler:^(GADInitializationStatus *status) {
        // Optional: Log each adapter's initialization latency.
        NSDictionary *adapterStatuses = [status adapterStatusesByClassName];
        for (NSString *adapter in adapterStatuses) {
            GADAdapterStatus *adapterStatus = adapterStatuses[adapter];
            NSLog(@"[AdManager][%@] > SDK initialization > Adapter Name: %@, Description: %@, Latency: %f", self.name, adapter, adapterStatus.description, adapterStatus.latency);
        }
        NSLog(@"[AdManager][%@] > SDK initialized ", self.name);
        self->_isInitialized = YES;
    }];
}

- (void)adapterViewInit {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner];
    self.adView.delegate = self;
    self.adView.adUnitID = self.adUnitID;
    self.adView.rootViewController = [self.delegate viewControllerForAdapter];
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
    self.adView.adSize = GADPortraitAnchoredAdaptiveBannerAdSizeWithWidth(adSize.width);
    if (self.adSize.height > 0.0f) {
        self.adView.adSize = GADAdSizeFromCGSize(adSize);
    }
    
    [superView layoutIfNeeded];
}

- (void)adapterViewLoadAd {
    NSLog(@"[AdManager][%@] > %@ > Initialized? %@", self.name, NSStringFromSelector(_cmd), self.isInitialized ? @"Yes" : @"No");
    
    if (self.isInitialized) {
        [self.adView loadRequest:[GADRequest request]];
        self.adView.autoloadEnabled = YES;
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self adapterViewLoadAd];
        });
    }
}

- (void)adapterViewStopAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    self.adView.autoloadEnabled = NO;
}

#pragma mark - Delegate methods

- (void)bannerViewDidReceiveAd:(GADBannerView *)bannerView {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), bannerView);
    [self.delegate adapterDidLoadAd:bannerView];
}

- (void)bannerView:(GADBannerView *)bannerView didFailToReceiveAdWithError:(NSError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
    [self.delegate adapterDidFailToLoadAdWithError:error];
}

#pragma mark - Debug methods

- (void)adapterViewDebug {
    UIView *gestureTriggerView = [self.delegate viewControllerForAdapter].view;
    UITapGestureRecognizer *adViewDebugGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleViewDebugGesture:)];
    adViewDebugGestureRecognizer.numberOfTapsRequired = 3;
    [gestureTriggerView addGestureRecognizer:adViewDebugGestureRecognizer];
}

- (void)handleViewDebugGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        [[GADMobileAds sharedInstance] presentAdInspectorFromViewController:[self.delegate viewControllerForAdapter] completionHandler:^(NSError * _Nullable error) {
            NSLog(@"[AdManager][%@] > %@ : Ad Inspector not loaded: %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
        }];
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    NSLog(@"[AdManager][%@] > %@", self.name, NSStringFromSelector(_cmd));
}

@end
