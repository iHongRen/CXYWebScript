//
//  CXYWebScript.h
//  CXYWebScript
//
//  Created by cxy on 2024/4/9.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CXYStrBlock)(NSString* _Nullable str);
typedef void(^CXYAsyncBlock)(NSArray *args, CXYStrBlock returnBlock);

typedef NSString* _Nullable (^CXYBlock)(NSArray *args);

@interface CXYWebScript : NSObject<WKUIDelegate>

@property (nonatomic, strong, readonly) WKWebView *webView;

- (instancetype)initWithWebView:(WKWebView*)webView;
- (instancetype)initWithWebView:(WKWebView*)webView injectName:(nullable NSString*)injectName;

- (void)useUIDelegate;

- (void)addJsFunc:(NSString*)jsFunc block:(CXYBlock)block;

// OC是异步的，js是同步的
- (void)addJsFunc:(NSString*)jsFunc asyncBlock:(CXYAsyncBlock)block;

- (void)addTarget:(id)target jsFunc:(NSString*)jsFunc ocSel:(SEL)sel;
- (void)removeScripts;

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler;

- (void)runJavaScriptPrompt:(NSString *)prompt
                defaultText:(NSString *)defaultText
          completionHandler:(void (^)(NSString * _Nullable))completionHandler;

@end

NS_ASSUME_NONNULL_END
