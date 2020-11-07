//
//  PIXAdManagerBaseAdapter.h
//  PIXAdManagerDemo
//
//  Created by Andrea Ottolina on 07/11/2020.
//  Copyright © 2020 Andrea Ottolina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PIXAdManagerAdapter.h"

NS_ASSUME_NONNULL_BEGIN

@interface PIXAdManagerBaseAdapter : NSObject<PIXAdManagerAdapter>

@property (nonatomic, copy, readonly) NSString *name;

@end

NS_ASSUME_NONNULL_END
