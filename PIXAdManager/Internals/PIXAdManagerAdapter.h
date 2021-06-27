//
//  PIXAdManagerAdapter.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PIXAdManagerAdapterDelegate <NSObject>

@required
- (UIViewController *)viewControllerForAdapter;

@optional
- (void)adapterDidLoadAd:(nonnull UIView *)ad;
- (void)adapterDidFailToLoadAdWithError:(nullable NSError *)error;

@end

@protocol PIXAdManagerAdapter <NSObject>

@required

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) UIView *adView;
@property (nonatomic, assign, readonly) BOOL isInitialized;
@property (nonatomic, weak) id<PIXAdManagerAdapterDelegate> delegate;

- (void)initWithConfiguration:(NSDictionary *)configuration;
- (void)adapterViewInit;
- (void)adapterViewAdjustSizeToSuperView;
- (void)adapterViewLoadAd;
- (void)adapterViewStopAd;

@end

NS_ASSUME_NONNULL_END
