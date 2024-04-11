//
//  ViewController.m
//  CXYWebScriptManager
//
//  Created by cxy on 2024/4/9.
//

#import "ViewController.h"
#import "CXYWebScript.h"
#import "CXYWebScript-Swift.h"

@interface ViewController ()<WKUIDelegate>
@property (weak, nonatomic) IBOutlet WKWebView *webView;
@property (nonatomic, strong) CXYWebScript *webScript;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configWebView];
}

- (void)dealloc {
    [self.webScript removeScripts];
}

- (void)configWebView {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"html"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    if (@available(iOS 16.4, *)) {
        self.webView.inspectable = YES;
    }
    
    [self setupWebScript];
}

- (void)setupWebScript {
    self.webScript = [[CXYWebScript alloc] initWithWebView:self.webView];
    [self.webScript useUIDelegate];

    /** 自定义injectName: CXY，那么 JS调用时就是 window.CXY.onSayHello('Hello') */
     //self.webScript = [[CXYWebScript alloc] initWithWebView:self.webView injectName:@"CXY"];

    /** 如果不使用[self.webScript useUIDelegate]; 就要自己实现UIDelegate代理
     //self.webView.UIDelegate = self;

     - (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
         
         [self.webScript runJavaScriptPrompt:prompt
                       defaultText:defaultText
                 completionHandler:completionHandler];
     }
     */
    
    /* 添加与H5交互的方法 */
    // 添加了相同的 jsFunc ，执行优先 block > async-block > target-action

    
    // 使用 target-action 方式
    [self.webScript addTarget:self
                       jsFunc:@"onSayHello"
                        ocSel:@selector(onSayHello:)];
    
    // 使用 block 方式，可同步返回值
//    __weak typeof(self) weakSelf = self;
//    [self.webScript addJsFunc:@"onSayHello" block:^NSString * _Nullable(NSArray *args) {
//        NSLog(@"args: %@", args);
//        NSLog(@"%@", weakSelf.webView.URL);
//        return @"只支持返回字符串或nil，如何需要返回其他类型，可先将其转为JSON字符串再返回";
//    }];
    
    // 使用 async-block 可异步返回值，返回值类型只支持字符串或nil，其他类型，可先将其转为JSON字符串
    // 这种方式OC是异步的，js是阻塞的
    [self.webScript addJsFunc:@"onSayHello" asyncBlock:^(NSArray * _Nonnull args, CXYStrBlock  _Nonnull returnBlock) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            returnBlock(@"我是异步返回值，2秒后才返回");
        });
    }];
    
    [self.webScript addTarget:self
                       jsFunc:@"onPreviewImages"
                        ocSel:@selector(onPreviewImages:currentIndex:)];
    
    [self.webScript addTarget:self
                       jsFunc:@"onShareObj"
                        ocSel:@selector(onShareObject:)];
    
    [self.webScript addTarget:self
                       jsFunc:@"onJumpToPage"
                        ocSel:@selector(onJumpToPage:)];
    
   
}

- (NSString*)onSayHello:(NSString*)param {
    NSLog(@"param: %@", param);
    return @"只支持返回字符串或nil，如何需要返回其他类型，可先将其转为JSON字符串再返回";
}

- (void)onPreviewImages:(NSArray*)images currentIndex:(NSString*)currentIndex {
    NSLog(@"images: %@", images);
    NSLog(@"content: %@", currentIndex);
}

- (void)onShareObject:(id)obj {
    NSLog(@"obj-class: %@", [obj class]); //__NSDictionaryI
    NSLog(@"obj: %@", obj);
}

- (void)onJumpToPage:(NSString*)url {
    // page=xxx, 你可以解析url，跳转到指定页面
    DetailController *c = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailController"];
    [self.navigationController pushViewController:c animated:YES];
}

// 缩放字体
- (IBAction)onScaleFontClick:(UIButton*)sender {
    sender.selected = !sender.isSelected;
    CGFloat scale = sender.selected ? 100*1.3 : 100;
    
    NSString *textJS = [NSString stringWithFormat:@"document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust='%@%%'",@(scale)];
    [self.webScript evaluateJavaScript:textJS completionHandler:^(id result, NSError * _Nullable error) {
        NSLog(@"result: %@", result);
    }];
}

// 修改body背景色
- (IBAction)onChangeBgColor:(id)sender {
    // 生成随机的16进制颜色值
    NSString *hexColor = [NSString stringWithFormat:@"#%06X", arc4random_uniform(0xFFFFFF)];
    NSString *js = [NSString stringWithFormat:@"onChangeTheme(\"%@\")",hexColor];
    [self.webScript evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"result: %@", result); //'修改成功'
    }];
}

- (IBAction)onReload:(id)sender {
    [self.webView reload];
}

//#pragma mark - WKUIDelegate
//- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
//    
//    [self.webScript runJavaScriptPrompt:prompt
//                  defaultText:defaultText
//            completionHandler:completionHandler];
//}
@end
