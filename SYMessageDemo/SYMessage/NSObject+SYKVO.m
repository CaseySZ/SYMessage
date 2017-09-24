//
//  NSObject+SYKVO.m
//  KVO封装
//
//  Created by SunY on 2017/9/16.
//  Copyright © 2017年 EOC. All rights reserved.
//

#import "NSObject+SYKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>


#define KeyPathUnique(monitor, observer, path) ([NSString stringWithFormat:@"%p_%p_%@", monitor, observer,path])

static NSMutableSet *swizzledClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });
    
    return swizzledClasses;
}

@interface NSObject ()

//
@property (nonatomic, retain)NSMutableDictionary *sunyBlockInfoDict;

/*
 当观察者或者被观察者释放时 都要移除监听，不然会造成bug
 observerWithKeyPathAry 被监听者的观察者对象集合
 */
@property (nonatomic, retain)NSMutableArray *observerWithKeyPathAry;



/*
 当观察者或者被观察者释放时 都要移除监听，不然会造成bug
 beMonitorWithKeyPathAry 观察者（observer）的监听对象集合
 */
@property (nonatomic, retain)NSMutableArray *beMonitorWithKeyPathAry;

@end



@implementation NSObject (SYKVO)

static void* SunyKVOObserverContext = &SunyKVOObserverContext;

- (void)addObserverSuny:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(SYKVOBlock)block{
    
    if (!keyPath || !observer || !block) {
        return;
    }
    
    [observer swizzleDealloc];
    [self swizzleDealloc];
    
    // 保存block，触发监听的时候用 infoKey由self+observer+keypath组成，保证唯一性
    NSString *infoKey = KeyPathUnique(self, observer,keyPath);
    observer.sunyBlockInfoDict[infoKey] = block;
    
    NSValue *selfValue = [NSValue valueWithNonretainedObject:self];
    [observer.beMonitorWithKeyPathAry addObject:[NSDictionary dictionaryWithObject:selfValue forKey:keyPath]];
    
    NSValue *observerValue = [NSValue valueWithNonretainedObject:observer];
    [self.observerWithKeyPathAry addObject:[NSDictionary dictionaryWithObject:observerValue forKey:keyPath]];
    // 添加监听
    [self addObserver:observer forKeyPath:keyPath options:options context:SunyKVOObserverContext];
    
}

- (void)addObserverSuny:(NSObject *)observer keyPath:(NSString *)keyPath block:(SYKVOBlock)block{
    
    [self addObserverSuny:observer keyPath:keyPath options:NSKeyValueObservingOptionNew block:block];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    
    
    if (context == SunyKVOObserverContext) {
        
        NSString *infoKey = KeyPathUnique(object, self,keyPath);
        SYKVOBlock sykvoBlock = self.sunyBlockInfoDict[infoKey];
        if (sykvoBlock) {
            sykvoBlock(change[NSKeyValueChangeNewKey]);
        }
    }
}

#pragma mark - setter getter
// 保存执行的block
- (NSMutableDictionary*)sunyBlockInfoDict {
    
    NSMutableDictionary *sunyBlockInfoDict = objc_getAssociatedObject(self, @selector(sunyBlockInfoDict));
    if (!sunyBlockInfoDict) {
        sunyBlockInfoDict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, @selector(sunyBlockInfoDict), sunyBlockInfoDict, OBJC_ASSOCIATION_RETAIN);
    }
    return sunyBlockInfoDict;
    
}

