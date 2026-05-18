//
//  PIXConsentManager.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 15/05/2026.
//  Copyright © 2026 Andrea Ottolina. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    ConsentFlowNone = 0,
    ConsentFlowATT,
    ConsentFlowAdMobCMP
} ConsentFlow;

typedef void (^TrackingConsentStatusHandler)(NSString *statusString);

@interface PIXConsentManager : NSObject

+ (instancetype)sharedManager;

- (void)startConsentFlowType:(ConsentFlow)type withCompletion:(nullable TrackingConsentStatusHandler)completion;

@end

NS_ASSUME_NONNULL_END
