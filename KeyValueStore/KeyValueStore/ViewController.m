//
//  ViewController.m
//  KeyValueStore
//
//  Created by Genius on 30/5/2017.
//  Copyright © 2017 Genius. All rights reserved.
//

#import "ViewController.h"
#import "CDKeyValueStore.h"


@interface ViewController ()
/** <#commment#> */
@property (nonatomic, strong) CDKeyValueStore *db;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.db = [[CDKeyValueStore alloc] initDBWithName:@"cd.db"];
    [self.db creatTableWithName:@"goodDetail"];
    [self.db putString:@"hello world" withId:@"123" fromTable:@"goodDetail"];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSString *str = [self.db getStringById:@"123" fromTable:@"goodDetail"];
    NSLog(@"%@", str);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
