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

/**
 App-level consent coordinator.

 Intended flow for ad-supported apps:
 1. Call startConsentFlowIfNeeded:fromPresentingViewController:completion: from a visible view controller.
 2. In the completion, check canRequestAds.
 3. Initialize ad SDKs and load ads only when canRequestAds is YES.

 The manager owns consent state for the current app session. View controllers should not keep their own
 "did start consent" flag; repeated calls are safe and will not start duplicate consent UI.
 */
@interface PIXConsentManager : NSObject

/// YES only after the selected consent flow allows ad requests.
@property (nonatomic, assign, readonly) BOOL canRequestAds;

/// YES while a consent provider request or form presentation is active.
@property (nonatomic, assign, readonly) BOOL isConsentFlowInProgress;

/// YES after the manager has reached a terminal consent result during the current app session.
/// Retryable provider/presentation failures leave this NO so a later visible controller can try again.
@property (nonatomic, assign, readonly) BOOL didCompleteConsentFlow;

/// Last normalized consent result, useful for logging and diagnostics.
@property (nonatomic, copy, readonly, nullable) NSString *lastConsentStatus;

+ (instancetype)sharedManager;

/**
 Starts the selected flow only if consent has not already completed.

 Must be called with a currently visible presenting view controller when the flow can present UI
 (for example ConsentFlowAdMobCMP). The manager keeps a weak reference to the latest presenter while
 a flow is in progress; if another visible controller calls this method before completion, that caller
 becomes the active continuation. This is "latest caller wins" by design, so stale view controllers do
 not continue ad setup after navigation. Only the latest completion block is retained while a flow is
 active.

 If a provider or presentation failure prevents a terminal consent result, the completion receives
 "error", canRequestAds remains NO, didCompleteConsentFlow remains NO, and the next visible caller can
 retry with this same method.

 Completion is invoked on the main thread.
 */
- (void)startConsentFlowIfNeeded:(ConsentFlow)flow fromPresentingViewController:(UIViewController *)viewController completion:(nullable ConsentFlowCompletion)completion;

@end

NS_ASSUME_NONNULL_END
