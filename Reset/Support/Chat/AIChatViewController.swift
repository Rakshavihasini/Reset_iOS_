import UIKit

class AIChatViewController: UIViewController {

    private let textField = UITextField()
    private let textView = UITextView()
    private let sendButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "AI Coach"
        view.backgroundColor = .systemBackground

        textView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        textField.placeholder = "Ask anything..."
        textField.borderStyle = .roundedRect

        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self,
                             action: #selector(sendMessage),
                             for: .touchUpInside)

        view.addSubview(textView)
        view.addSubview(textField)
        view.addSubview(sendButton)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 500),

            textField.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 10),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            sendButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 10),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.centerYAnchor.constraint(equalTo: textField.centerYAnchor),

            textField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc func sendMessage() {
        guard let message = textField.text else { return }

        textView.text += "\nYou: \(message)\n"

        Task {
            let reply = await askAI(message)
            DispatchQueue.main.async {
                self.textView.text += "AI: \(reply)\n"
            }
        }

        textField.text = ""
    }
}


extension AIChatViewController {

    func askAI(_ prompt: String) async -> String {

        let apiKey = ""

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions")
        else { return "Error" }

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": "You are a recovery coach helping users stay sober."
                ],
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)",
                         forHTTPHeaderField: "Authorization")
        request.setValue("application/json",
                         forHTTPHeaderField: "Content-Type")

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            if let choices = json?["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {

                return content
            }

        } catch {
            return "Failed to get response."
        }

        return "No response."
    }
}
