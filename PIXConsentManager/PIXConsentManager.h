//
//  PIXConsentManager.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 15/05/2026.
//  Copyright © 2026 Andrea Ottolina. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ConsentFlow) {
    ConsentFlowNone = 0,
    ConsentFlowATT,
    ConsentFlowAdMobCMP
};

typedef void (^ConsentFlowCompletion)(NSString *statusString);

@interface PIXConsentManager : NSObject

@property (nonatomic, weak, nullable) UIViewController *presentingViewController;
@property (nonatomic, assign, readonly) BOOL canRequestAds;

+ (instancetype)sharedManager;

- (void)startConsentFlow:(ConsentFlow)flow completion:(nullable ConsentFlowCompletion)completion;

@end

NS_ASSUME_NONNULL_END
