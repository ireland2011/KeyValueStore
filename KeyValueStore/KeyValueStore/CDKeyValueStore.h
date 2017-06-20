//
//  CDKeyValueStore.h
//  KeyValueStore
//
//  Created by Genius on 30/5/2017.
//  Copyright © 2017 Genius. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CDKeyValueItem : NSObject

/** key */
@property (nonatomic, strong) NSString *itemId;
/** value */
@property (nonatomic, strong) id itemObject;
/** date */
@property (nonatomic, strong) NSDate *createdTime;

@end



@interface CDKeyValueStore : NSObject

#pragma mark - 初始化方法
//> 数据库 <- 数据库名
- (instancetype)initDBWithName:(NSString *)dbName;

//> 数据库 <- 数据库路径
- (instancetype)initWithDBWithPath:(NSString *)dbPath;

//> 数据表 <- 表名
- (void)creatTableWithName:(NSString *)tableName;

//> 数据表 是否存在
- (BOOL)isTableExists:(NSString *)tableName;

//> 数据表 清空
- (void)clearTable:(NSString *)tableName;

//> 数据表 删除
- (void)dropTable:(NSString *)tableName;

//> 数据库 关闭
- (void)close;


#pragma mark - 存取方法
//===========对象==========
- (void)putObject:(id)object withId:(NSString *)objectId intoTable:(NSString *)tableName;

- (id)getObjectById:(NSString *)objectId fromTable:(NSString *)tableName;

- (CDKeyValueItem *)getCDKeyValueItemByItem:(NSString *)objectId fromTable:(NSString *)tableName;

//===========字符串==========
- (void)putString:(NSString *)string withId:(NSString *)stringId fromTable:(NSString *)tableName;

- (id)getStringById:(NSString *)stringId fromTable:(NSString *)tableName;


//===========NSNumber==========
- (void)putNumber:(NSNumber *)number withId:(NSString *)numberId intoTable:(NSString *)tableName;

- (id)getNumber:(NSString *)numberId fromTable:(NSString *)tableName;

//===========获取数据表中全部数据==========
- (NSArray *)getAllItemsFromTable:(NSString *)tableName;

//===========获取表中数据 个数==========
- (NSUInteger)getCountFromTable:(NSString *)tableName;


//===========删除表中数据==============
- (void)deleteObjectById:(NSString *)objectId fromTable:(NSString *)tableName;

- (void)deleteObjectsByIdArray:(NSArray *)objectIdArray fromTable:(NSString *)tableName;

- (void)deleteObjectsByIdPrefix:(NSString *)objectIdPrefix fromTable:(NSString *)tableName;


//===========事务 批量更新数据==============
- (void)transactionPutObject:(NSArray *)objectArray intoTable:(NSString *)tableName;










@end
