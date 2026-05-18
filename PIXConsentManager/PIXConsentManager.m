//
//  PIXConsentManager.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 15/05/2026.
//  Copyright © 2026 Andrea Ottolina. All rights reserved.
//

#import "PIXConsentManager.h"
#import <AppTrackingTransparency/AppTrackingTransparency.h>
#import <UserMessagingPlatform/UserMessagingPlatform.h>

typedef NS_ENUM(NSInteger, AdConsentStatus) {
    AdConsentStatusUnknown = 0,
    AdConsentStatusAllowed,
    AdConsentStatusNotAllowed,
    AdConsentStatusError
};

@interface PIXConsentManager ()

@property (nonatomic, assign, readwrite) BOOL canRequestAds;
@property (nonatomic, assign) ConsentFlow currentConsentFlow;
@property (nonatomic, assign) AdConsentStatus adConsentStatus;
@property (nonatomic, copy) NSString *lastConsentStatus;

@end

@implementation PIXConsentManager

+ (instancetype)sharedManager {
    static PIXConsentManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Entry point

// Resets normalized state, then routes to the selected consent provider flow.
- (void)startConsentFlow:(ConsentFlow)flow completion:(ConsentFlowCompletion)completion {
    self.currentConsentFlow = flow;
    self.adConsentStatus = AdConsentStatusUnknown;
    self.canRequestAds = NO;
    
    switch (flow) {
        case ConsentFlowNone:
            [self startNoConsentFlowWithCompletion:completion];
            break;
        case ConsentFlowATT:
            [self startATTConsentFlowWithCompletion:completion];
            break;
        case ConsentFlowAdMobCMP:
            [self startAdMobCMPConsentFlowWithCompletion:completion];
            break;
        default:
            [self startUnknownConsentFlowWithCompletion:completion];
            break;
    }
}

#pragma mark - No Consent Flow

// No consent provider is configured, so ads can be requested immediately.
- (void)startNoConsentFlowWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowForNoConsentWithCompletion:completion];
}

// Normalizes the no-consent flow as skipped and ad-requestable.
- (void)completeConsentFlowForNoConsentWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowWithStatus:@"skipped"
                        adConsentStatus:AdConsentStatusAllowed
                             completion:completion];
}

#pragma mark - Apple ATT Flow

// Requests ATT when needed, otherwise completes with the current ATT status.
- (void)startATTConsentFlowWithCompletion:(ConsentFlowCompletion)completion {
    if (@available(iOS 14.5, *)) {
        void (^requestTrackingAuthorization)(void) = ^{
            ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
            
            if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
                [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
                    [self completeConsentFlowForATTWithAuthorizationStatus:status completion:completion];
                }];
            } else {
                [self completeConsentFlowForATTWithAuthorizationStatus:status completion:completion];
            }
        };
        if ([NSThread isMainThread]) {
            requestTrackingAuthorization();
        } else {
            dispatch_async(dispatch_get_main_queue(), requestTrackingAuthorization);
        }
    } else {
        [self completeConsentFlowForUnavailableATTWithCompletion:completion];
    }
}

// Converts ATT authorization into the provider-agnostic ad request state.
- (void)completeConsentFlowForATTWithAuthorizationStatus:(ATTrackingManagerAuthorizationStatus)status completion:(ConsentFlowCompletion)completion {
    NSLog(@"[LogMe][ConsentManager][ATT] > status: %lu", (unsigned long)status);
    
    NSString *statusString = @"unknown";
    AdConsentStatus adConsentStatus = AdConsentStatusNotAllowed;
    switch (status) {
        case ATTrackingManagerAuthorizationStatusAuthorized:
            statusString = @"authorized";
            adConsentStatus = AdConsentStatusAllowed;
            break;
            
        case ATTrackingManagerAuthorizationStatusDenied:
            statusString = @"denied";
            adConsentStatus = AdConsentStatusAllowed;
            break;
            
        case ATTrackingManagerAuthorizationStatusRestricted:
            statusString = @"restricted";
            adConsentStatus = AdConsentStatusAllowed;
            break;
            
        case ATTrackingManagerAuthorizationStatusNotDetermined:
            statusString = @"not determined";
            adConsentStatus = AdConsentStatusNotAllowed;
            break;
    }
    
    [self completeConsentFlowWithStatus:statusString adConsentStatus:adConsentStatus completion:completion];
}

