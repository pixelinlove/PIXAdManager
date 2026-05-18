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

typedef NS_ENUM(NSInteger, ConsentAdRequestStatus) {
    ConsentAdRequestStatusUnknown = 0,
    ConsentAdRequestStatusCanRequestAds,
    ConsentAdRequestStatusCannotRequestAds,
    ConsentAdRequestStatusError
};

@interface PIXConsentManager ()

@property (nonatomic, assign, readwrite) BOOL canRequestAds;
@property (nonatomic, assign) ConsentFlow currentConsentFlow;
@property (nonatomic, assign) ConsentAdRequestStatus adRequestStatus;
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

- (void)startConsentFlow:(ConsentFlow)flow completion:(ConsentFlowCompletion)completion {
    self.currentConsentFlow = flow;
    self.adRequestStatus = ConsentAdRequestStatusUnknown;
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

- (void)startNoConsentFlowWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowForNoConsentWithCompletion:completion];
}

- (void)completeConsentFlowForNoConsentWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowWithStatus:@"skipped"
                        adRequestStatus:ConsentAdRequestStatusCanRequestAds
                             completion:completion];
}

#pragma mark - Apple ATT Flow

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
        [self completeConsentFlowForATTWithAuthorizationStatus:0 completion:completion];
    }
}

- (void)completeConsentFlowForATTWithAuthorizationStatus:(ATTrackingManagerAuthorizationStatus)status completion:(ConsentFlowCompletion)completion {
    NSLog(@"[LogMe][ConsentManager][ATT] > status: %lu", (unsigned long)status);
    
    NSString *statusString = @"unavailable";
    ConsentAdRequestStatus adRequestStatus = ConsentAdRequestStatusCanRequestAds;
    
    if (!@available(iOS 14.5, *)) {
        [self completeConsentFlowWithStatus:statusString adRequestStatus:adRequestStatus completion:completion];
        return;
    }
    
    statusString = @"unknown";
    adRequestStatus = ConsentAdRequestStatusCannotRequestAds;
    switch (status) {
        case ATTrackingManagerAuthorizationStatusAuthorized:
            statusString = @"authorized";
            adRequestStatus = ConsentAdRequestStatusCanRequestAds;
            break;
            
        case ATTrackingManagerAuthorizationStatusDenied:
            statusString = @"denied";
            adRequestStatus = ConsentAdRequestStatusCanRequestAds;
            break;
            
        case ATTrackingManagerAuthorizationStatusRestricted:
            statusString = @"restricted";
            adRequestStatus = ConsentAdRequestStatusCanRequestAds;
            break;
            
        case ATTrackingManagerAuthorizationStatusNotDetermined:
            statusString = @"not determined";
            adRequestStatus = ConsentAdRequestStatusCannotRequestAds;
            break;
    }
    
    [self completeConsentFlowWithStatus:statusString adRequestStatus:adRequestStatus completion:completion];
}

#pragma mark - AdMob CMP Flow

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
            [self completeConsentFlowForAdMobCMPWithError:requestConsentError completion:completion];
        } else {
            [UMPConsentForm loadAndPresentIfRequiredFromViewController:presentingViewController
                                                     completionHandler:^(NSError *_Nullable loadAndPresentError) {
                [self completeConsentFlowForAdMobCMPWithError:loadAndPresentError completion:completion];
            }];
        }
    }];
}

- (void)completeConsentFlowForAdMobCMPWithError:(NSError *)error completion:(ConsentFlowCompletion)completion {
    if (error) {
        NSLog(@"[LogMe][ConsentManager] > AdMob CMP error: %@", error.localizedDescription);
        [self completeConsentFlowWithStatus:@"error"
                            adRequestStatus:ConsentAdRequestStatusError
                                 completion:completion];
        return;
    }
    
    BOOL canRequestAds = UMPConsentInformation.sharedInstance.canRequestAds;
    [self completeConsentFlowWithStatus:@"completed"
                        adRequestStatus:canRequestAds ? ConsentAdRequestStatusCanRequestAds : ConsentAdRequestStatusCannotRequestAds
                             completion:completion];
}

#pragma mark - Unknown Consent Flow

- (void)startUnknownConsentFlowWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowForUnknownFlowWithCompletion:completion];
}

- (void)completeConsentFlowForUnknownFlowWithCompletion:(ConsentFlowCompletion)completion {
    [self completeConsentFlowWithStatus:@"unknown"
                        adRequestStatus:ConsentAdRequestStatusCannotRequestAds
                             completion:completion];
}

#pragma mark - Shared Completion

- (void)completeConsentFlowWithStatus:(NSString *)statusString adRequestStatus:(ConsentAdRequestStatus)adRequestStatus completion:(ConsentFlowCompletion)completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.adRequestStatus = adRequestStatus;
        self.lastConsentStatus = statusString;
        self.canRequestAds = adRequestStatus == ConsentAdRequestStatusCanRequestAds;
        
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
