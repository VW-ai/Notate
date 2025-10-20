import SwiftUI

struct TimeRangePicker: View {
    @Binding var selectedRange: TimeRange
    let onRangeChange: (TimeRange) -> Void

    @State private var showCustomPicker = false
    @State private var customStart = Date()
    @State private var customEnd = Date()

    var body: some View {
        HStack(spacing: 12) {
            // Quick range buttons
            ForEach(TimeRange.allCases.filter { $0 != .custom }, id: \.self) { range in
                RangeButton(
                    range: range,
                    isSelected: selectedRange == range,
                    action: {
                        selectedRange = range
                        onRangeChange(range)
                    }
                )
            }

            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.2))

            // Custom range button
            Button(action: {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    showCustomPicker.toggle()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: selectedRange == .custom ? 16 : 12))

                    Text("Custom")
                        .font(.system(size: selectedRange == .custom ? 18 : 14, weight: selectedRange == .custom ? .bold : .semibold))
                }
                .foregroundColor(selectedRange == .custom ? Color(hex: "#1C1C1E") : .secondary)
                .frame(minWidth: 100)
                .frame(height: selectedRange == .custom ? 56 : 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedRange == .custom ? Color(hex: "#FFD60A") : Color(hex: "#3A3A3C"))
                )
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedRange)
            .popover(isPresented: $showCustomPicker) {
                customDatePicker
            }
        }
    }

    // MARK: - Custom Date Picker

    private var customDatePicker: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Date Range")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Start Date")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DatePicker(
                    "",
                    selection: $customStart,
                    displayedComponents: [.date]
                )
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("End Date")
                    .font(.caption)
                    .foregroundColor(.secondary)

                DatePicker(
                    "",
                    selection: $customEnd,
                    displayedComponents: [.date]
                )
                .labelsHidden()
            }

            HStack {
                Button("Cancel") {
                    showCustomPicker = false
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Apply") {
                    selectedRange = .custom
                    showCustomPicker = false
                    // Trigger custom range change through the view model
                    onRangeChange(.custom)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 280)
    }
}

// MARK: - Range Button

struct RangeButton: View {
    let range: TimeRange
    let isSelected: Bool
    let action: () -> Void

    private var backgroundColor: Color {
        if isSelected {
            return Color(hex: "#FFD60A")
        } else {
            return Color(hex: "#3A3A3C")
        }
    }

    private var textColor: Color {
        if isSelected {
            return Color(hex: "#1C1C1E")
        } else {
            return .secondary
        }
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                action()
            }
        }) {
            Text(range.rawValue)
                .font(.system(size: isSelected ? 18 : 14, weight: isSelected ? .bold : .semibold))
                .foregroundColor(textColor)
                .frame(minWidth: 100)
                .frame(height: isSelected ? 56 : 48)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedRange: TimeRange = .week

    return TimeRangePicker(
        selectedRange: $selectedRange,
        onRangeChange: { newRange in
            print("Range changed to: \(newRange)")
        }
    )
    .padding()
    .frame(width: 700)
}
