import UIKit

class ActionViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.01)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.extractAndOpen()
        }
    }
    
    func extractAndOpen() {
        var text = ""
        
        if let items = extensionContext?.inputItems as? [NSExtensionItem] {
            for item in items {
                if let t = item.attributedContentText?.string, !t.isEmpty {
                    text = t
                    break
                }
            }
        }
        
        if text.isEmpty {
            text = "no text found"
        }
        
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "vexom://action?text=\(encoded)"
        
        guard let url = URL(string: urlString) else {
            self.extensionContext?.completeRequest(returningItems: nil)
            return
        }
        
        // This is the correct way to open URL from extension
        self.extensionContext?.open(url, completionHandler: { _ in
            self.extensionContext?.completeRequest(returningItems: nil)
        })
    }
}