// Normalizes older iOS versions where ATT is unavailable.
- (void)completeConsentFlowForUnavailableATTWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowWithStatus:@"unavailable"
                        adConsentStatus:AdConsentStatusAllowed
                             completion:completion];
}

#pragma mark - AdMob CMP Flow

// Updates UMP consent info and presents the AdMob CMP form if required.
- (void)startAdMobCMPConsentFlowWithCompletion:(ConsentFlowCompletion)completion {
    UIViewController *presentingViewController = self.presentingViewController;
    if (!presentingViewController) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"PIXConsentManager requires presentingViewController to be set before starting ConsentFlowAdMobCMP."];
    }
    
    UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    parameters.tagForUnderAgeOfConsent = NO;
    
#if DEBUG
    UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
    debugSettings.geography = UMPDebugGeographyEEA;
    parameters.debugSettings = debugSettings;
#endif
    
    [UMPConsentInformation.sharedInstance requestConsentInfoUpdateWithParameters:parameters
                                                               completionHandler:^(NSError *_Nullable requestConsentError) {
        if (requestConsentError) {
            NSLog(@"[LogMe][ConsentManager] > AdMob CMP request error: %@", requestConsentError.localizedDescription);
            [self completeConsentFlowWithStatus:@"error"
                                adConsentStatus:AdConsentStatusError
                                     completion:completion];
        } else {
            [UMPConsentForm loadAndPresentIfRequiredFromViewController:presentingViewController
                                                     completionHandler:^(NSError *_Nullable loadAndPresentError) {
                if (loadAndPresentError) {
                    NSLog(@"[LogMe][ConsentManager] > AdMob CMP form error: %@", loadAndPresentError.localizedDescription);
                    [self completeConsentFlowWithStatus:@"error"
                                        adConsentStatus:AdConsentStatusError
                                             completion:completion];
                } else {
                    [self completeConsentFlowForAdMobCMPWithCompletion:completion];
                }
            }];
        }
    }];
}

// Reads UMP's final ad-request eligibility after the CMP flow succeeds.
- (void)completeConsentFlowForAdMobCMPWithCompletion:(ConsentFlowCompletion)completion {
    BOOL canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds;
    [self completeConsentFlowWithStatus:@"completed"
                        adConsentStatus:canRequestAds ? AdConsentStatusAllowed : AdConsentStatusNotAllowed
                             completion:completion];
}

#pragma mark - Unknown Consent Flow

// Unknown flows fail closed so ads are not requested accidentally.
- (void)startUnknownConsentFlowWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowForUnknownFlowWithCompletion:completion];
}

// Normalizes unsupported flow values.
- (void)completeConsentFlowForUnknownFlowWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowWithStatus:@"unknown"
                        adConsentStatus:AdConsentStatusNotAllowed
                             completion:completion];
}

#pragma mark - Shared Completion

// Stores the normalized result and invokes the caller on the main queue.
- (void)completeConsentFlowWithStatus:(NSString *)statusString adConsentStatus:(AdConsentStatus)adConsentStatus completion:(ConsentFlowCompletion)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.adConsentStatus = adConsentStatus;
        self.lastConsentStatus = statusString;
        self.canRequestAds = adConsentStatus == AdConsentStatusAllowed;
        
        NSLog(@"[LogMe][ConsentManager] > status: %@ > canRequestAds: %@", statusString, self.canRequestAds ? @"Y" : @"N");
        
        if (completion) {
            completion(statusString);
        }
    });
}

