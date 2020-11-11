//
//  AppDelegate.m
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 09/03/2018.
//  Copyright © 2018 Andrea Ottolina. All rights reserved.
//

#import "AppDelegate.h"
#import "PIXAdManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSDictionary *testMopubConfiguration = @{@"adUnitID": @"0ac59b0996d947309c33f59d6676399f"};
    [[PIXAdManager sharedManager] initializeMediationPartner:MediationPartnerMoPub withConfiguration:testMopubConfiguration];
    
//    AdMob requires the App Unit ID to be set in the info.plist key "GADApplicationIdentifier"
//    NSDictionary *testAdmobConfiguration = @{@"appUnitID": @"ca-app-pub-3940256099942544~1458002511",
//                                             @"adUnitID": @"ca-app-pub-3940256099942544/2934735716"};
//    [[PIXAdManager sharedManager] initializeMediationPartner:MediationPartnerAdMob withConfiguration:testAdmobConfiguration];
    
    return YES;
}

@end
