import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var viewModel: TranslationViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("选择语言类型", selection: $selectedTab) {
                    Text("源语言").tag(0)
                    Text("目标语言").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                List {
                    ForEach(viewModel.availableLanguages) { language in
                        LanguageRow(
                            language: language,
                            isSelected: selectedTab == 0
                                ? viewModel.sourceLanguage == language
                                : viewModel.targetLanguage == language
                        )
                        .onTapGesture {
                            if selectedTab == 0 {
                                viewModel.setSourceLanguage(language)
                            } else {
                                viewModel.setTargetLanguage(language)
                            }
                        }
                    }
                }
            }
            .navigationTitle("选择语言")
        }
    }
}

struct LanguageRow: View {
    let language: Language
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Text(language.name)
                .font(.body)
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }
} 
