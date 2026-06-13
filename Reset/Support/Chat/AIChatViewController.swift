import UIKit

class AIChatViewController: UIViewController {

    private let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Reset AI Coach"
        view.backgroundColor = .systemBackground

        textView.frame = view.bounds
        textView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        textView.text = """
        AI Coach

        User: I'm having cravings.

        AI: Cravings are temporary. Try drinking water and taking a short walk.

        User: Motivate me.

        AI: Every sober day is evidence that you're stronger than yesterday.
        """

        view.addSubview(textView)
    }
}
