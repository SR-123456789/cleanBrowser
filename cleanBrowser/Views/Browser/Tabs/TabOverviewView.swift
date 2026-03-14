import SwiftUI

struct TabOverviewView: View {
    @ObservedObject var viewModel: TabOverviewViewModel
    @Binding var isPresented: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(viewModel.tabs.enumerated()), id: \.element.id) { index, tab in
                        TabPreviewCard(
                            tab: tab,
                            isActive: index == viewModel.activeTabIndex,
                            onTap: {
                                viewModel.selectTab(at: index)
                                isPresented = false
                            },
                            onClose: {
                                viewModel.closeTab(at: index)
                            }
                        )
                    }
                }
                .padding(16)
            }
            .navigationTitle(viewModel.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        viewModel.addTabAndSelect()
                        isPresented = false
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        isPresented = false
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}

#Preview {
    TabOverviewView(viewModel: TabOverviewViewModel(browserStore: BrowserStore()), isPresented: .constant(true))
}
