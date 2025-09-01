//
//  EnhancedSearchScreen.swift
//
//
//  Created by TheCodeAssassin on 8/31/25.
//

import SwiftUI
import Combine

// MARK: - Data Models
struct SearchItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let category: String
    let imageIcon: String
    let color: Color
    let isTrending: Bool
}

struct SearchSuggestion: Identifiable, Hashable {
    let id = UUID()
    let text: String
    let category: String
    let icon: String
}

// MARK: - Enhanced Search View Model
class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [SearchItem] = []
    @Published var recentSearches: [String] = []
    @Published var searchSuggestions: [SearchSuggestion] = []
    @Published var isLoading = false
    @Published var selectedCategory: String?

    private var cancellables = Set<AnyCancellable>()

    // Enhanced sample data with colors and icons
    private let sampleData = [
        SearchItem(title: "iPhone 15 Pro", subtitle: "Latest Apple smartphone", category: "Electronics", imageIcon: "iphone", color: .blue, isTrending: true),
        SearchItem(title: "MacBook Air", subtitle: "Lightweight laptop", category: "Electronics", imageIcon: "laptopcomputer", color: .purple, isTrending: true),
        SearchItem(title: "AirPods Pro", subtitle: "Wireless earbuds", category: "Audio", imageIcon: "airpods", color: .green, isTrending: false),
        SearchItem(title: "iPad Pro", subtitle: "Professional tablet", category: "Electronics", imageIcon: "ipad", color: .orange, isTrending: true),
        SearchItem(title: "Apple Watch", subtitle: "Smart watch", category: "Wearables", imageIcon: "applewatch", color: .pink, isTrending: false),
        SearchItem(title: "Coffee Maker", subtitle: "Automatic brewing", category: "Kitchen", imageIcon: "cup.and.saucer", color: .brown, isTrending: false),
        SearchItem(title: "Running Shoes", subtitle: "Athletic footwear", category: "Sports", imageIcon: "figure.run", color: .red, isTrending: true),
        SearchItem(title: "Wireless Charger", subtitle: "Fast charging pad", category: "Accessories", imageIcon: "battery.100.bolt", color: .yellow, isTrending: false)
    ]

    private let suggestions = [
        SearchSuggestion(text: "Apple products", category: "Electronics", icon: "apple.logo"),
        SearchSuggestion(text: "Wireless accessories", category: "Accessories", icon: "wifi"),
        SearchSuggestion(text: "Sports equipment", category: "Sports", icon: "sportscourt"),
        SearchSuggestion(text: "Kitchen appliances", category: "Kitchen", icon: "house")
    ]

    var trendingItems: [SearchItem] {
        sampleData.filter { $0.isTrending }
    }

    var categories: [String] {
        Array(Set(sampleData.map { $0.category })).sorted()
    }

    init() {
        searchSuggestions = suggestions

        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchText in
                self?.performSearch(query: searchText)
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation(.easeOut(duration: 0.3)) {
                searchResults = []
            }
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let results = self?.sampleData.filter { item in
                let matchesQuery = item.title.localizedCaseInsensitiveContains(query) ||
                    item.category.localizedCaseInsensitiveContains(query) ||
                    (item.subtitle?.localizedCaseInsensitiveContains(query) ?? false)

                let matchesCategory = self?.selectedCategory == nil || item.category == self?.selectedCategory

                return matchesQuery && matchesCategory
            } ?? []

            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                self?.searchResults = results
                self?.isLoading = false
            }
        }
    }

    func addToRecentSearches(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            recentSearches.removeAll { $0 == trimmedQuery }
            recentSearches.insert(trimmedQuery, at: 0)
            recentSearches = Array(recentSearches.prefix(10))
        }
    }

    func clearSearchHistory() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            recentSearches.removeAll()
        }
    }

    func selectRecentSearch(_ query: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            searchText = query
        }
    }

    func selectCategory(_ category: String?) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedCategory = category
        }
        if !searchText.isEmpty {
            performSearch(query: searchText)
        }
    }
}

