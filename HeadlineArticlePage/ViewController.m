//
//  ViewController.m
//  HeadlineArticlePage
//
//  Created by Chris on 16/7/18.
//  Copyright © 2016年 All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, retain) UIScrollView *scrollView;
@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UITableView *tableView;
@end

@implementation ViewController

/**
 *  原理：scrollView嵌套scrollView，用户滑动内层scrollView，当内层scrollView滚动到顶（底）时，继续滑动就会令外层scrollView滚动。
 
 *  仿今日头条文章页的实现方式：
 *  1. 通过 UIWebView 加载网页
 *  2. 通过 UITableView 加载评论等native元素
 *  3. 通过 UIScrollView 加载上述的 webView 及 scrollView
 *  4. 滚动实现：设置webView的高度与其contentSize的高度一致，通过scrollView实现网页内容滚动；
       然后在webView下面将tableView加入到scrollView中，高度为一屏的高度；
       滚动时，当webView的左上角刚好与屏幕的左上角重合，开启webView的自身滚动功能，否则关闭其自身滚动功能。
 */

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.webView];
    [self.scrollView addSubview:self.tableView];
    
    [self loadWebPage];
    [self addKVO];
}

- (void)loadWebPage
{
    NSURL *url            = [NSURL URLWithString:@"http://news.qq.com/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

- (void)dealloc
{
    [self removeKVO];
}

#pragma mark - KVO
- (void)addKVO
{
    [self.webView addObserver:self forKeyPath:@"scrollView.contentSize" options:NSKeyValueObservingOptionNew context:nil];
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)removeKVO
{
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.webView removeObserver:self forKeyPath:@"scrollView.contentSize"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (object == self.webView && [keyPath isEqualToString:@"scrollView.contentSize"]) {
        [self refreshUI];
        NSLog(@"contentSize:%@", NSStringFromCGSize(self.scrollView.contentSize));
    }
    
    if (object == self.scrollView && [keyPath isEqualToString:@"contentOffset"]) {
        CGFloat delta = self.scrollView.contentOffset.y;
        if (delta >= self.webView.scrollView.contentSize.height) {
            self.tableView.scrollEnabled = YES;
        }
        else {
            self.tableView.scrollEnabled = NO;
        }
    }
}

- (void)refreshUI
{
    CGFloat height = self.webView.scrollView.contentSize.height;
    
    CGSize size                 = self.scrollView.contentSize;
    size.height                 = height + self.tableView.bounds.size.height;
    self.scrollView.contentSize = size;
    
    CGRect frame       = self.webView.frame;
    frame.size.height  = height;
    self.webView.frame = frame;
    
    frame                 = self.tableView.frame;
    frame.origin.y        = height;
    self.tableView.frame  = frame;
    self.tableView.hidden = NO;
}

#pragma mark - getter
- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        CGRect frame       = self.view.bounds;
        frame.origin.y     = 20.f;
        frame.size.height -= 20.f;
        _scrollView        = [[UIScrollView alloc] initWithFrame:frame];
    }
    return _scrollView;
}

- (UIWebView *)webView
{
    if (!_webView) {
        _webView                          = [[UIWebView alloc] initWithFrame:self.scrollView.bounds];
        _webView.scalesPageToFit          = YES;
        _webView.scrollView.scrollEnabled = NO;    }
    return _webView;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        CGRect frame          = self.scrollView.bounds;
        _tableView            = [[UITableView alloc] initWithFrame:frame];
        _tableView.dataSource = self;
        _tableView.delegate   = self;
        _tableView.bounces    = NO;
        _tableView.hidden     = YES;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _tableView;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 30;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    cell.textLabel.text = [NSString stringWithFormat:@"第%@行", @(indexPath.row + 1)];
    return cell;
}

@end
