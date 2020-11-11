//
//  PIXAdManagerAdapterMoPub.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterMoPub.h"

static NSString * const kMediationPartner = @"MoPub";
static NSString * const kTestindAdUnitID = @"0ac59b0996d947309c33f59d6676399f";

@interface PIXAdManagerAdapterMoPub ()

@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, strong) MPAdView *adView;
@property (nonatomic, assign) BOOL isSdkInitialized;

@end

@implementation PIXAdManagerAdapterMoPub

- (NSString *)adapterName {
    return kMediationPartner;
}

- (UIView *)adapterAdView {
    if (!self.adView) {
        self.adView = [[MPAdView alloc] initWithAdUnitId:self.adUnitID];
        self.adView.delegate = self;
    }
    return self.adView;
}

- (void)initializeWithConfiguration:(NSDictionary *)configuration {
    
    self.configuration = configuration;
    NSString *configurationAdUnitID = self.configuration[@"adUnitID"];
    self.adUnitID = configurationAdUnitID ? configurationAdUnitID : kTestindAdUnitID;
    
    MPMoPubConfiguration *sdkConfig = [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:self.adUnitID];

    [[MoPub sharedInstance] initializeSdkWithConfiguration:sdkConfig completion:^{
        // SDK initialization complete. Ready to make ad requests.
        NSLog(@"[AdManager][%@] > %@ ", self.adapterName, NSStringFromSelector(_cmd));
    }];
}

// MPAdView ad loading

- (BOOL)isSdkInitialized {
    return [MoPub sharedInstance].isSdkInitialized;
}

- (void)loadAd {
    NSLog(@"[AdManager][%@] > %@ ", self.adapterName, NSStringFromSelector(_cmd));
    if (self.isSdkInitialized) {
        [self.adView loadAdWithMaxAdSize:kMPPresetMaxAdSize50Height];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self loadAd];
        });
    }
}

- (void)startRefreshing {
    [self.adView startAutomaticallyRefreshingContents];
}

- (void)stopRefreshing {
    [self.adView stopAutomaticallyRefreshingContents];
}

// MPAdView delegate calls

- (UIViewController *)viewControllerForPresentingModalView {
    return [self.adapterDelegate viewControllerForPresentingModalView];
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {
    NSLog(@"[AdManager][%@] > %@ : %@", self.adapterName, NSStringFromSelector(_cmd), view);
    [self.adapterDelegate adapterDidLoadAd:view];
}

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.adapterName, NSStringFromSelector(_cmd), [error localizedDescription]);
    [self.adapterDelegate adapterDidFailToLoadAdWithError:error];
}

@end
