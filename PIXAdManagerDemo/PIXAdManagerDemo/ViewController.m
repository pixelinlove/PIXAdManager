//
//  ViewController.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) NSLayoutConstraint *adViewBottomLayoutContraint;

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
    
    NSDictionary *mopubTestConfiguration = @{@"adUnitID": @"b195f8dd8ded45fe847ad89ed1d016da"};
    NSDictionary *admobTestConfiguration = @{@"adUnitID": @"ca-app-pub-3940256099942544/2934735716"};
    NSDictionary *applovinTestConfiguration = @{@"adUnitID": @"03291466ee732cfa"};
    
    PIXAdManager *adManager = [PIXAdManager sharedManager];
    adManager.delegate = self;
    [adManager initializeWithMediationAdapter:AdManagerAdapterAppLovin andConfiguration:applovinTestConfiguration];
    
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
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setupAdView];
    
    PIXAdManager *adManager = [PIXAdManager sharedManager];
    [adManager applicationNotificationsEnabled:YES];
    [adManager loadAd];
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

- (void)setupAdView {
    NSLog(@"[AdManager][%@] > %@", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
    
    UIView *adView = [PIXAdManager sharedManager].adView;
    
    adView.translatesAutoresizingMaskIntoConstraints = NO;
    adView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self.view addSubview:adView];
    
    [[PIXAdManager sharedManager] adViewSetupSize];
    [adView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    if (self.adViewBottomLayoutContraint.firstItem != adView) {
        NSLog(@"[AdManager][%@] > %@ > New adViewBottomLayoutContraint is needed", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
        self.adViewBottomLayoutContraint.active = NO;
        self.adViewBottomLayoutContraint = [adView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor];
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

- (void)adManagerDidFailToLoadAd {
    [self showAdView:NO animated:YES];
}

- (void)adManagerDidPauseAd {
    [self showAdView:NO animated:NO];
}

@end
