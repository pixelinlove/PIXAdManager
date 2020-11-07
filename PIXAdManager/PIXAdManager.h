//
//  PIXAdManager.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    MediationPartnerNone = 0,
    MediationPartnerMoPub,
    MediationPartnerAdMob
} MediationPartner;

@interface PIXAdManager : NSObject

@property (nonatomic, strong) NSString *mediationClass;
@property (nonatomic, strong) UIView *adView;

+ (PIXAdManager *)sharedManager;

- (void)initializeMediationPartner:(MediationPartner)partner;
- (void)showMessage;

@end
