//
//  ViewController.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import "ViewController.h"
#import "PIXAdManager.h"
#import "PIXConsentManager.h"

@interface ViewController () <PIXAdManagerDelegate>

@property (nonatomic, strong) NSLayoutConstraint *adViewBottomLayoutContraint;
@property (nonatomic, assign) BOOL didInitializeAds;

- (void)startAdsIfAllowed;

@end

@implementation ViewController

#pragma mark - Demo project methods

- (IBAction)showFirstViewController:(id)sender {
    [self performSegueWithIdentifier:@"SegueToFirstVC" sender:sender];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.title = @"Root ViewController";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    PIXConsentManager *consentManager = [PIXConsentManager sharedManager];
    __weak __typeof__(self) weakSelf = self;
    [consentManager startConsentFlowIfNeeded:ConsentFlowAdMobCMP fromPresentingViewController:self completion:^(NSString * _Nonnull statusString) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        NSLog(@"[LogMe][ConsentManager] > callback with status: %@", statusString);

        if ([PIXConsentManager sharedManager].canRequestAds) {
            [strongSelf startAdsIfAllowed];
        } else {
            [[PIXAdManager sharedManager] pauseAd];
            [strongSelf showAdView:NO animated:NO];
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    PIXAdManager *adManager = [PIXAdManager sharedManager];
    [adManager applicationNotificationsEnabled:NO];
    [adManager pauseAd];

    [super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    PIXAdManager *adManager = [PIXAdManager sharedManager];
    [adManager applicationNotificationsEnabled:NO];
    // Check as the delegate could be set to another viewController
    if (adManager.delegate == self) {
        adManager.delegate = nil;
    }
}

#pragma mark - AdManager AdView support methods

- (void)startAdsIfAllowed {
    if (![PIXConsentManager sharedManager].canRequestAds) {
        return;
    }

    PIXAdManager *adManager = [PIXAdManager sharedManager];
    adManager.delegate = self;

    if (!self.didInitializeAds) {
        // Adapter initialization may start ad SDKs, so keep this behind the consent gate.
        NSDictionary *admobTestConfiguration = @{
            kAdManagerConfigurationAdUnitKey:@"ca-app-pub-3940256099942544/2934735716",
            kAdManagerConfigurationAdSizeKey:@"{-1.0f,-1.0f}",
        };
        [adManager initializeWithMediationAdapter:AdManagerAdapterAdMob andConfiguration:admobTestConfiguration];

//        NSDictionary *applovinTestConfiguration = @{@"adUnitID": @"03291466ee732cfa"};
//        [adManager initializeWithMediationAdapter:AdManagerAdapterAppLovin andConfiguration:applovinTestConfiguration];

        #if DEBUG
            NSDictionary *debugConfiguration = @{
                @"testDevices": @{
                    @"facebook": @[@"8f43ab85f1144df4cdc5d2b4e30cdd0ff111905d", // iPhone 11 Pro Brain
                                   @"b602d594afd2b0b327e07a06f36ca6a7e42546d0", // iPhone X
                                   @"00000000-0000-0000-0000-000000000000"], // Simulator
                    @"admob": @[@"d7a9eedb0e0697d89ece1697ccdc8a93", // iPhone 11 Pro Brain
                                @"c4a3d37c376300f94a8f497ca4c7e55c"] // iPhone SE 2 Brain
                }
            };
            [adManager debugEnabledWithConfiguration:debugConfiguration];
        #endif

        self.didInitializeAds = adManager.adView != nil;
    }

    [self setupAdView];
    [adManager applicationNotificationsEnabled:YES];
    [adManager loadAd];
}

- (void)setupAdView {
    NSLog(@"[AdManager][%@] > %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));

    UIView *adView = [PIXAdManager sharedManager].adView;
    if (!adView) {
        return;
    }

    BOOL shouldAttachAdView = adView.superview != self.view;
    if (shouldAttachAdView) {
        [adView removeFromSuperview];
        adView.translatesAutoresizingMaskIntoConstraints = NO;
        adView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [self.view addSubview:adView];
    }

    [[PIXAdManager sharedManager] adViewSetupSize];

    if (shouldAttachAdView) {
        [adView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    }
    if (self.adViewBottomLayoutContraint.firstItem != adView) {
        NSLog(@"[AdManager][%@] > %@ > New adViewBottomLayoutContraint is needed", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
        self.adViewBottomLayoutContraint.active = NO;
        self.adViewBottomLayoutContraint = [adView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor];
        self.adViewBottomLayoutContraint.active = YES;
    }

    [self showAdView:NO animated:NO];

}

- (void)showAdView:(BOOL)show animated:(BOOL)animated {
    NSLog(@"[AdManager][%@] > %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));

    UIView *adView = [PIXAdManager sharedManager].adView;

    // hidden values
    CGFloat _height = adView.frame.size.height;
    CGFloat _alpha = 0.0;
    BOOL _hidden = YES;
    if (show) {
        // show values
        _height = 0.0;
        _alpha = 1.0;
        _hidden = NO;
    }

    NSTimeInterval _duration = 0.0;
    NSTimeInterval _delay = 0.0;
    if (animated) {
        _duration = 0.3;
        _delay = 0.1;
    }

    [adView.superview layoutIfNeeded];
    adView.hidden = NO;
    [UIView animateWithDuration:_duration
                          delay:_delay
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.adViewBottomLayoutContraint.constant = _height;
        adView.alpha = _alpha;
        [adView.superview layoutIfNeeded];
    }
                     completion:^(BOOL finished) {
        if (finished) {
            adView.hidden = _hidden;
        }
    }];
}

#pragma mark - AdManager delegate methods

- (UIViewController *)viewControllerForAdManager {
    return self;
}

- (void)adManagerDidLoadAd {
    [self showAdView:YES animated:YES];
}

- (void)adManagerDidFailToLoadAdWithError:(NSError *)error {
    NSLog(@"[AdManager] > Failed to load ad: %@ (%@, %ld)", error.localizedDescription, error.domain, (long)error.code);
    [self showAdView:NO animated:YES];
}

- (void)adManagerDidPauseAd {
    [self showAdView:NO animated:NO];
}

@end
