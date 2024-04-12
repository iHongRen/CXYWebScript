//
//  DetailController.swift
//  CXYWebScript
//
//  Created by cxy on 2024/4/11.
//

import UIKit

class DetailController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    private lazy var webScript: CXYWebScript = {
        let webScript = CXYWebScript(webView: webView)
        webScript.useUIDelegate()
        return webScript
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = Bundle.main.url(forResource: "demo", withExtension: "html")!
        webView.load(URLRequest(url: url))
        webView.navigationDelegate = self;
        setupWebScript()
    }
    
    deinit {
        print("deinit")
    }
    
    func setupWebScript() {
       
        webScript.addJsFunc("onSayHello") { args in
            print(args)
            return "只支持返回字符串或nil，如何需要返回其他类型，可先将其转为JSON字符串再返回"
        }

         // async-block 方式，Swift 异步返回，js 同步接收返回数据
//        webScript.addJsFunc("onSayHello") { args, returnBlock in
//            print(args)
//            DispatchQueue.main.asyncAfter(deadline: .now()+2) {
//                // 只支持返回字符串或nil，如何需要返回其他类型，可先将其转为JSON字符串再返回
//                returnBlock("我是异步返回值，2秒后才返回"); // returnBlock 必须要执行
//            }
//        }
        
        webScript.addTarget(self, jsFunc: "onPreviewImages", ocSel: #selector(onPreviewImages(_:_:)))
        
        webScript.addTarget(self, jsFunc: "onShareObj", ocSel: #selector(onShareObject(_:)))
        
        webScript.addJsFunc("onJumpToPage") { [weak self] args in
            self?.navigationController?.popViewController(animated: true)
            return ""
        }
        
    }
    
    @objc func onPreviewImages(_ imgs: [String], _ currentIndex: NSNumber) {
        print(imgs)
        print(currentIndex)
    }
    
    @objc func onShareObject(_ obj: AnyObject) {
        print(obj)
    }
  
}

extension DetailController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        // 修改第四个按钮的标题
        self.webScript.evaluateJavaScript("modifyBtn4Title(\"返回\")") { res, err in
            
        }
    }
}
