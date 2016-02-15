//
//  TrelloView.m
//  SCTrelloNavigation
//
//  Created by Yh c on 15/11/5.
//  Copyright © 2015年 Yh c. All rights reserved.
//

#import "TrelloView.h"

@interface TrelloView ()
@end

@implementation TrelloView

#pragma mark - Init method
- (id)initWithFrame:(CGRect)frame dataSource:(id)dataSource {
    self = [super initWithFrame:frame];
    if(self) {
        self.userInteractionEnabled = YES;
        self.dataSource = dataSource;
        [self initSubViewsWithItems:[self listItemArrayFromDataSource]];
    }
    return self;
}

- (void)reloadData {
    NSMutableArray *items = [self listItemArrayFromDataSource];
    self.tabView.listItems = items;
    self.listView.listItems = items;
    [self animationBackToBriefMode];
    //...
    [self.tabView reloadData];
//    [self.listView reloadData];
}

- (NSMutableArray *)listItemArrayFromDataSource {
    NSInteger boardNumber = [self.dataSource respondsToSelector:@selector(numberForBoardsInTrelloView:)] ? [self.dataSource numberForBoardsInTrelloView:self] : 0;
    NSMutableArray *listItems = [NSMutableArray array];
    
    for(NSInteger i=0;i<boardNumber;i++) {
        SCTrelloBoardLevel level = [self.dataSource respondsToSelector:@selector(levelForRowsInTrelloView:atBoardIndex:)] ? [self.dataSource levelForRowsInTrelloView:self atBoardIndex:i] : SCTrelloBoardLevel1;
        NSInteger rowNumber = [self.dataSource respondsToSelector:@selector(numberForRowsInTrelloView:atBoardIndex:)] ? [self.dataSource numberForRowsInTrelloView:self atBoardIndex:i] : 0;
        NSString *title = [self.dataSource respondsToSelector:@selector(titleForBoardsInTrelloView:atBoardIndex:)] ? [self.dataSource titleForBoardsInTrelloView:self atBoardIndex:i] : @"DEFAULT";
        
        NSMutableArray *rowItemArray = [NSMutableArray array];
        if([self.dataSource respondsToSelector:@selector(itemForRowsInTrelloView:atBoardIndex:atRowIndex:)])
        {
            for(NSInteger j=0;j<rowNumber;j++)
            {
                //1
                [rowItemArray addObject:[self.dataSource itemForRowsInTrelloView:self atBoardIndex:i atRowIndex:j]];
            }
        }
        //2  
        [listItems addObject:[[TrelloListItem alloc]initWithTitle:title level:level rowNumber:rowNumber rowItems:rowItemArray]];
    }
    return listItems;
}

- (void)initSubViewsWithItems:(NSArray *)listItems {
    
    self.isFoldedMode = NO;
    // 顶部按钮
    self.tabView = [[TrelloListTabView alloc]initWithFrame:CGRectMake(0.0f, 20.0f, ScreenWidth, 100.0f) withListArray:listItems];
    self.tabView.userInteractionEnabled = YES;

    _tabView.backgroundColor = [UIColor clearColor];
    
    //[_tabView addSubview:effectView];
    [_tabView selectBoardAtIndex:0];
    
    __weak TrelloView *weakSelf = self;
    _tabView.HeaderDidSwitchCallBack = ^{
        [weakSelf switchMode];
    };
    [self addSubview:_tabView];
    
    // 数据所在tableView
    self.listView = [[TrelloListView alloc]initWithFrame:CGRectMake(30.0f, _tabView.bottom - 50.0f, ScreenWidth - 45.0f, self.height - _tabView.bottom + 80.0f)
                                                   index:0
                                               listArray:listItems];
    _tabView.listView = self.listView;
    _listView.userInteractionEnabled = YES;
    _listView.delegate = self;
    _listView.layer.masksToBounds = NO;
    _listView.clipsToBounds = NO;
    /**
     *  下边的Block没有调用
     */
    _listView.HeaderDidFoldedCallBack = ^{
        if(!weakSelf.isFoldedMode) {
            // 展开
            for(TrelloListItemView *view in weakSelf.tabView.listItemViews) {
                view.titlelabel.frame = CGRectZero;
            }
            [UIView animateWithDuration:0.3f animations:^{
                CGFloat nextX = 70.0f;
                
                weakSelf.tabView.contentSize = CGSizeMake(0.0f, 35.0f);
                weakSelf.tabView.frame = CGRectMake(0.0f, weakSelf.tabView.top, ScreenWidth, 35.0f);
                for(TrelloListItemView *view in weakSelf.tabView.listItemViews) {
                    view.frame = CGRectMake(nextX, 0.0f, 30.0f, 0.0f);
                    view.boardView.frame = CGRectMake(5.0f, 5.0f, 20.0f, 0.0f);
                    nextX += view.width;
                }
                CGRect frame = weakSelf.listView.frame;
                frame.origin.y = 20.0f;
                frame.size.height = weakSelf.height - 50.0f;
                weakSelf.listView.frame = frame;
                
            } completion:^(BOOL finished) {
                weakSelf.isFoldedMode = YES;
                weakSelf.tabView.isFoldedMode = YES;
                weakSelf.tabView.isBriefMode = NO;
                weakSelf.listView.isFoldMode = YES;
            }];
        } else {
            for(TrelloListItemView *view in weakSelf.tabView.listItemViews) {
                view.titlelabel.frame = CGRectZero;
            }
            [UIView animateWithDuration:0.3f animations:^{
                CGFloat nextX = 70.0f;
                
                weakSelf.tabView.contentSize = CGSizeMake(70.0f + weakSelf.tabView.listItems.count * 30.0f, 100.0f);
                weakSelf.tabView.frame = CGRectMake(0.0f, weakSelf.tabView.top, ScreenWidth, 100.0f);
                for(TrelloListItemView *view in weakSelf.tabView.listItemViews) {
                    view.frame = CGRectMake(nextX, 0.0f, 30.0f, 30.0f + view.item.heightLevel * 10.0f + 20.0f);
                    view.boardView.frame = CGRectMake(5.0f, 5.0f, 20.0f, view.item.heightLevel * 10.0f);
                    nextX += view.width;
                }
                CGRect frame = weakSelf.listView.frame;
                frame.origin.y = weakSelf.tabView.bottom - 50.0f;
                frame.size.height = weakSelf.height - weakSelf.tabView.bottom + 30.0f - 44;
                weakSelf.listView.frame = frame;
            } completion:^(BOOL finished) {
                weakSelf.isFoldedMode = NO;
                weakSelf.tabView.isFoldedMode = NO;
                weakSelf.tabView.isBriefMode = YES;
                weakSelf.listView.isFoldMode = NO;
            }];
        }
    };
    [self addSubview:_listView];
}

