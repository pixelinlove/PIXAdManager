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

@property (nonatomic, assign) MediationAdapter initialisedMediationAdapter;
@property (nonatomic, strong) id<PIXAdManagerAdapter> adapter;

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

- (void)initializeWithMediationAdapter:(MediationAdapter)adapter andConfiguration:(NSDictionary *)configuration {
    if (_initialisedMediationAdapter != 0) {
        //TODO: Raise error. Mediation Adapter already initialised and can't be changed.
        [NSException raise:NSInternalInconsistencyException
                    format:@"PIXAdManager can be initialised only once"];
        return;
    }
    _initialisedMediationAdapter = adapter;

    Class adapterClass = NSClassFromString([self classNameForAdapter:adapter]);
    if (adapterClass == nil) {
        //TODO: Raise error. Adapter Class Files couldn't be loaded.
        [NSException raise:NSInternalInconsistencyException
                    format:@"PIXAdManager can't find required adapter class"];
        return;
    }
    self.adapter = (id<PIXAdManagerAdapter>)[[adapterClass alloc] init];
    self.adapter.delegate = self;
    
    [self.adapter initWithConfiguration:configuration];
    [self.adapter adapterViewInit];
    
}

- (NSString *)classNameForAdapter:(MediationAdapter)adapter {
    NSString *className = nil;
    if (adapter == MediationAdapterAdMob) {
        className = @"PIXAdManagerAdapterAdMob";
    }
    if (adapter == MediationAdapterMoPub) {
        className = @"PIXAdManagerAdapterMoPub";
    }
    return className;
}

- (UIView *)adView {
    return (UIView *)self.adapter.adView;
}

- (void)adViewSetupSize {
    NSLog(@"[AdManger] > %@", NSStringFromSelector(_cmd));
    [self.adapter adapterViewAdjustSizeToSuperView];
}

- (void)loadAd {
    NSLog(@"[AdManger] > %@", NSStringFromSelector(_cmd));
    
    UIView *adView = self.adapter.adView;
    if (adView.superview == nil) {
        NSLog(@"[AdManager] > *** WARNING *** AdView needs to be attached to the superView before loading an ad");
    }
    
    [self.adapter adapterViewLoadAd];
}

- (void)pauseAd {
    NSLog(@"[AdManger] > %@", NSStringFromSelector(_cmd));
    [self.adapter adapterViewStopAd];
    [self.delegate adManagerDidPauseAd];
}

#pragma mark - Application notifications handling

- (void)applicationNotificationsEnabled:(BOOL)enabled {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    
    if (enabled) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationNotificationForAdManager:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationNotificationForAdManager:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationNotificationForAdManager:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
}

- (void)applicationNotificationForAdManager:(NSNotification *)notification {
    if (notification.name == UIApplicationDidBecomeActiveNotification) {
        NSLog(@"[AdManager] > Application Did Become Active - Banner will refresh");
        [self loadAd];
    }
    
    if (notification.name == UIApplicationWillResignActiveNotification) {
        NSLog(@"[AdManger] > Application Will Resign Active - Banner will hide");
        [self pauseAd];
    }
}

#pragma mark - Adapter delegate calls

- (void)adapterDidLoadAd:(nonnull UIView *)ad {
    [self.delegate adManagerDidLoadAd:ad];
}

- (void)adapterDidFailToLoadAdWithError:(nullable NSError *)error {
    [self.delegate adManagerDidFailWithError:error];
}

- (UIViewController *)viewControllerForAdapter {
    return [self.delegate viewControllerForAdManager];
}

#pragma mark - Debugging

- (void)debugEnabled:(BOOL)enabled {
    if (enabled) {
        [self.adapter adapterViewDebug];
    }
}

@end
