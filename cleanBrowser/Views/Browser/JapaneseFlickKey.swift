import SwiftUI

struct JapaneseFlickKey: View {
    let character: String
    let flickOptions: [CustomKeyboardViewModel.FlickDirection: String]
    let onCommit: (CustomKeyboardViewModel.FlickDirection?) -> Void

    @GestureState private var translation: CGSize = .zero
    @State private var isPressing = false

    private let keyCornerRadius: CGFloat = 8
    private let optionOffset: CGFloat = 34
    private let flickThreshold: CGFloat = 18

    private var activeDirection: CustomKeyboardViewModel.FlickDirection? {
        Self.direction(for: translation, threshold: flickThreshold)
    }

    private var displayedCharacter: String {
        guard
            let activeDirection,
            let selected = flickOptions[activeDirection]
        else {
            return character
        }

        return selected
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: keyCornerRadius)
                .fill(isPressing ? Color.blue.opacity(0.14) : Color.white)
                .shadow(color: .black.opacity(0.12), radius: 1, y: 1)

            Text(displayedCharacter)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.black)

            if isPressing && !flickOptions.isEmpty {
                FlickOptionsOverlay(
                    baseCharacter: character,
                    activeDirection: activeDirection,
                    flickOptions: flickOptions,
                    optionOffset: optionOffset
                )
                .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .contentShape(RoundedRectangle(cornerRadius: keyCornerRadius))
        .zIndex(isPressing ? 1 : 0)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($translation) { value, state, _ in
                    state = value.translation
                }
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                    }
                }
                .onEnded { value in
                    let direction = Self.direction(for: value.translation, threshold: flickThreshold)
                    isPressing = false
                    onCommit(direction)
                }
        )
    }

    private static func direction(
        for translation: CGSize,
        threshold: CGFloat
    ) -> CustomKeyboardViewModel.FlickDirection? {
        let horizontalDistance = abs(translation.width)
        let verticalDistance = abs(translation.height)
        let strongestDistance = max(horizontalDistance, verticalDistance)

        guard strongestDistance >= threshold else {
            return nil
        }

        if horizontalDistance > verticalDistance {
            return translation.width > 0 ? .right : .left
        }

        return translation.height > 0 ? .down : .up
    }
}

private struct FlickOptionsOverlay: View {
    let baseCharacter: String
    let activeDirection: CustomKeyboardViewModel.FlickDirection?
    let flickOptions: [CustomKeyboardViewModel.FlickDirection: String]
    let optionOffset: CGFloat

    var body: some View {
        ZStack {
            candidateBubble(
                label: baseCharacter,
                isSelected: activeDirection == nil
            )

            ForEach(CustomKeyboardViewModel.FlickDirection.allCases, id: \.self) { direction in
                if let option = flickOptions[direction] {
                    candidateBubble(
                        label: option,
                        isSelected: activeDirection == direction
                    )
                    .offset(offset(for: direction))
                }
            }
        }
        .frame(width: 110, height: 110)
    }

    @ViewBuilder
    private func candidateBubble(label: String, isSelected: Bool) -> some View {
        Text(label)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(isSelected ? .white : .black)
            .frame(width: 34, height: 34)
            .background(isSelected ? Color.blue : Color.white)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
    }

    private func offset(for direction: CustomKeyboardViewModel.FlickDirection) -> CGSize {
        switch direction {
        case .up:
            return CGSize(width: 0, height: -optionOffset)
        case .right:
            return CGSize(width: optionOffset, height: 0)
        case .down:
            return CGSize(width: 0, height: optionOffset)
        case .left:
            return CGSize(width: -optionOffset, height: 0)
        }
    }
}
