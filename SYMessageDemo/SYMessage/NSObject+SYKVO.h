//
//  NSObject+SYKVO.h
//  KVO封装
//
//  Created by SunY on 2017/9/16.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import <Foundation/Foundation.h>


#define SYKVOOptionInitAndNew (NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)

typedef void(^SYKVOBlock)(id newValue);

@interface NSObject (SYKVO)

- (void)addObserverSuny:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(SYKVOBlock)block;

// 默认是NSKeyValueObservingOptionNew
- (void)addObserverSuny:(NSObject *)observer keyPath:(NSString *)keyPath block:(SYKVOBlock)block;


@end

