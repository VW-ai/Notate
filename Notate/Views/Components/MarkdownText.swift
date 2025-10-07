import SwiftUI

struct MarkdownText: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
            ForEach(Array(parseMarkdown(markdown).enumerated()), id: \.offset) { index, block in
                block
            }
        }
    }

    private func parseMarkdown(_ text: String) -> [AnyView] {
        var blocks: [AnyView] = []
        let lines = text.components(separatedBy: .newlines)
        var currentSection: [String] = []
        var currentSectionTitle: String? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Handle section headers (## or ###)
            if trimmed.hasPrefix("##") {
                // Finish previous section if exists
                if !currentSection.isEmpty {
                    blocks.append(createSection(title: currentSectionTitle, content: currentSection))
                    currentSection = []
                }

                // Start new section
                currentSectionTitle = trimmed.replacingOccurrences(of: "##", with: "").trimmingCharacters(in: .whitespaces)
            }
            // Handle bullet points
            else if trimmed.hasPrefix("-") {
                let bulletContent = trimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                currentSection.append(bulletContent)
            }
            // Handle regular content
            else if !trimmed.isEmpty {
                currentSection.append(trimmed)
            }
        }

        // Add final section
        if !currentSection.isEmpty {
            blocks.append(createSection(title: currentSectionTitle, content: currentSection))
        }

        return blocks
    }

    private func createSection(title: String?, content: [String]) -> AnyView {
        return AnyView(
            VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.small) {
                // Section title
                if let title = title {
                    Text(title)
                        .font(ModernDesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(ModernDesignSystem.Colors.primary)
                        .padding(.top, ModernDesignSystem.Spacing.small)
                }

                // Section content
                VStack(alignment: .leading, spacing: ModernDesignSystem.Spacing.tiny) {
                    ForEach(Array(content.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: ModernDesignSystem.Spacing.small) {
                            // Bullet point
                            Circle()
                                .fill(ModernDesignSystem.Colors.accent)
                                .frame(width: 4, height: 4)
                                .padding(.top, 8)

                            // Content
                            Text(item)
                                .font(ModernDesignSystem.Typography.small)
                                .foregroundColor(ModernDesignSystem.Colors.primary)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)

                            Spacer()
                        }
                    }
                }
                .padding(.leading, ModernDesignSystem.Spacing.small)
            }
        )
    }
}

// MARK: - Preview
struct MarkdownText_Previews: PreviewProvider {
    static var previews: some View {
        MarkdownText(markdown: """
        ## Nearby Locations
        - Best Buy: Offers a wide selection of monitors from various brands
        - Micro Center: A specialty electronics store with a great selection

        ## Best Practices and Tips
        - Determine your needs: Consider factors like screen size and resolution
        - Research reviews: Read professional and user reviews
        """)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}