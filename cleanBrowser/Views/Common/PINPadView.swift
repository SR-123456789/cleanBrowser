import SwiftUI

struct PINPadView: View {
    enum Style {
        case regular
        case compact

        var titleFont: Font {
            switch self {
            case .regular:
                return .system(size: 12, weight: .bold)
            case .compact:
                return .title2.weight(.bold)
            }
        }

        var buttonSize: CGFloat {
            switch self {
            case .regular:
                return 80
            case .compact:
                return 70
            }
        }

        var keypadSpacing: CGFloat {
            switch self {
            case .regular:
                return 20
            case .compact:
                return 15
            }
        }

        var containerSpacing: CGFloat {
            switch self {
            case .regular:
                return 30
            case .compact:
                return 20
            }
        }

        var digitFont: Font {
            switch self {
            case .regular:
                return .title
            case .compact:
                return .title2
            }
        }
    }

    let title: String
    let enteredDigits: Int
    let errorMessage: String?
    let style: Style
    let onDigitTapped: (String) -> Void
    let onDeleteTapped: () -> Void

    var body: some View {
        VStack(spacing: style.containerSpacing) {
            Spacer()

            Text(title)
                .font(style.titleFont)

            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < enteredDigits ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 20, height: 20)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: style.keypadSpacing) {
                ForEach(1...9, id: \.self) { number in
                    digitButton(String(number))
                }

                Color.clear
                    .frame(width: style.buttonSize, height: style.buttonSize)

                digitButton("0")

                Button(action: onDeleteTapped) {
                    Image(systemName: "delete.left")
                        .font(style.digitFont)
                        .foregroundColor(.white)
                        .frame(width: style.buttonSize, height: style.buttonSize)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding()
    }

    private func digitButton(_ digit: String) -> some View {
        Button(action: { onDigitTapped(digit) }) {
            Text(digit)
                .font(style.digitFont)
                .foregroundColor(.white)
                .frame(width: style.buttonSize, height: style.buttonSize)
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
