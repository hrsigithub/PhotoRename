//
//  FileHelper.swift
//  PhotoRename
//
//  Created by Hiroshi.Nakai on 2024/10/20.
//

import Foundation
import CoreGraphics
import ImageIO

/// <#Description#>
class FileHelper {
  
  // 日付を"yyyyMMdd_HHmm"形式の文字列に変換
  static func formattedDateString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmm"
    return formatter.string(from: date)
  }
  
  func uniqueFileName(at directoryURL: URL, baseName: String, extension ext: String) -> URL {
    var uniqueName = baseName
    var counter = 1
    var destinationURL = directoryURL.appendingPathComponent("\(uniqueName).\(ext)")
    
    // ファイルが存在する場合はサフィックスを追加
    while FileManager.default.fileExists(atPath: destinationURL.path) {
      uniqueName = "\(baseName)_\(counter)"
      destinationURL = directoryURL.appendingPathComponent("\(uniqueName).\(ext)")
      counter += 1
    }
    
    return destinationURL
  }
  
  
  // 指定フォルダ内のファイルをリネーム
  static func renameFiles(in folderURL: URL, progressUpdate: @escaping (Double) -> Void, completion: @escaping (Int) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
      let fileManager = FileManager.default
      let keys: [URLResourceKey] = [.isRegularFileKey]
      
      do {
        let fileURLs = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: keys)
        let imageFileURLs = fileURLs.filter { $0.pathExtension.lowercased() == "jpeg" || $0.pathExtension.lowercased() == "jpg" }
        
        let totalFiles = imageFileURLs.count
        var progress: Double = 0
        
        for imageFileURL in imageFileURLs {
          do {
            let imageSource = CGImageSourceCreateWithURL(imageFileURL as CFURL, nil)
            if let imageSource = imageSource,
               let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
               let exifDict = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
               let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal] as? String {
              
              let formatter = DateFormatter()
              formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
              if let date = formatter.date(from: dateString) {
                
                let newFileName = formattedDateString(from: date) + "." + imageFileURL.pathExtension
                
                let newFileURL = folderURL.appendingPathComponent(newFileName)
                try fileManager.moveItem(at: imageFileURL, to: newFileURL)
                
              }
            }
          } catch {
            print("Error processing file \(imageFileURL): \(error)")
          }
          
          progress += 1
          DispatchQueue.main.async {
            progressUpdate(progress / Double(totalFiles))
          }
        }
        
        DispatchQueue.main.async {
          completion(totalFiles)
        }
        
      } catch {
        print("Error reading directory: \(error)")
      }
    }
  }
}