/*



- (void)checkPrivacyConsent:(ATTPromptType)type daysBetweenReminders:(int)days {
    if (@available(iOS 14.5, *)) {
        ATTrackingManagerAuthorizationStatus status = [ATTrackingManager trackingAuthorizationStatus];
        
        NSLog(@"[LogMe][ATTPrompt] > Prompt type: %u - AuthStatus: %lu", type, (unsigned long)status);
        if (status == ATTrackingManagerAuthorizationStatusNotDetermined) {
            switch (type) {
                case ATTPromptTypeNone:
                    break;
                case ATTPromptTypeDefault:
                    [self showConsentPromptATTDefault];
                    break;
                case ATTPromptTypeIntroAlert:
                    if ([self shouldShowConsentPromptATTWithIntroAlertAfterDays:days]) {
                        [self showConsentPromptATTWithIntroAlert];
                    };
                    break;
                case ATTPromptTypeFundingChoices:
                    [self showConsentPromptWithFundingChoices];
                    break;
                case ATTPromptTypeAdMobUMP:
                    [self showConsentPromptWithAdMobUMP];
                    break;
                default:
                    break;
            }
        }
    }
}

- (BOOL)shouldShowConsentPromptATTWithIntroAlertAfterDays:(int)days {
    // Check enough days have passed.
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDate *lastReminded = [defaults objectForKey:ATTPromptLastReminded];
    NSDate *today = [NSDate date];
    
    if ([today timeIntervalSinceDate:lastReminded] < days * SECONDS_IN_A_DAY) {
        // Do not display as not enough days have passed
        return NO;
    }
    
    // Save current date in case we need to check again
    [defaults setObject:today forKey:ATTPromptLastReminded];
    [defaults synchronize];
    
    return YES;
}

- (void)showConsentPromptATTDefault {
    // This method displays the ATT prompt immediately
    if (@available(iOS 14.5, *)) {
        [ATTrackingManager requestTrackingAuthorizationWithCompletionHandler:^(ATTrackingManagerAuthorizationStatus status) {
            [self logATTrackingManagerAuthorizationStatus:status];
        }];
    }
}

- (void)showConsentPromptATTWithIntroAlert {
    // This method displays the ATT prompt after a pre-request
    NSString *alertTitle = NSLocalizedString(@"att.preprompt.title", @"Label for the pre App Tracking Transparency prompt");
    NSString *alertMessage = NSLocalizedString(@"att.preprompt.message", @"Label for the main message displayed in the pre App Tracking Transparency prompt");
    NSString *okActionLabel = NSLocalizedString(@"att.preprompt.button.ok", @"Label for the OK button");
    NSString *laterActionLabel = NSLocalizedString(@"att.preprompt.button.later", @"Label for the remind-me-later button");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle message:alertMessage preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *laterAction = [UIAlertAction actionWithTitle:laterActionLabel style:UIAlertActionStyleCancel handler:nil];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okActionLabel
                                                       style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction *_Nonnull action) {
        [self showConsentPromptATTDefault];
    }];
    
    [alert addAction:laterAction];
    [alert addAction:okAction];
    
    alert.preferredAction = okAction;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showConsentPromptWithFundingChoices {
    // Create a UMPRequestParameters object.
    UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    // Set tag for under age of consent. Here NO means users are not under age.
    parameters.tagForUnderAgeOfConsent = NO;
    
    // Request an update to the consent information.
    [UMPConsentInformation.sharedInstance requestConsentInfoUpdateWithParameters:parameters
                                                               completionHandler:^(NSError *_Nullable error) {
        if (error) {
            // Handle the error.
        } else {
            // The consent information state was updated.
            // You are now ready to check if a form is available.
            UMPFormStatus formStatus = UMPConsentInformation.sharedInstance.formStatus;
            if (formStatus == UMPFormStatusAvailable) {
                [self loadFundingChoicesForm];
            }
        }
    }];
}

- (void)loadFundingChoicesForm {
    [UMPConsentForm loadWithCompletionHandler:^(UMPConsentForm *form, NSError *loadError) {
        if (loadError) {
            // Handle the error.
        } else {
            // Present the form. You can also hold on to the reference to present
            // later.
            if (UMPConsentInformation.sharedInstance.consentStatus == UMPConsentStatusRequired) {
                [form presentFromViewController:self
                              completionHandler:^(NSError *_Nullable dismissError) {
                    if (UMPConsentInformation.sharedInstance.consentStatus == UMPConsentStatusObtained) {
                        // App can start requesting ads.
                    }
                    if (@available(iOS 14.5, *)) {
                        [self logATTrackingManagerAuthorizationStatus:ATTrackingManager.trackingAuthorizationStatus];
                    }
                }];
            } else {
                // Keep the form available for changes to user consent.
            }
        }
    }];
}

- (void)showConsentPromptWithAdMobUMP {
    
    // Create a UMPRequestParameters object.
    UMPRequestParameters *parameters = [[UMPRequestParameters alloc] init];
    // Set tag for under age of consent. NO means users are not under age
    // of consent.
    parameters.tagForUnderAgeOfConsent = NO;
    
#if DEBUG
    UMPDebugSettings *debugSettings = [[UMPDebugSettings alloc] init];
//    debugSettings.testDeviceIdentifiers = @[ @"TEST-DEVICE-HASHED-ID" ];
    debugSettings.geography = UMPDebugGeographyEEA;
    parameters.debugSettings = debugSettings;
    [UMPConsentInformation.sharedInstance reset];
#endif
    
    __weak __typeof__(self) weakSelf = self;
    // Request an update for the consent information.
    [UMPConsentInformation.sharedInstance
     requestConsentInfoUpdateWithParameters:parameters
     completionHandler:^(NSError *_Nullable requestConsentError) {
        if (requestConsentError) {
            // Consent gathering failed.
            NSLog(@"Error: %@", requestConsentError.localizedDescription);
            return;
        }
        __strong __typeof__(self) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        
        [UMPConsentForm loadAndPresentIfRequiredFromViewController:strongSelf
                                                 completionHandler:^(NSError *loadAndPresentError) {
            if (loadAndPresentError) {
                // Consent gathering failed.
                NSLog(@"Error: %@", loadAndPresentError.localizedDescription);
                return;
            }
            
            // Consent has been gathered.
            __strong __typeof__(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            
            if (UMPConsentInformation.sharedInstance.canRequestAds) {
                [strongSelf startGoogleMobileAdsSDK];
            }
        }];
    }];
    
    // Check if you can initialize the Google Mobile Ads SDK in parallel
    // while checking for new consent information. Consent obtained in
    // the previous session can be used to request ads.
    if (UMPConsentInformation.sharedInstance.canRequestAds) {
        [self startGoogleMobileAdsSDK];
    }
}

- (void)startGoogleMobileAdsSDK {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // TODO: Initialise ad manager.
        // Initialize the Google Mobile Ads SDK.
        // [GADMobileAds.sharedInstance startWithCompletionHandler:nil];
        
        // TODO: Request an ad.
        // [GADInterstitialAd loadWithAdUnitID...];
    });
}


- (void)logATTrackingManagerAuthorizationStatus:(ATTrackingManagerAuthorizationStatus)status API_AVAILABLE(ios(14)) {
    NSLog(@"[LogMe][ATTPrompt] > status: %lu", (unsigned long)status);
    
    NSString *trackingLabel = @"unknown";
    if (status == ATTrackingManagerAuthorizationStatusAuthorized) {
        trackingLabel = @"authorized";
    }
    if (status == ATTrackingManagerAuthorizationStatusDenied) {
        trackingLabel = @"denied";
    }
    
    ///////////////////////
    // Begin Tracking Block
    NSArray *trackingData = @[ @"interface", @"attprompt", trackingLabel ];
    [FIRAnalytics logEventWithName:[trackingData componentsJoinedByString:@"_"] parameters:nil];
    // End Tracking Block
    ///////////////////////
}
#endif

 */

@end
