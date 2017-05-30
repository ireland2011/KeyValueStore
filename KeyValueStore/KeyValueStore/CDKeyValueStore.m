//
//  CDKeyValueStore.m
//  KeyValueStore
//
//  Created by Genius on 30/5/2017.
//  Copyright © 2017 Genius. All rights reserved.
//

#import "CDKeyValueStore.h"
#import "FMDB.h"

#pragma mark - Macro

#ifdef DEBUG
#define debugLog(...)    NSLog(__VA_ARGS__)
#define debugMethod()    NSLog(@"%s", __func__)
#define debugError()     NSLog(@"Error at %s Line:%d", __func__, __LINE__)
#else
#define debugLog(...)
#define debugMethod()
#define debugError()
#endif


#define PATH_OF_DOCUMENT [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]


#define ID @"id"

#define JSON @"json"

#define CREATEDTime  @"createdTime"

#define CHECKTABLNAME if (![CDKeyValueStore checkTableName:tableName]) { \
return;\
}


#pragma mark - SQL
static NSString *const DEFAULT_DB_NAME = @"database.sqlite";

static NSString *const CREATE_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS %@ ( \
id TEXT NOT NULL, \
json TEXT NOT NULL, \
createdTime TEXT NOT NULL, \
PRIMARY KEY(id))\
";

static NSString *const UPDATE_ITEM_SQL = @"REPLACE INTO %@ (id, json, createdTime) values(?, ? ,?)";

static NSString *const QUERY_ITEM_SQL = @"SELECT json, createdTime from %@ where id = ? Limit 1";

static NSString *const SELECT_ALL_SQL = @"SELECT * from %@";

static NSString *const COUNT_ALL_SQL = @"SELECT count(*) as num from %@";

static NSString *const CLEAR_ALL_SQL = @"DELETE from %@";

static NSString *const DELETE_ITEM_SQL = @"DELETE from %@ where id = ?";

static NSString *const DELETE_ITEMS_SQL = @"DELETE from %@ where id in (%@)";

static NSString *const DELETE_ITEMS_WITH_PREFIX_SQL = @"DELETE from %@ where id like ? ";

static NSString *const DROP_TABLE_SQL = @"DROP TABLE '%@' ";





#pragma mark - CDKeyValueItem
@implementation CDKeyValueItem

- (NSString *)description {
    return [NSString stringWithFormat:@"itemId = %@, value = %@, timeStamp = %@", _itemId, _itemObject, _createdTime];
}

@end


#pragma mark - CDKeyValueStore
@interface CDKeyValueStore ()
/*
 To perform queries and updates on multiple threads, you'll want to use `FMDatabaseQueue`.
 在多线程环境中 执行查询和更新, 请使用FMDatabaseQueue
 
 Using a single instance of `<FMDatabase>` from multiple threads at once is a bad idea. It has always been OK to make a `<FMDatabase>` object *per thread*. Just don't share a single instance across threads, and definitely not across multiple threads at the same time.
 在多线程环境中使用FMDatabase单例 是不对的. 对一个线程中就要创建一个FMDatabase对象进行使用才是OK的.  不要跨线程共享FMDatabase单例
 
 Instead, use `FMDatabaseQueue`. Here's how to use it:
 FMDatabaseQueue使用方法
 
 1. 创建queue
 First, make your queue.
 FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:aPath];
 
 2. 使用
 Then use it like so:
 [queue inDatabase:^(FMDatabase *db) { 
        [db executeUpdate:"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]]; 
        [db executeUpdate:"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]]; 
        [db executeUpdate:"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];
        
        FMResultSet *rs = [db executeQuery:"select * from foo"];
        while ([rs next])
            { //… } }
 ];
 
 An easy way to wrap things up in a transaction can be done like this:
 [queue inTransaction:^(FMDatabase *db, BOOL *rollback) { 
         [db executeUpdate:"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
         [db executeUpdate:"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
         [db executeUpdate:"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];
         
         if (whoopsSomethingWrongHappened) {
            rollback = YES; 
            return;
         } // etc…
 
        [db executeUpdate:"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:4]];
    }
 ];
 
 `FMDatabaseQueue` will run the blocks on a serialized queue (hence the name of the class). 
 FMDatabaseQueue 运行在一个串行队列中.
 
 So if you call `FMDatabaseQueue`'s methods from multiple threads at the same time, they will be executed in the order they are received. 
 如果在同一时间在多个线程中调用FMDatabaseQueue方法, 他们会按照他们接受的顺序来执行.
 
 This way queries and updates won't step on each other's toes, and every one is happy.
 查询和更新 会按照顺序执行, 不会越俎代庖....
 

 */
