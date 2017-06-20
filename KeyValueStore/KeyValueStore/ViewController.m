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
    [self.db clearTable:@"goodDetail"];
    
    //
    NSMutableArray *arrayM = [NSMutableArray array];
    for (int i = 0; i < 10000; i++) {
        [arrayM addObject:@(i)];
    }
    
    [self.db transactionPutObject:arrayM intoTable:@"goodDetail"];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.db putNumber:@(123456) withId:@"1" intoTable:@"goodDetail"];
    NSArray *arrayM = [self.db getAllItemsFromTable:@"goodDetail"];
    
    NSLog(@"%@", arrayM);
}




@end
