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

@end

@implementation PIXAdManagerAdapterMoPub

- (BOOL)isInitialized {
    return [MoPub sharedInstance].isSdkInitialized;
}

- (NSString *)name {
    return kMediationPartner;
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

- (void)adViewInit {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));

    self.adView = [[MPAdView alloc] initWithAdUnitId:self.adUnitID];
    self.adView.delegate = self;
}

- (void)adViewAdjustSizeToView:(UIView *)view {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    [self.adView.widthAnchor constraintEqualToAnchor:view.widthAnchor].active = YES;
    [self.adView.heightAnchor constraintEqualToConstant:kMPPresetMaxAdSize50Height.height].active = YES;
}

- (void)adViewLoadAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    if (self.isInitialized) {
        [self.adView loadAdWithMaxAdSize:kMPPresetMaxAdSize50Height];
        [self.adView startAutomaticallyRefreshingContents];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self adViewLoadAd];
        });
    }
}

- (void)adViewStopAd {
    NSLog(@"[AdManager][%@] > %@ ", self.name, NSStringFromSelector(_cmd));
    
    [self.adView stopAutomaticallyRefreshingContents];
}

// MPAdView delegate calls

- (UIViewController *)viewControllerForPresentingModalView {
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)adViewDidLoadAd:(MPAdView *)view adSize:(CGSize)adSize {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), view);
    [self.delegate adapterDidLoadAd:view];
}

- (void)adView:(MPAdView *)view didFailToLoadAdWithError:(NSError *)error {
    NSLog(@"[AdManager][%@] > %@ : %@", self.name, NSStringFromSelector(_cmd), [error localizedDescription]);
    [self.delegate adapterDidFailToLoadAdWithError:error];
}

@end

/*

// Consent Dialog
- (void)initConsentDialog {
    NSLog(@"[AdManager][%@] > %@ : GDPR (%@) - Should show (%@) - Status (%zd)", self.adapterName, NSStringFromSelector(_cmd), [MoPub sharedInstance].isGDPRApplicable ? @"Yes" : @"No", [MoPub sharedInstance].shouldShowConsentDialog ? @"Yes" : @"No", [MoPub sharedInstance].currentConsentStatus);
    if ([MoPub sharedInstance].shouldShowConsentDialog) {
        [[MoPub sharedInstance] loadConsentDialogWithCompletion:^(NSError *error) {
            if (error) {
                // TODO: Show error
            } else {
                UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
                [[MoPub sharedInstance] showConsentDialogFromViewController:rootViewController
                                                                 completion:nil];
            }
        }];
    }
}

*/
