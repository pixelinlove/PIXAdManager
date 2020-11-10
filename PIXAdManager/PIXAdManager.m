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

- (void)initializeMediationPartner:(MediationPartner)partner withConfiguration:(NSDictionary *)configuration {
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
    self.adapter.adapterDelegate = self;
    
    [self.adapter initializeWithConfiguration:configuration];
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

- (void)loadAd {
    [self.adapter loadAd];
}

- (void)startRefreshing {
    [self.adapter startRefreshing];
}

- (void)stopRefreshing {
    [self.adapter stopRefreshing];
}

- (UIView *)adView {
    return self.adapter.adapterAdView;
}

- (UIViewController *)viewControllerForPresentingModalView {
    return [self.delegate viewControllerForPresentingModalView];
}

- (void)adapterDidLoadAd:(UIView *)ad {
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    [self.delegate adManagerDidLoadAd:ad];
}

- (void)adapterDidFailToLoadAdWithError:(NSError *)error {
    NSLog(@"[AdManager] > %@", NSStringFromSelector(_cmd));
    [self.delegate adManagerDidFailWithError:error];
}

@end
