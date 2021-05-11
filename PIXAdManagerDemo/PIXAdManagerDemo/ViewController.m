//
//  ViewController.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import "ViewController.h"

#define MEDIATION_PARTNER 1

@interface ViewController ()

@property (nonatomic, strong) UIView *adView;
@property (nonatomic, assign) CGSize adViewDesignedSize;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSDictionary *testMopubConfiguration = @{@"adUnitID": @"0ac59b0996d947309c33f59d6676399f"};
    NSDictionary *testAdmobConfiguration = @{@"adUnitID": @"ca-app-pub-3940256099942544/2934735716"};
    NSDictionary *mopubConfiguration = @{@"adUnitID": @"2e8c909d6e114a67aad04c5ca014f85c"};
    NSDictionary *adMobConfiguration = @{@"adUnitID": @"ca-app-pub-3008186008208131/8209379850"};
    
    PIXAdManager *adManager = [PIXAdManager sharedManager];
    adManager.delegate = self;
    [adManager initMediationPartner:MediationPartnerAdMob withConfiguration:adMobConfiguration];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    PIXAdManager *adManager = [PIXAdManager sharedManager];
//    [adManager loadAd];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (UIViewController *)viewControllerForAdView {
    return self;
}

@end
