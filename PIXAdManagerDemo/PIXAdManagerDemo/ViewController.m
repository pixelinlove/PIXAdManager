//
//  ViewController.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIView *adView;
@property (nonatomic, assign) CGSize adViewDesignedSize;
@property (nonatomic, strong) NSLayoutConstraint *adViewBottomLayoutContraint;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    PIXAdManager *adManager = [PIXAdManager sharedManager];
    adManager.delegate = self;
    
    self.adView = adManager.adView;
    
    self.adView.translatesAutoresizingMaskIntoConstraints = NO;
    self.adViewDesignedSize = CGSizeMake(320.0, 50.0);
    [self.view addSubview:self.adView];

    [self.adView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;
    [self.adView.heightAnchor constraintEqualToConstant:self.adViewDesignedSize.height].active = YES;
    [self.adView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    
    [self showAdView:NO animated:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:adManager.delegate
                                             selector:@selector(appNotificationForAdView:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:adManager.delegate
                                             selector:@selector(appNotificationForAdView:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:adManager.delegate
                                             selector:@selector(appNotificationForAdView:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showAdView:(BOOL)show animated:(BOOL)animated {
    
    // hidden values
    CGFloat _height = self.adViewDesignedSize.height;
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
    
    if (!self.adViewBottomLayoutContraint) {
        self.adViewBottomLayoutContraint = [self.adView.bottomAnchor constraintEqualToAnchor:self.bottomLayoutGuide.topAnchor constant:_height];
        self.adViewBottomLayoutContraint.active = YES;
    }
    
    [self.adView.superview layoutIfNeeded];
    self.adView.hidden = NO;
    [UIView animateWithDuration:_duration
                          delay:_delay
                        options:UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        self.adViewBottomLayoutContraint.constant = _height;
        self.adView.alpha = _alpha;
        [self.adView.superview layoutIfNeeded];
    }
                     completion:^(BOOL finished) {
        if (finished) {
            self.adView.hidden = _hidden;
        }
    }];
}

- (void)appNotificationForAdView:(NSNotification *)notification {
    if (notification.name == UIApplicationDidBecomeActiveNotification) {
        NSLog(@"[LogMe] > Application Did Become Active - Banner will refresh");
        [self startAd];
    }
    
    if (notification.name == UIApplicationWillResignActiveNotification) {
        NSLog(@"[LogMe] > Application Will Resign Active - Banner will hide");
        [self pauseAd];
    }
}

- (void)pauseAd {
    [[PIXAdManager sharedManager] stopRefreshing];
    [self showAdView:NO animated:NO];
}

- (void)startAd {
    [[PIXAdManager sharedManager] loadAd];
    [[PIXAdManager sharedManager] startRefreshing];
}

#pragma mark - Ads delegates

- (UIViewController *)viewControllerForPresentingModalView {
    return self;
}

- (void)adManagerDidLoadAd:(UIView *)ad {
    [self showAdView:YES animated:YES];
}

- (void)adManagerDidFailWithError:(NSError *)error {
    [self showAdView:NO animated:YES];
}

@end
