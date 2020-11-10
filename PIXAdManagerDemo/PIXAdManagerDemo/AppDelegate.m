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
    
    [[PIXAdManager sharedManager] initializeMediationPartner:MediationPartnerMoPub withConfiguration:nil];
    
    return YES;
}

@end
