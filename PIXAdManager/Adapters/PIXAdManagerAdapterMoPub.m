//
//  PIXAdManagerAdapterMoPub.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapterMoPub.h"

static NSString * const kTestindAdUnitID = @"0ac59b0996d947309c33f59d6676399f";

@interface PIXAdManagerAdapterMoPub ()

@property (nonatomic, copy) NSString *adUnitID;
@property (nonatomic, strong) MPAdView *adView;

@end

@implementation PIXAdManagerAdapterMoPub

- (NSString *)adapterName {
    return @"MoPub";
}

- (UIView *)adapterAdView {
    if (!_adView) {
        _adView = [[MPAdView alloc] initWithAdUnitId:self.adUnitID];
        _adView.delegate = self;
    }
    return _adView;
}

- (void)initializeWithConfiguration:(NSDictionary *)configuration {
    
    NSString *configurationAdUnitID = configuration[@"adUnitID"];
    self.adUnitID = configurationAdUnitID ? configurationAdUnitID : kTestindAdUnitID;
    
    MPMoPubConfiguration *sdkConfig = [[MPMoPubConfiguration alloc] initWithAdUnitIdForAppInitialization:self.adUnitID];
    NSLog(@"[AdManager][MoPub] > GDPR applicable: %@", @([MoPub sharedInstance].isGDPRApplicable));
    NSLog(@"[AdManager][MoPub] > Should consent: %@", @([MoPub sharedInstance].shouldShowConsentDialog));
    NSLog(@"[AdManager][MoPub] > Current status: %zd", [MoPub sharedInstance].currentConsentStatus);

    [[MoPub sharedInstance] initializeSdkWithConfiguration:sdkConfig completion:^{
        NSLog(@"[AdManager][MoPub] > SDK initialization complete");
        NSLog(@"[AdManager][MoPub] > GDPR applicable: %@", @([MoPub sharedInstance].isGDPRApplicable));
        NSLog(@"[AdManager][MoPub] > Should consent: %@", @([MoPub sharedInstance].shouldShowConsentDialog));
        NSLog(@"[AdManager][MoPub] > Current status: %zd", [MoPub sharedInstance].currentConsentStatus);
        // SDK initialization complete. Ready to make ad requests.
    }];
}

- (void)loadAd {
    [self.adView loadAdWithMaxAdSize:kMPPresetMaxAdSize50Height];
}

- (void)startRefreshing {
    [self.adView startAutomaticallyRefreshingContents];
}

- (void)stopRefreshing {
    [self.adView stopAutomaticallyRefreshingContents];
}

- (UIViewController *)viewControllerForPresentingModalView {
    return [self.adapterDelegate viewControllerForPresentingModalView];
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {
    NSLog(@"[AdManager][MoPub] > %@ > %@", NSStringFromSelector(_cmd), view);
    [self.adapterDelegate adapterDidLoadAd:view];
}

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"[AdManager][MoPub] > %@ > %@", NSStringFromSelector(_cmd), [error localizedDescription]);
    [self.adapterDelegate adapterDidFailToLoadAdWithError:error];
}

@end