@property (nonatomic, strong) FMDatabaseQueue *dbQueue;
@end

@implementation CDKeyValueStore

#pragma mark - 初始化方法
+ (BOOL)checkTableName:(NSString *)tableName {
    if (tableName == nil || tableName.length == 0 || [tableName rangeOfString:@" "].location != NSNotFound) {
        debugLog(@"ERROR, table name: %@ format error", tableName);
        return NO;
    }
    return YES;
}

- (instancetype)init {
    return [self initDBWithName:DEFAULT_DB_NAME];
}

- (instancetype)initDBWithName:(NSString *)dbName {
    self = [super init];
    if (self) {
        NSString *dbPath = [PATH_OF_DOCUMENT stringByAppendingPathComponent:dbName];
        debugLog(@"dbPath = %@", dbPath);
        if (_dbQueue) {
            [self close];
        }
        
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}

- (instancetype)initWithDBWithPath:(NSString *)dbPath {
    self = [super init];
    if (self) {
        debugLog(@"dbPath = %@", dbPath);
        if (_dbQueue) {
            [_dbQueue close];
        }
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
    }
    return self;
}

- (void)close {
    [_dbQueue close];
    _dbQueue = nil;
}


#pragma mark - 创建/删除/清空/检测 数据表
- (void)creatTableWithName:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return;
    }
    
    NSString *sql = [NSString stringWithFormat:CREATE_TABLE_SQL, tableName];
    __block BOOL result;
    /*Synchronously perform database operations on queue.*/
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    
    if (!result) {
        debugLog(@"ERROR, failed to creat table: %@", tableName);
    }
}

- (BOOL)isTableExists:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return NO;
    }
    
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db tableExists:tableName];
    }];
    
    if (!result) {
        debugLog(@"ERROR, table: %@ not exists in current DB", tableName);
    }
    
    return result;
}

- (void)clearTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return;
    }
    
    NSString *sql = [NSString stringWithFormat:CLEAR_ALL_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    
    if (!result) {
        debugLog(@"ERROR, failed to clear table: %@", tableName);
    }
}

- (void)dropTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return;
    }
    
    NSString *sql = [NSString stringWithFormat:DROP_TABLE_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    
    if (!result) {
        debugLog(@"ERROR, failed to drop table: %@", tableName);
    }
}

#pragma mark - 存取方法
//===========对象==========
- (void)putObject:(id)object withId:(NSString *)objectId intoTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return;
    }
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (error) {
        debugLog(@"ERROR, failed to get json data");
        return;
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSDate *creatTime = [NSDate date];
    NSString *sql = [NSString stringWithFormat:UPDATE_ITEM_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, objectId, jsonString, creatTime];
    }];
    
    if (!result) {
        debugLog(@"ERROR, failed to insert/replace into table: %@", tableName);
    }
}

- (id)getObjectById:(NSString *)objectId fromTable:(NSString *)tableName {
    CDKeyValueItem *item = [self getCDKeyValueItemByItem:objectId fromTable:tableName];
    if (item) {
        return item.itemObject;
    }else {
        return nil;
    }
}

- (CDKeyValueItem *)getCDKeyValueItemByItem:(NSString *)objectId fromTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return nil;
    }
    
    NSString *sql = [NSString stringWithFormat:QUERY_ITEM_SQL, tableName];
    __block NSString *json = nil;
    __block NSDate *createdTime = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql, objectId];
        if ([rs next]) {
            json = [rs stringForColumn:JSON];
            createdTime = [rs dateForColumn:CREATEDTime];
        }
        [rs close];
    }];
    
    if (json) {
        NSError *error;
        id result = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
        
        if (error) {
            debugLog(@"ERROR, failed to prase to json");
            return nil;
        }
        
        CDKeyValueItem *item = [CDKeyValueItem new];
        item.itemId = objectId;
        item.itemObject = result;
        item.createdTime = createdTime;
        
        return item;
    }else {
        return nil;
    }
}


