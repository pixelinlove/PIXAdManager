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
    
    NSDictionary *mopubConfiguration = @{@"adUnitID": @"5d0ff333b3a745118af4429d08d362be"};
    [[PIXAdManager sharedManager] initializeMediationPartner:MediationPartnerMoPub withConfiguration:mopubConfiguration];
    
//    NSDictionary *admobConfiguration = @{@"adUnitID": @"5d0ff333b3a745118af4429d08d362be"};
//    [[PIXAdManager sharedManager] initializeMediationPartner:MediationPartnerAdMob withConfiguration:admobConfiguration];
    
    return YES;
}

@end