// MARK: - Modern Search Bar with Glassmorphism
struct ModernSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    @State private var isTyping = false
    let onCancel: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(isFocused ? .blue : .secondary)
                    .scaleEffect(isFocused ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isTyping ? 360 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isFocused)
                    .animation(.easeInOut(duration: 0.8), value: isTyping)

                TextField("What are you looking for?", text: $text)
                    .focused($isFocused)
                    .font(.system(.body, design: .rounded))
                    .onSubmit {
                        withAnimation(.spring(response: 0.3)) {
                            onSubmit()
                        }
                    }
                    .onChange(of: text) { _, _ in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isTyping = !text.isEmpty
                        }
                    }

                if !text.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            text = ""
                            isTyping = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .scaleEffect(0.9)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .animation(.spring(response: 0.3), value: text.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .stroke(isFocused ? .blue.opacity(0.5) : .clear, lineWidth: 1.5)
                    .shadow(color: .black.opacity(isFocused ? 0.1 : 0.05), radius: isFocused ? 12 : 8, x: 0, y: isFocused ? 4 : 2)
                    .scaleEffect(isFocused ? 1.02 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isFocused)
            }

            if isFocused {
                Button("Cancel") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        text = ""
                        isFocused = false
                        isTyping = false
                        onCancel()
                    }
                }
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(.blue)
                .transition(.move(edge: .trailing).combined(with: .opacity).combined(with: .scale))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFocused)
    }
}

// MARK: - Enhanced Search Result Card
struct SearchResultCard: View {
    let item: SearchItem
    let onTap: () -> Void
    @State private var isVisible = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onTap()
            }
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            HStack(spacing: 16) {
                // Icon with gradient background
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [item.color.opacity(0.8), item.color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: item.color.opacity(0.3), radius: 6, x: 0, y: 2)

                    Image(systemName: item.imageIcon)
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .medium))
                        .scaleEffect(isVisible ? 1.0 : 0.5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title)
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)

                        if item.isTrending {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                                .scaleEffect(isVisible ? 1.0 : 0.5)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: isVisible)
                        }
                    }

                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    Text(item.category)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(item.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(item.color.opacity(0.1))
                        .clipShape(Capsule())
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: isVisible)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.system(size: 14, weight: .medium))
                    .offset(x: isVisible ? 0 : 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isVisible)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Category Filter Pills
struct CategoryFilterView: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    @State private var isVisible = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All category pill
                CategoryPill(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .blue
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedCategory = nil
                    }
                }

                ForEach(Array(categories.enumerated()), id: \.element) { index, category in
                    CategoryPill(
                        title: category,
                        isSelected: selectedCategory == category,
                        color: colorForCategory(category)
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedCategory = category == selectedCategory ? nil : category
                        }
                    }
                    .scaleEffect(isVisible ? 1.0 : 0.5)
                    .opacity(isVisible ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: isVisible)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
        }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Electronics": return .blue
        case "Audio": return .green
        case "Wearables": return .pink
        case "Kitchen": return .brown
        case "Sports": return .red
        case "Accessories": return .yellow
        default: return .gray
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @State private var isPulsing = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
                isPulsing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPulsing = false
            }
        }) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.1))
                        .shadow(color: color.opacity(0.2), radius: isSelected ? 4 : 0, x: 0, y: 2)
                }
                .scaleEffect(isPulsing ? 1.1 : (isSelected ? 1.05 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
                .animation(.easeInOut(duration: 0.1), value: isPulsing)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Main Search Screen
struct EnhancedSearchScreen: View {
    @StateObject private var viewModel = SearchViewModel()
    @State private var contentOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Dynamic gradient background with parallax effect
            LinearGradient(
                colors: [.blue.opacity(0.08), .purple.opacity(0.08), .clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .offset(y: contentOffset * 0.5)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Search Bar with bounce effect
                ModernSearchBar(
                    text: $viewModel.searchText,
                    onCancel: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            viewModel.searchResults = []
                        }
                    },
                    onSubmit: {
                        if !viewModel.searchText.isEmpty {
                            viewModel.addToRecentSearches(viewModel.searchText)
                        }
                    }
                )
                .padding(.horizontal)
                .offset(y: contentOffset > 0 ? -contentOffset * 0.2 : 0)

                // Category Filter with slide animation
                if !viewModel.searchText.isEmpty || viewModel.selectedCategory != nil {
                    CategoryFilterView(
                        categories: viewModel.categories,
                        selectedCategory: $viewModel.selectedCategory
                    )
                    .padding(.top, 12)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity).combined(with: .scale),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                }

                // Content with scroll tracking
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear
                            .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                    }
                    .frame(height: 0)

                    LazyVStack(spacing: 16) {
                        if viewModel.searchText.isEmpty {
                            trendingSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))

                            recentSearchesSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))

                            suggestionsSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        } else if viewModel.isLoading {
                            loadingView
                                .transition(.scale.combined(with: .opacity))
                        } else if viewModel.searchResults.isEmpty {
                            emptyStateView
                                .transition(.scale.combined(with: .opacity).combined(with: .move(edge: .bottom)))
                        } else {
                            searchResultsSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(.easeOut(duration: 0.1)) {
                        contentOffset = value
                    }
                }
            }
        }
        .navigationTitle("Discovery")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Trending Section with enhanced animations
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)

                Text("Trending Now")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(viewModel.trendingItems.enumerated()), id: \.element) { index, item in
                        TrendingCard(item: item) {
                            // Handle selection with animation
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.searchText = item.title
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .leading)),
                            removal: .scale.combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: viewModel.trendingItems.count)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Enhanced Recent Searches with grid animation
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.recentSearches.isEmpty {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                        .rotationEffect(.degrees(contentOffset * 0.1))

                    Text("Recent Searches")
                        .font(.system(.title3, design: .rounded, weight: .semibold))

                    Spacer()

                    Button("Clear") {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            viewModel.clearSearchHistory()
                        }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.blue)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(Array(viewModel.recentSearches.prefix(6).enumerated()), id: \.element) { index, search in
                        RecentSearchPill(search: search) {
                            viewModel.selectRecentSearch(search)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity).combined(with: .move(edge: .top)),
                            removal: .scale.combined(with: .opacity).combined(with: .move(edge: .leading))
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: viewModel.recentSearches.count)
                    }
                }
            }
        }
    }

    // MARK: - Search Suggestions with staggered animations
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)

                Text("Suggestions")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                Spacer()
            }

            LazyVStack(spacing: 8) {
                ForEach(Array(viewModel.searchSuggestions.enumerated()), id: \.element) { index, suggestion in
                    SuggestionRow(suggestion: suggestion) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.searchText = suggestion.text
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(Double(index) * 0.1), value: viewModel.searchSuggestions.count)
                }
            }
        }
    }

    // MARK: - Enhanced Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
            }

            Text("Searching...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)
                .scaleEffect(1.1)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: UUID())
        }
        .padding(.top, 60)
    }

    // MARK: - Enhanced Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                    .scaleEffect(1.05)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(5))
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: UUID())
            }

            VStack(spacing: 8) {
                Text("No Results Found")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                Text("Try different keywords or check spelling")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())
            }
        }
        .padding(.top, 60)
    }

    // MARK: - Search Results with cascading animation
    private var searchResultsSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(viewModel.searchResults.enumerated()), id: \.element) { index, item in
                SearchResultCard(item: item) {
                    viewModel.addToRecentSearches(viewModel.searchText)
                    print("Selected: \(item.title)")
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: viewModel.searchResults.count)
            }
        }
    }
}

