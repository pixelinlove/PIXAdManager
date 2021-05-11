//
//  PIXAdManagerAdapterMoPub.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import "PIXAdManagerAdapter.h"
#import <MoPubSDK/MoPub.h>

NS_ASSUME_NONNULL_BEGIN

@interface PIXAdManagerAdapterMoPub : NSObject <PIXAdManagerAdapter, MPAdViewDelegate>

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong) MPAdView *adView;
@property (nonatomic, assign, readwrite) BOOL isInitialized;
@property (nonatomic, weak) id<PIXAdManagerAdapterDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
