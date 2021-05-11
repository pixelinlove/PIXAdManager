//
//  PIXAdManager.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManager.h"
#import "PIXAdManagerAdapter.h"

@interface PIXAdManager ()

@property (nonatomic, assign) MediationPartner initialisedMediationPartner; //current Mediation partner
@property (nonatomic, strong) id<PIXAdManagerAdapter> adapter;
@property (nonatomic, strong) NSLayoutConstraint *adViewBottomLayoutContraint;

@end

@implementation PIXAdManager

+ (PIXAdManager *)sharedManager {
    static PIXAdManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (void)initMediationPartner:(MediationPartner)partner withConfiguration:(NSDictionary *)configuration {
    if (_initialisedMediationPartner != 0) {
        //TODO: Raise error. Mediation Partner already initialised and can't be changed.
        [NSException raise:NSInternalInconsistencyException
                    format:@"PIXAdManager can be initialised only once"];
        return;
    }
    _initialisedMediationPartner = partner;

    Class adapterClass = NSClassFromString([self classNameForPartner:partner]);
    if (adapterClass == nil) {
        //TODO: Raise error. Adapter Class Files couldn't be loaded.
        [NSException raise:NSInternalInconsistencyException
                    format:@"PIXAdManager can't find required adapter class"];
        return;
    }
    self.adapter = (id<PIXAdManagerAdapter>)[[adapterClass alloc] init];
    self.adapter.delegate = self;
    
    [self.adapter initWithConfiguration:configuration];
    [self.adapter adViewInit];
    
    [self initAppNotifications];
}

- (NSString *)classNameForPartner:(MediationPartner)partner {
    NSString *className = nil;
    if (partner == MediationPartnerAdMob) {
        className = @"PIXAdManagerAdapterAdMob";
    }
    if (partner == MediationPartnerMoPub) {
        className = @"PIXAdManagerAdapterMoPub";
    }
    return className;
}

- (void)initAppNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self.adapter.delegate
                                             selector:@selector(appNotificationForAdView:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.adapter.delegate
                                             selector:@selector(appNotificationForAdView:)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.adapter.delegate
                                             selector:@selector(appNotificationForAdView:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void)appNotificationForAdView:(NSNotification *)notification {
    if (notification.name == UIApplicationDidBecomeActiveNotification) {
        NSLog(@"[AdManager] > Application Did Become Active - Banner will refresh");
        [self resumeRequest];
    }
    
    if (notification.name == UIApplicationWillResignActiveNotification) {
        NSLog(@"[AdManger] > Application Will Resign Active - Banner will hide");
        [self pauseRequest];
    }
}

- (void)resumeRequest {
    NSLog(@"[AdManger] > %@", NSStringFromSelector(_cmd));
    
    // Check if adView is attached to the superview. If not, set it up.
    // This is because the frame and constraints should be setup only after viewDidAppear.
    UIView *adView = self.adapter.adView;
    if (adView.superview == nil) {
        [self adViewSetupView];
    }
    
    [self.adapter adViewLoadAd];
}

- (void)pauseRequest {
    [self.adapter adViewStopAd];
    [self showAdView:NO animated:NO];
}

- (void)adViewSetupView {
    NSLog(@"[AdManger] > %@", NSStringFromSelector(_cmd));
    
    UIView *adView = self.adapter.adView;
    
    adView.translatesAutoresizingMaskIntoConstraints = NO;
    adView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    UIViewController *viewControllerForAdView = [self.delegate viewControllerForAdView];
    [viewControllerForAdView.view addSubview:adView];
    
    [self.adapter adViewAdjustSizeToView:viewControllerForAdView.view];
    [adView.centerXAnchor constraintEqualToAnchor:viewControllerForAdView.view.centerXAnchor].active = YES;
    if (!self.adViewBottomLayoutContraint) {
        self.adViewBottomLayoutContraint = [adView.bottomAnchor constraintEqualToAnchor:viewControllerForAdView.bottomLayoutGuide.topAnchor];
        self.adViewBottomLayoutContraint.active = YES;
    }
    [adView layoutIfNeeded];
    
    [self showAdView:NO animated:NO];
    
}

- (void)showAdView:(BOOL)show animated:(BOOL)animated {
    NSLog(@"[LogMe][MoPub|AdMob] > %@", NSStringFromSelector(_cmd));
    
    UIView *adView = self.adapter.adView;
    
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

- (void)adapterDidLoadAd:(nonnull UIView *)ad {
    [self showAdView:YES animated:YES];
}

- (void)adapterDidFailToLoadAdWithError:(nullable NSError *)error {
    [self showAdView:NO animated:YES];
}

- (UIViewController *)viewControllerForPresentingModalView {
    return [self.delegate viewControllerForPresentingModalView];
}

@end