// MARK: - Supporting Components with enhanced animations
struct TrendingCard: View {
    let item: SearchItem
    let onTap: () -> Void
    @State private var isHovering = false
    @State private var isVisible = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onTap()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [item.color, item.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: item.color.opacity(0.4), radius: isHovering ? 8 : 4, x: 0, y: isHovering ? 4 : 2)
                        .scaleEffect(isHovering ? 1.1 : 1.0)

                    Image(systemName: item.imageIcon)
                        .foregroundStyle(.white)
                        .font(.system(size: 24, weight: .medium))
                        .scaleEffect(isVisible ? 1.0 : 0.5)
                        .rotationEffect(.degrees(isVisible ? 0 : 180))
                }

                Text(item.title)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .opacity(isVisible ? 1.0 : 0)
            }
            .frame(width: 80)
            .scaleEffect(isVisible ? 1.0 : 0.8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                isVisible = true
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovering)
    }
}

struct RecentSearchPill: View {
    let search: String
    let onTap: () -> Void
    @State private var isVisible = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                onTap()
            }
        }) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .rotationEffect(.degrees(isVisible ? 0 : 90))

                Text(search)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(isVisible ? 1.0 : 0.5)
            .opacity(isVisible ? 1.0 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

struct SuggestionRow: View {
    let suggestion: SearchSuggestion
    let onTap: () -> Void
    @State private var isVisible = false

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: suggestion.icon)
                    .foregroundStyle(.blue)
                    .font(.system(size: 16))
                    .frame(width: 20)
                    .scaleEffect(isVisible ? 1.0 : 0.5)

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.text)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)

                    Text(suggestion.category)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .offset(x: isVisible ? 0 : -20)

                Spacer()

                Image(systemName: "arrow.up.left")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                    .offset(x: isVisible ? 0 : 10)
                    .rotationEffect(.degrees(isVisible ? 0 : 45))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .opacity(isVisible ? 1.0 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
