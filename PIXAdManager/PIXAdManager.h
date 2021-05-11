//
//  PIXAdManager.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PIXAdManagerAdapter.h"

typedef enum {
    MediationPartnerNone = 0,
    MediationPartnerMoPub,
    MediationPartnerAdMob
} MediationPartner;


@class PIXAdManager;

// PIXAdManagerDelegate declaration
@protocol PIXAdManagerDelegate <NSObject>

@required

- (UIViewController *)viewControllerForPresentingModalView;
- (UIViewController *)viewControllerForAdView;

@optional

//- (void)adManagerDidLoadAd:(UIView *)adView;
//- (void)adManagerDidFailWithError:(NSError *)error;

@end

// PIXAdManager singleton class definition
@interface PIXAdManager : NSObject <PIXAdManagerAdapterDelegate>

@property (nonatomic, strong) UIView *adView;
@property (nonatomic, copy) NSString *mediationClass;
@property (nonatomic, weak) id<PIXAdManagerDelegate> delegate;

+ (PIXAdManager *)sharedManager;

- (void)initMediationPartner:(MediationPartner)partner withConfiguration:(NSDictionary *)configuration;
//- (void)loadAd;
//- (void)startRefreshing;
//- (void)stopRefreshing;

@end