//===========字符串==========
- (void)putString:(NSString *)string withId:(NSString *)stringId fromTable:(NSString *)tableName {
    if (!string) {
        debugLog(@"error, string is nil");
        return;
    }
    
    [self putObject:@[string] withId:stringId intoTable:tableName];
}

- (id)getStringById:(NSString *)stringId fromTable:(NSString *)tableName {
    NSArray *array = [self getObjectById:stringId fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    
    return nil;
}


//===========NSNumber==========
- (void)putNumber:(NSNumber *)number withId:(NSString *)numberId intoTable:(NSString *)tableName {
    if (!number) {
        debugLog(@"error, number is nil");
        return;
    }
    
    [self putObject:@[number] withId:numberId intoTable:tableName];
}

- (id)getNumber:(NSString *)numberId fromTable:(NSString *)tableName {
    NSArray *array = [self getObjectById:numberId fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    return nil;
}

//===========获取数据表中全部数据==========
- (NSArray *)getAllItemsFromTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return nil;
    }
    
    NSString *sql = [NSString stringWithFormat:SELECT_ALL_SQL, tableName];
    __block NSMutableArray *result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        while ([rs next]) {
            CDKeyValueItem *item = [CDKeyValueItem new];
            item.itemId = [rs stringForColumn:ID];
            item.itemObject = [rs stringForColumn:JSON];
            item.createdTime = [rs dateForColumn:CREATEDTime];
            
            [result addObject:item];
        }
        [rs close];
    }];
    
    NSError *error;
    for (CDKeyValueItem *item in result) {
        error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:[item.itemObject dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
        
        if (error) {
            debugLog(@"ERROR, failed to parse to json");
        }else {
            item.itemObject = object;
        }
    }
    
    return result;
}

//===========获取表中数据 个数==========
- (NSUInteger)getCountFromTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return 0;
    }
    
    NSString *sql = [NSString stringWithFormat:COUNT_ALL_SQL, tableName];
    __block NSInteger sum = 0;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        if ([rs next]) {
            sum = [rs unsignedLongLongIntForColumn:@"num"];
        }
        [rs close];
    }];
    
    return sum;
}


//===========删除表中数据==============
- (void)deleteObjectById:(NSString *)objectId fromTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return;
    }
    
    NSString *sql = [NSString stringWithFormat:DELETE_ITEM_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, objectId];
    }];
    
    if (!result) {
        debugLog(@"error, failed to delete item form table: %@", tableName);
    }
}

- (void)deleteObjectsByIdArray:(NSArray *)objectIdArray fromTable:(NSString *)tableName {
    CHECKTABLNAME
    
    NSMutableString *stringBuilder = [NSMutableString string];
    for (id objectId in objectIdArray) {
        NSString *item = [NSString stringWithFormat:@" '%@' ", objectId];
        if (stringBuilder.length == 0) {
            [stringBuilder appendString:item];
        }else {
            [stringBuilder appendString:@","];
            [stringBuilder appendString:item];
        }
    }
    
    NSString *sql = [NSString stringWithFormat:DELETE_ITEMS_SQL, tableName, stringBuilder];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    
    if (!result) {
        debugLog(@"error, failed to delete items by ids from table: %@", tableName);
    }
    
}

- (void)deleteObjectsByIdPrefix:(NSString *)objectIdPrefix fromTable:(NSString *)tableName {
    if (![CDKeyValueStore checkTableName:tableName]) {
        return;
    }
    
    NSString *sql = [NSString stringWithFormat:DELETE_ITEMS_WITH_PREFIX_SQL, tableName];
    NSString *prefixArgument = [NSString stringWithFormat:@"%@%%", objectIdPrefix];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, prefixArgument];
    }];
    if (!result) {
        debugLog(@"error, failed to delete items by id prefix from table: %@", tableName);
    }
}



@end


















