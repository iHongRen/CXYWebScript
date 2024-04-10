# CXYWebScript
简化 iOS App 与 H5 交互，H5 直接调用 window.App?.onSayHello('Hello')，即可完成对原生 App  `onSayHello:` 方法的调用。如此，与 H5 在 Android 端调用一致。



### CXYWebScript 有以下特点：

- H5 在调用原 App 方法是时，不需要区分是 Android 还是 iOS 环境
- 支持使用 block 和 target-action 方式注册 js 方法
- 支持传递返回值给 H5 (限字符串类型或 nil )
- 支持 **iOS 10+**



<img src="./screenshot.png" width="375">

## 如何使用

### H5 端 JS代码：

```js
// 调用原生App方法，并能接收App端方法的返回值
function onBtn1Click() {
    if (window.App) {
        // 接收 App 端的返回值
        const ret = window.App.onSayHello('Hello')
        console.log(ret) 
    }
}

// 传递多个参数给App端
function onBtn2Click() {
    const imgs = [
      'https://www.baidu.com/img/1.png', 
      'https://www.baidu.com/img/2.png', 
      'https://www.baidu.com/img/3.png']
    
    window.App?.onPreviewImages(imgs, 1)
}

// App 端调用此方法，修改body背景
function onChangeTheme(theme) {
    document.body.style.backgroundColor = theme
    return '修改成功' // 返回一个字符串给App端
}
```

### App 端 OC代码：

```objective-c
#import "CXYWebScript.h"

 - (void)setupWebScript {
   // 初始化 CXYWebScript
    self.webScript = [[CXYWebScript alloc] initWithWebView:self.webView];
    [self.webScript useUIDelegate];

    /* 添加与H5交互的方法 */
    // 使用 target-action 方式
    [self.webScript addTarget:self
                       jsFunc:@"onSayHello"
                        ocSel:@selector(onSayHello:)];
    
    // 使用 block 方式，
    // 如果 target-action 和 block 添加了相同的 jsFunc ，则只执行 block 方式的
    __weak typeof(self) weakSelf = self;
    [self.webScript addJsFunc:@"onSayHello" block:^NSString * _Nullable(NSArray *args) {
        NSLog(@"args: %@", args);
        NSLog(@"%@", weakSelf.webView.URL);
        return @"只支持返回字符串或nil，如何需要返回其他类型，可先将其转为JSON字符串再返回";
    }];
    
    // 多参数使用
    [self.webScript addTarget:self
                       jsFunc:@"onPreviewImages"
                        ocSel:@selector(onPreviewImages:currentIndex:)];
    
}

- (NSString*)onSayHello:(NSString*)param {
    NSLog(@"param: %@", param);
    return @"只支持返回字符串或nil，如何需要返回其他类型，可先将其转为JSON字符串再返回";
}

- (void)onPreviewImages:(NSArray*)images currentIndex:(NSString*)currentIndex {
    NSLog(@"images: %@", images);
    NSLog(@"content: %@", currentIndex);
}
  
// 修改body背景色
- (IBAction)onChangeBgColor:(id)sender {
    NSString *hexColor = [NSString stringWithFormat:@"#%06X", arc4random_uniform(0xFFFFFF)];
    NSString *js = [NSString stringWithFormat:@"onChangeTheme(\"%@\")",hexColor];
  
    // App 调用 H5 方法
    [self.webScript evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSLog(@"result: %@", result); //'修改成功'
    }];
}

```