- (void)switchMode {
    if(_tabView.isBriefMode) {
        __weak TrelloView *weakSelf = self;
        [UIView animateWithDuration:0.3f animations:^{
            CGFloat scale = (ScreenWidth/4.5f)/30.0f;
            CGFloat nextX = 30.0f;
            
            weakSelf.tabView.contentSize = CGSizeMake(weakSelf.tabView.listItems.count * (ScreenWidth/4.5f) + 60.0f, 100.0f * scale);
            weakSelf.tabView.frame = CGRectMake(0.0f, weakSelf.tabView.top, ScreenWidth, 100.0f * scale);
            /**
             *  设置展开后顶部按钮间距
             */
            for(TrelloListItemView *view in weakSelf.tabView.listItemViews) {
                view.frame = CGRectMake(nextX, 0.0f, ScreenWidth/4.5f, 50.0f + view.item.heightLevel * 20.0f);
                view.titlelabel.frame = CGRectMake(ScreenWidth/27.0f, 10.0f, ScreenWidth/(4.5f * 1.5f), 25.0f);
                view.boardView.frame = CGRectMake(ScreenWidth/18.0f, view.titlelabel.bottom + 10.0f, ScreenWidth/10.0f, view.item.heightLevel * 15.0f);
                nextX += view.width;
            }
            weakSelf.listView.top = weakSelf.tabView.bottom - 130.0f;

        } completion:^(BOOL finished) {
            weakSelf.listView.isFoldMode = NO;
            weakSelf.isFoldedMode = NO;
            weakSelf.tabView.isBriefMode = NO;
        }];
        // 缩略图模式，变大
    }
    else {
        [self animationBackToBriefMode];
    }
}

- (void)animationBackToBriefMode {
    for(TrelloListItemView *view in _tabView.listItemViews) {
        view.titlelabel.frame = CGRectZero;
    }
    [UIView animateWithDuration:0.3f animations:^{
        CGFloat nextX = 70.0f;
        
        self.tabView.contentSize = CGSizeMake(70.0f + self.tabView.listItems.count * 30.0f, 100.0f);
        self.tabView.frame = CGRectMake(0.0f, self.tabView.top, ScreenWidth, 100.0f);
        for(TrelloListItemView *view in self.tabView.listItemViews) {
            view.frame = CGRectMake(nextX, 0.0f, 30.0f, 30.0f + view.item.heightLevel * 10.0f + 20.0f);
            view.boardView.frame = CGRectMake(5.0f, 5.0f, 20.0f, view.item.heightLevel * 10.0f);
            nextX += view.width;
        }
        self.listView.top = self.tabView.bottom - 50.0f;
        
    } completion:^(BOOL finished) {
        self.listView.isFoldMode = NO;
        self.isFoldedMode = NO;
        self.tabView.isBriefMode = YES;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if(scrollView == _listView) {
        NSInteger x = scrollView.contentOffset.x;
        NSInteger width = ScreenWidth - 45.0f;
        if(x % width == 0) {
            [_tabView selectBoardAtIndex:x/width];
        }
    }
}

@end
