import UIKit

/// The default window above a marker: a title and a snippet, as Google's default.
internal final class GMSInfoWindowView: UIView {

    init(title: String?, snippet: String?) {
        super.init(frame: .zero)
        backgroundColor = .white
        layer.cornerRadius = 8
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])

        if let title {
            let label = UILabel()
            label.text = title
            label.font = .boldSystemFont(ofSize: 14)
            label.textColor = .black
            stack.addArrangedSubview(label)
        }
        if let snippet {
            let label = UILabel()
            label.text = snippet
            label.font = .systemFont(ofSize: 12)
            label.textColor = UIColor(white: 0.33, alpha: 1)
            label.numberOfLines = 0
            stack.addArrangedSubview(label)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("GMSInfoWindowView is created in code only.")
    }
}
