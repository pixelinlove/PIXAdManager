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
- (UIViewController *)viewControllerForPresentingModalView;

@optional
- (void)adapterDidLoadAd:(nonnull UIView *)ad;
- (void)adapterDidFailToLoadAdWithError:(nullable NSError *)error;

@end

@protocol PIXAdManagerAdapter <NSObject>

@required

@property (nonatomic, copy, readonly) NSString *adapterName;
@property (nonatomic, weak) id<PIXAdManagerAdapterDelegate> adapterDelegate;
@property (nonatomic, strong, readonly) UIView *adapterAdView;

- (void)initializeWithConfiguration:(NSDictionary *)configuration;
- (void)loadAd;
- (void)startRefreshing;
- (void)stopRefreshing;

@end

NS_ASSUME_NONNULL_END
