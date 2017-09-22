//
//  ViewController.m
//  SYMessageDemo
//
//  Created by ksw on 2017/9/22.
//  Copyright © 2017年 SunYong. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"

#import "SYMessage/SYMessage.h"



@interface ViewController (){
    
    Person *person;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    person = [Person new];
    
    
    [person addObserverSuny:self keyPath:@"age" block:^(id value) {
       
        NSLog(@"%@", value);
    }];
    
    person.age = @"10";
    
    
    
}





@end
