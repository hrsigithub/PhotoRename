import SwiftUI

struct ContentView: View {
  
  @State private var folderPath: String = ""
  @State private var isProcessing: Bool = false
  @State private var progress: Double = 0.0
  @State private var totalFiles: Int = 0
  @State private var showAlert: Bool = false
  @State private var alertMessage: String = ""
  @State private var totalFilesRenamed: Int = 0
  
  var body: some View {
    VStack {
      // フォルダが選択されているかを表示
      Text("Selected Folder: \(folderPath.isEmpty ? "None" : folderPath)")
        .padding()
      
      // フォルダ選択ボタン
      Button("Select Folder") {
        selectFolder()
      }
      .padding()
      .disabled(isProcessing) // 処理中はボタンを無効化
      
      // 進捗バーの表示
      if isProcessing {
        ProgressView(value: progress)
          .padding()
      }
      
      // リネームされたファイル数の表示
      if totalFilesRenamed > 0 {
        Text("Renamed \(totalFilesRenamed) files")
          .padding()
      }
      
    }
    .alert(isPresented: $showAlert) {
      Alert(title: Text("Process Completed"),
            message: Text(alertMessage),
            dismissButton: .default(Text("OK")))
    }
    .padding()
  }
  
  // フォルダ選択処理
  func selectFolder() {
    let dialog = NSOpenPanel()
    dialog.canChooseFiles = false
    dialog.canChooseDirectories = true
    dialog.allowsMultipleSelection = false
    
    if dialog.runModal() == .OK {
      if let url = dialog.url {
        folderPath = url.path
        processFolder(url)
      }
    }
  }
  
  // フォルダ内ファイルのリネーム処理
  func processFolder(_ folderURL: URL) {
    isProcessing = true
    progress = 0
    totalFilesRenamed = 0
    
    // FileHelperクラスのリネーム処理を呼び出す
    FileHelper.renameFiles(in: folderURL, progressUpdate: { progressValue in
      DispatchQueue.main.async {
        progress = progressValue
      }
    }, completion: { total in
      DispatchQueue.main.async {
        isProcessing = false
        totalFilesRenamed = total
        alertMessage = "Renamed \(total) files successfully."
        showAlert = true
      }
    })
  }
}

#Preview {
  ContentView()
}