- (void)setSunyBlockInfoDict:(NSMutableDictionary *)sunyBlockInfoDict{
    
    objc_setAssociatedObject(self, @selector(sunyBlockInfoDict), sunyBlockInfoDict, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableArray*)observerWithKeyPathAry {
    
    NSMutableArray *observerWithKeyPathAry = objc_getAssociatedObject(self, @selector(observerWithKeyPathAry));
    if (!observerWithKeyPathAry) {
        observerWithKeyPathAry = [NSMutableArray array];
        objc_setAssociatedObject(self, @selector(observerWithKeyPathAry), observerWithKeyPathAry, OBJC_ASSOCIATION_RETAIN);
    }
    return observerWithKeyPathAry;
    
}

- (void)setObserverWithKeyPathAry:(NSMutableArray *)observerWithKeyPathAry{
    
    objc_setAssociatedObject(self, @selector(observerWithKeyPathAry), observerWithKeyPathAry, OBJC_ASSOCIATION_RETAIN);
}

- (NSMutableArray*)beMonitorWithKeyPathAry {
    
    NSMutableArray *beMonitorWithKeyPathAry = objc_getAssociatedObject(self, @selector(beMonitorWithKeyPathAry));
    if (!beMonitorWithKeyPathAry) {
        beMonitorWithKeyPathAry = [NSMutableArray array];
        objc_setAssociatedObject(self, @selector(beMonitorWithKeyPathAry), beMonitorWithKeyPathAry, OBJC_ASSOCIATION_RETAIN);
    }
    return beMonitorWithKeyPathAry;
    
}

- (void)setBeMonitorWithKeyPathAry:(NSMutableArray *)beMonitorWithKeyPathAry{
    
    objc_setAssociatedObject(self, @selector(beMonitorWithKeyPathAry), beMonitorWithKeyPathAry, OBJC_ASSOCIATION_RETAIN);
}


#pragma mark - dealloc

- (void)swizzleDealloc{
    
    @synchronized (swizzledClasses()) {
        Class swizzleClass = [self class];
        NSString *className = NSStringFromClass(swizzleClass);
        if ([swizzledClasses() containsObject:className]) return;
        
        SEL deallocSelector = sel_registerName("dealloc");
        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
        
        
        id newDealloc = ^(__unsafe_unretained id self) {
            
            [self sunyDealloc];
            if (originalDealloc == NULL) {
                struct objc_super superInfo = {
                    .receiver = self,
                    .super_class = class_getSuperclass(swizzleClass)
                };
                
                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                originalDealloc(self, deallocSelector);
            }
        };
        
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
        
        if (!class_addMethod(swizzleClass, deallocSelector, newDeallocIMP, "v@:")) {
            
            Method deallocMethod = class_getInstanceMethod(swizzleClass, deallocSelector);
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);
        }
        
        [swizzledClasses() addObject:className];
        
    }
    
}


- (void)sunyDealloc{

    // 移除自己的监听对象
    for(NSDictionary *observerKeyDict in self.beMonitorWithKeyPathAry){
        
        [observerKeyDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            NSObject *oberver = self; // 观察者
            NSObject *beMonitor = [obj nonretainedObjectValue]; // 监听对象
            [beMonitor removeObserver:oberver forKeyPath:key context:SunyKVOObserverContext]; // 移除观察者
            
            // 从监听对象中，从observerWithKeyPathAry移除当前观察者即移除自己（self）
            NSMutableArray *removeAry = [NSMutableArray array];
            [beMonitor.observerWithKeyPathAry enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                // 当前观察者是self，则移除
                if([obj objectForKey:key] && [[obj objectForKey:key] nonretainedObjectValue] == oberver){
                    
                    [removeAry addObject:obj];
                }
                
            }];
            
            [removeAry enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [beMonitor.observerWithKeyPathAry removeObject:obj];
            }];
            
        }];
    }
    // 移除自己的观察者
    for(NSDictionary *observerKeyDict in self.observerWithKeyPathAry){
        
        [observerKeyDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            
            NSObject *observer = [obj nonretainedObjectValue];// 观察者
            NSObject *beMonitor = self; // 监听对象
            
            [beMonitor removeObserver:observer forKeyPath:key context:SunyKVOObserverContext];
            
            
            // 从观察者信息中 移除监听者信息（self）
            NSMutableArray *removeAry = [NSMutableArray array];
            [observer.beMonitorWithKeyPathAry enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                // 当前监听对象是自己self，则移除
                if([obj objectForKey:key] && [[obj objectForKey:key] nonretainedObjectValue] == beMonitor){
                    
                    [removeAry addObject:obj];
                }
                
            }];
            
            [removeAry enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [observer.beMonitorWithKeyPathAry removeObject:obj];
            }];
            
            
        }];
    }
    self.sunyBlockInfoDict = nil;
    self.observerWithKeyPathAry = nil;
    self.beMonitorWithKeyPathAry = nil;
    objc_removeAssociatedObjects(self);
}


@end

