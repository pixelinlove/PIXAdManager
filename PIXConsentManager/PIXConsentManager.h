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

@property (nonatomic, assign, readonly) BOOL canRequestAds;
@property (nonatomic, assign, readonly) BOOL isConsentFlowInProgress;
@property (nonatomic, assign, readonly) BOOL didCompleteConsentFlow;
@property (nonatomic, copy, readonly, nullable) NSString *lastConsentStatus;

+ (instancetype)sharedManager;

- (void)startConsentFlowIfNeeded:(ConsentFlow)flow fromPresentingViewController:(UIViewController *)viewController completion:(nullable ConsentFlowCompletion)completion;

@end

NS_ASSUME_NONNULL_END
