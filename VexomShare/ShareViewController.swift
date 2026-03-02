import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        extractAndOpen()
    }
    
    func extractAndOpen() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            cancel()
            return
        }
        
        var text = ""
        let group = DispatchGroup()
        
        for item in items {
            if let t = item.attributedContentText?.string, !t.isEmpty {
                text += t + " "
            }
            for attachment in (item.attachments ?? []) {
                if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                    group.enter()
                    attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { data, _ in
                        if let t = data as? String { text += t + " " }
                        group.leave()
                    }
                } else if attachment.hasItemConformingToTypeIdentifier("public.url") {
                    group.enter()
                    attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { data, _ in
                        if let url = data as? URL { text += url.absoluteString + " " }
                        group.leave()
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            let final = text.trimmingCharacters(in: .whitespacesAndNewlines)
            // Save to shared UserDefaults then open app
            UserDefaults.standard.set(final, forKey: "vexom_pending_action")
            UserDefaults.standard.synchronize()
            
            // Try opening via URL
            let encoded = final.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "vexom://action?text=\(encoded)") {
                // Use perform selector to get UIApplication
                let selectorName = "openURL:"
                let selector = NSSelectorFromString(selectorName)
                var responder: UIResponder? = self
                while let r = responder {
                    if r.responds(to: selector) {
                        r.perform(selector, with: url)
                        break
                    }
                    responder = r.next
                }
            }
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
    
    func cancel() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
