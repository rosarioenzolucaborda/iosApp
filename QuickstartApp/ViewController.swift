import GoogleAPIClientForREST
import GoogleSignIn
import UIKit

class ViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLRAuthScopeGmailReadonly]
    
    private let service = GTLRGmailService()
    let signInButton = GIDSignInButton()
    let output = UITextView()
    private var saldo = 0.0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure Google Sign-in.
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = scopes
        GIDSignIn.sharedInstance().signInSilently()
        
        // Add the sign-in button.
        view.addSubview(signInButton)
        
        // Add a UITextView to display output.
        output.frame = view.bounds
        output.isEditable = false
        output.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 20, right: 0)
        output.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        output.isHidden = true
        view.addSubview(output);
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!,
              withError error: Error!) {
        if let error = error {
            showAlert(title: "Authentication Error", message: error.localizedDescription)
            self.service.authorizer = nil
        } else {
            self.signInButton.isHidden = true
            self.output.isHidden = false
            self.service.authorizer = user.authentication.fetcherAuthorizer()
            //fetchLabels()
            fetchMessages()
        }
    }
    
    // Construct a query and get a list of upcoming labels from the gmail API
    func fetchLabels() {
        output.text = "Getting labels..."
        
        let query = GTLRGmailQuery_UsersLabelsList.query(withUserId: "me")
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicket(ticket:finishedWithObject:error:))
 

        )
    }
    
    func fetchMessages() {
        output.text = "Getting messages:"
        
        let query = GTLRGmailQuery_UsersMessagesList.query(withUserId: "me")
        query.q = "from:widiba"
        query.maxResults = 5
        //service.shouldFetchNextPages = true
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicketMessages(ticket:finishedWithObject:error:))
            
        )
    }

    func fetchMessage(messageId: String) {
        output.text = "Getting message..."
        
        let query = GTLRGmailQuery_UsersMessagesGet.query(withUserId: "me", identifier: messageId)
        service.executeQuery(query,
                             delegate: self,
                             didFinish: #selector(displayResultWithTicketMessage(ticket:finishedWithObject:error:))
            
        )
    }

    // Display the labels in the UITextView
    func displayResultWithTicket(ticket : GTLRServiceTicket,
                                 finishedWithObject labelsResponse : GTLRGmail_ListLabelsResponse,
                                 error : NSError?) {
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        var labelString = ""
        if let labels = labelsResponse.labels, labels.count > 0 {
            labelString += "Labels:\n"
            for label in labels {
                labelString += "\(label.name!)\n"
            }
        } else {
            labelString = "No labels found."
        }
        output.text = labelString
    }
    
    func displayResultWithTicketMessages(ticket : GTLRServiceTicket,
                                 finishedWithObject messagesResponse : GTLRGmail_ListMessagesResponse,
                                 error : NSError?) {
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
        var messagesString = ""
        if let messages = messagesResponse.messages, messages.count > 0 {
            messagesString += "Messages:\n"
            for message in messages {
                messagesString += "\(message.identifier!)\n"
                fetchMessage(messageId: message.identifier!)
                //messagesString += buffer
            }
        } else {
            messagesString = "No messages found."
        }
        //output.text = /*messagesString +*/ buffer
        //showAlert(title: "messaggio", message: output.text)
    }

    func displayResultWithTicketMessage(ticket : GTLRServiceTicket,
                                         finishedWithObject messageResponse : GTLRGmail_Message,
                                         error : NSError?) {
        if let error = error {
            showAlert(title: "Error", message: error.localizedDescription)
            return
        }
//        output.insertText("\n\(messageResponse.snippet!)\n")
        let amount = matches(for:"[0-9]+,[0-9]+", in:messageResponse.snippet!)
        if amount.count > 0 {
            //output.insertText("\n"+amount[0])
            let importo = amount[0].replacingOccurrences(of: ",",with: ".")
            saldo += Double(importo)!
            let giorni = Calendar.current.component(.day, from: Date())
            let media = round(100*saldo/Double(giorni))/100
            output.text = String(saldo) + " € in " + String(giorni) + " giorni\n\n" + String(media) + " € al giorno"
            
        }
    
        
    }
    
    func matches(for regex: String, in text: String) -> [String] {
        
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: text,
                                        range: NSRange(text.startIndex..., in: text))
            return results.map {
                String(text[Range($0.range, in: text)!])
            }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return []
        }
    }
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
}

