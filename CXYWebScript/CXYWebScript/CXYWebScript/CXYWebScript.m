//
//  CXYWebScript.m
//  CXYWebScript
//
//  Created by cxy on 2024/4/9.
//

#import "CXYWebScript.h"

@interface NSObject (CXY)
@end

@implementation NSObject (CXY)

- (id)cxy_performSelector:(SEL)aSelector withObjects:(NSArray *)objects {
    if (!aSelector || ![self respondsToSelector:aSelector] || (objects && ![objects isKindOfClass:[NSArray class]])) {
        return nil;
    }
    
    NSMethodSignature *signature = [self methodSignatureForSelector:aSelector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setTarget:self];
    [invocation setSelector:aSelector];
    
    NSInteger arguments = [signature numberOfArguments]-2;
    NSInteger count = MIN(arguments, objects.count);
    for (NSUInteger i=0; i<count; i++) {
        id obj = objects[i];
        if ([obj isKindOfClass:[NSNull class]]) {
            obj = nil;
        }
        [invocation setArgument:&obj atIndex:i+2];
    }
    [invocation invoke];
    
    if ([signature methodReturnLength]) { 
        __unsafe_unretained id data;
        [invocation getReturnValue:&data];
        return data;
    }
    return nil;
}

@end


@interface CXYWebScript ()
@property (nonatomic, strong, readwrite) WKWebView *webView;
@property (nonatomic, copy) NSString *injectName;
@property (nonatomic, strong) NSMapTable *targetMap;
@property (nonatomic, strong) NSMutableDictionary *scriptMap;
@property (nonatomic, strong) NSMutableDictionary *blockMap;
@property (nonatomic, strong) NSMutableDictionary *asyncBlockMap;

@end

@implementation CXYWebScript

- (instancetype)initWithWebView:(WKWebView*)webView {
    return [self initWithWebView:webView injectName:nil];
}

- (instancetype)initWithWebView:(WKWebView*)webView injectName:(nullable NSString*)injectName {
    if (self = [super init]) {
        self.injectName = injectName?:@"App";
        self.webView = webView;
        [self config];
    }
    return self;
}

- (void)useUIDelegate {
    self.webView.UIDelegate = self;
}

- (void)config {
    WKUserScript *script = [[WKUserScript alloc] initWithSource:[self proxyJScript]
                                                  injectionTime:(WKUserScriptInjectionTimeAtDocumentStart)
                                               forMainFrameOnly:NO];
    
    [self.webView.configuration.userContentController addUserScript:script];
}

- (NSMutableDictionary *)scriptMap {
    if (!_scriptMap) {
        _scriptMap = @{}.mutableCopy;
    }
    return _scriptMap;
}

- (NSMapTable *)targetMap {
    if (!_targetMap) {
        _targetMap = [NSMapTable strongToWeakObjectsMapTable];
    }
    return _targetMap;
}

- (NSMutableDictionary *)blockMap {
    if (!_blockMap) {
        _blockMap = @{}.mutableCopy;
    }
    return _blockMap;
}

- (NSMutableDictionary *)asyncBlockMap {
    if (!_asyncBlockMap) {
        _asyncBlockMap = @{}.mutableCopy;
    }
    return _asyncBlockMap;
}

- (NSString*)proxyJScript {
    return [NSString stringWithFormat:
    @"window.%@ = new Proxy({},{ \
        get: function (target, name) { \
            return function (...args) { \
                return window.prompt(name,JSON.stringify(args)); \
            };\
        } \
    });", self.injectName];
}

- (void)addTarget:(id)target jsFunc:(NSString*)jsFunc ocSel:(SEL)sel {
    [self.targetMap setObject:target forKey:jsFunc];
    self.scriptMap[jsFunc] = NSStringFromSelector(sel);
}

- (void)removeScripts {
    [_asyncBlockMap removeAllObjects];
    [_blockMap removeAllObjects];
    [_targetMap removeAllObjects];
    [_scriptMap removeAllObjects];
    [self.webView.configuration.userContentController removeAllUserScripts];
}

- (void)addJsFunc:(NSString*)jsFunc block:(CXYBlock)block {
    self.blockMap[jsFunc] = block;
}

- (void)addJsFunc:(NSString*)jsFunc asyncBlock:(CXYAsyncBlock)block {
    self.asyncBlockMap[jsFunc] = block;
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id result, NSError * _Nullable error))completionHandler {
    [self.webView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

- (NSArray*)arrayWithJSON:(NSString*)json {
    if ([json isKindOfClass:NSString.class] && json.length>0) {
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *ret = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        return ret?:@[];
    }
    return @[];
}

- (void)runJavaScriptPrompt:(NSString *)prompt
                defaultText:(NSString *)defaultText
          completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    NSArray *args = [self arrayWithJSON:defaultText];

    if (_blockMap[prompt]) {
        CXYBlock block = _blockMap[prompt];
        NSString *ret = block(args);
        [self completion:ret handler:completionHandler];
        
    } else if (_asyncBlockMap[prompt]) {
        CXYAsyncBlock asyncBlock = _asyncBlockMap[prompt];
        asyncBlock(args, ^(NSString *ret){
            [self completion:ret handler:completionHandler];
        });
        
    } else {
        NSString *ret = nil;
        NSString *selString = self.scriptMap[prompt];
        NSObject *target = [self.targetMap objectForKey:prompt];
        if (selString && target) {
            SEL sel = NSSelectorFromString(selString);
            ret = [target cxy_performSelector:sel withObjects:args];
        }
        [self completion:ret handler:completionHandler];
    }
}

- (void)completion:(NSString*)res handler:(void (^)(NSString * _Nullable))completionHandler {
    
    NSString *ret = res;
    if (ret && ![ret isKindOfClass:NSString.class]) {
        NSAssert(NO, @"只接受字符串或nil类型的返回值");
        ret = nil;
    }
    if (completionHandler) {
        completionHandler(ret);
    }
}

#pragma mark - WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    [self runJavaScriptPrompt:prompt 
                  defaultText:defaultText
            completionHandler:completionHandler];
}

@end



