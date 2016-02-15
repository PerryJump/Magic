//
//  DBManager.m
//  LimitFreeProject
//


#import "DBManager.h"
#import "NewDataModel.h"

//全局变量
NSString * const kLZXFavorite = @"favorites";
NSString * const kLZXDownloads = @"downloads";
NSString * const kLZXBrowses = @"browese";

/*
 数据库
 1.导入 libsqlite3.dylib
 2.导入 fmdb
 3.导入头文件
 fmdb 是对底层C语言的sqlite3的封装
 
 */
@implementation DBManager
{
    //数据库对象
    FMDatabase *_database;
}

+ (DBManager *)sharedManager {
    static DBManager *manager = nil;
    @synchronized(self) {//同步 执行 防止多线程操作
        if (manager == nil) {
            manager = [[DBManager alloc] init];
        }
    }
    return manager;
}
- (id)init {
    if (self = [super init]) {
        //1.获取数据库文件app.db的路径
        NSString *filePath = [self getFileFullPathWithFileName:@"app.db"];
        //2.创建database
        _database = [[FMDatabase alloc] initWithPath:filePath];
        //3.open
        //第一次 数据库文件如果不存在那么 会创建并且打开
        //如果存在 那么直接打开
        if ([_database open]) {
            NSLog(@"数据库打开成功");
            //创建表 不存在 则创建
            [self creatTable];
        }else {
            NSLog(@"database open failed:%@",_database.lastErrorMessage);
        }
    }
    return self;
}
#pragma mark - 创建表
- (void)creatTable {
    //字段: 应用名 应用id 当前价格 最后价格 icon地址 记录类型 价格类型
    NSString *sql = @"create table if not exists appInfo(serial integer  Primary Key Autoincrement,appName Varchar(1024),appId Varchar(1024),currentPrice Varchar(1024),lastPrice Varchar(1024),iconUrl Varchar(1024),recordType Varchar(1024),priceType Varchar(1024),loveCount Varchar(1024),downCount Varchar(1024))";
    //创建表 如果不存在则创建新的表
    BOOL isSuccees = [_database executeUpdate:sql];
    if (!isSuccees) {
        NSLog(@"creatTable error:%@",_database.lastErrorMessage);
    }
}
#pragma mark - 获取文件的全路径

//获取文件在沙盒中的 Documents中的路径
- (NSString *)getFileFullPathWithFileName:(NSString *)fileName {
    NSString *docPath = [NSHomeDirectory() stringByAppendingFormat:@"/Documents"];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:docPath]) {
        //文件的全路径
        return [docPath stringByAppendingFormat:@"/%@",fileName];
    }else {
        //如果不存在可以创建一个新的
        NSLog(@"Documents不存在");
        return nil;
    }
}


//增加 数据 收藏/浏览/下载记录
//存储类型 favorites downloads browses
- (void)insertModel:(id)model recordType:(NSString *)type {
    newDatasModel *appModel = (newDatasModel *)model;
    
    if ([self isExistAppForAppId:appModel.id recordType:type]) {
        NSLog(@"this app has  recorded");
        return;
    }
    NSString *sql = @"insert into appInfo(appName,appId,currentPrice,lastPrice,iconUrl,recordType,priceType,loveCount, downCount) values (?,?,?,?,?,?,?,?,?)";
    BOOL isSuccess = [_database executeUpdate:sql,appModel.name,appModel.id,appModel.pic_1080,appModel.source,appModel.info,type,appModel.user_id, appModel.desp, appModel.type];
    if (!isSuccess) {
        NSLog(@"insert error:%@",_database.lastErrorMessage);
    }
}
//查找所有插入类型
- (NSArray *)searchAllType {
    
    NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
    NSString *sql = @"select *from appInfo";
    //NSString *sql1 = @"select recordType from appInfo";
    FMResultSet *resultSet = [_database executeQuery:sql];
    //FMResultSet *resultSet1 = [_database executeQuery:sql1];
    while (resultSet.next) {
        [tmpArray addObject:[resultSet stringForColumn:@"recordType"]];
    }
    return tmpArray;
}

//删除指定的应用数据 根据指定的类型
- (void)deleteModelForAppId:(NSString *)appId recordType:(NSString *)type {
    NSString *sql = @"delete from appInfo where appId = ? and recordType = ?";
    BOOL isSuccess = [_database executeUpdate:sql,appId,type];
    if (!isSuccess) {
        NSLog(@"delete error:%@",_database.lastErrorMessage);
    }
}

- (void)deleteModelForAppId:(NSString *)appId{
    NSString *sql = @"delete from appInfo where appId = ?";
    BOOL isSuccess = [_database executeUpdate:sql,appId];
    if (!isSuccess) {
        NSLog(@"delete error:%@",_database.lastErrorMessage);
    }
}

//根据指定类型  查找所有的记录
//根据记录类型 查找 指定的记录
- (NSArray *)readModelsWithRecordType:(NSString *)type{
    
    NSString *sql = @"select * from appInfo where  recordType = ?";
    FMResultSet * rs = [_database executeQuery:sql,type];

    NSMutableArray *arr = [NSMutableArray array];
    //遍历集合
    while ([rs next]) {
        //把查询之后结果 放在model
        newDatasModel *appModel = [[newDatasModel alloc] init];
        appModel.name = [rs stringForColumn:@"appName"];
        appModel.id = [rs stringForColumn:@"appId"];
        appModel.pic_1080 = [rs stringForColumn:@"currentPrice"];
        appModel.source = [rs stringForColumn:@"lastPrice"];
        appModel.info = [rs stringForColumn:@"iconUrl"];
        appModel.user_id = [rs stringForColumn:@"priceType"];
        appModel.desp = [rs stringForColumn:@"loveCount"];
        appModel.type = [rs stringForColumn:@"downCount"];
        //放入数组
        [arr addObject:appModel];
    }
    return arr;
}
//根据指定的类型 返回 这条记录在数据库中是否存在
- (BOOL)isExistAppForAppId:(NSString *)appId recordType:(NSString *)type {
    NSString *sql = @"select * from appInfo where appId = ? and recordType = ?";
    FMResultSet *rs = [_database executeQuery:sql,appId,type];
    if ([rs next]) {//查看是否存在 下条记录 如果存在 肯定 数据库中有记录
        return YES;
    }else{
        return NO;
    }
}
//根据 指定的记录类型  返回 记录的条数
- (NSInteger)getCountsFromAppWithRecordType:(NSString *)type {
    NSString *sql = @"select count(*) from appInfo where recordType = ?";
    FMResultSet *rs = [_database executeQuery:sql,type];
    NSInteger count = 0;
    while ([rs next]) {
        //查找 指定类型的记录条数
        count = [[rs stringForColumnIndex:0] integerValue];
    }
    return count;
}


@end
