//
//  ViewModel.swift
//  RSSI
//
//  Created by woody on 2023/04/26.
//

import SwiftUI

actor ProcessWithLines {
  private let process = Process()
  private let stdin = Pipe()
  private let stdout = Pipe()
  private let stderr = Pipe()
  private var buffer = Data()
  private(set) var lines: AsyncLineSequence<FileHandle.AsyncBytes>?
  
  init() {
    process.standardInput = stdin
    process.standardOutput = stdout
    process.standardError = stderr
    process.launchPath = "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
    process.arguments = ["-s"]
  }
  
  func start() throws {
    lines = stdout.fileHandleForReading.bytes.lines
    try process.run()
  }
  
  func terminate() {
    process.terminate()
  }
  
  func send(_ string: String) {
    guard let data = "\(string)\n".data(using: .utf8) else { return }
    stdin.fileHandleForWriting.write(data)
  }
}

extension Collection {
  subscript (safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

final class AirportManager {
  static let command = "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  static let options = ["-s"]
  
  func getRSSIMap() async throws -> [String: Int] {
    let process = ProcessWithLines()
    try await process.start()
    var outputs: [String] = []
    
    guard let lines = await process.lines else {
      return [:]
    }

    for try await line in lines {
      outputs.append(line)
    }
    
    let map: [String: Int] = outputs.reduce(into: [:]) { dict, line in
      let line = line.split(separator: " ").map(String.init)

      guard let ssid = line[safe: 0], let rssi = line[safe: 1], let rssiValue = Int(rssi), rssiValue < 0 else { return }

      dict[ssid] = rssiValue
    }
    return map
  }
}


struct RissModel: Identifiable {
  let ssid: String
  var rssi: Int
  var id: String { self.ssid }
  var isPinned: Bool = false
  
  mutating func updateRssi(_ rssi: Int) {
    self.rssi = rssi
  }
  
  mutating func updateIsPinned(_ isPinned: Bool) {
    self.isPinned = isPinned
  }
  
  var rssiStatusColor: Color {
    switch rssi {
    case -70 ..< 100: return .green
    case -85 ..< -70: return .yellow
    case -100 ..< -85: return .orange
    default: return .red
    }
  }
}

@MainActor
final class ViewModel: ObservableObject {
  private let airportManager = AirportManager()
  private var task: Task<Void, Error>?
  private var disconnectCount = 0
  
  @Published var rissModels: [RissModel] = []
  
  var filtersModels: [RissModel] {
    get { self.rissModels.filter { $0.isPinned }.sorted { $0.id < $1.id } }
  }
  
  @Published var excelTitles: [String] = []
  @Published var excels: [ExcelRow] = []
  @Published var alertMessage: String = "" {
    didSet {
      guard !self.alertMessage.isEmpty else { return }
      
      self.isShowingAlert = true
    }
  }
  @Published var isShowingAlert: Bool = false
  @Published var updateTime: Date = Date()

  init() { }
  
  func onAppear() {
    self.task = Task {
      while true {
        do {
          try await Task.sleep(for: .milliseconds(100))
          let rssiMap: [String: Int] = try await airportManager.getRSSIMap()
          
          guard !rssiMap.isEmpty else { continue }
          
          if rssiMap.isEmpty {
            self.disconnectCount += 1
          }
          
          var rissModels = self.rissModels
          
          rissModels.enumerated().forEach { offset, _ in
            rissModels[offset].updateRssi(-100) // 연결 끊긴 값
          }
          
          for (key, value) in rssiMap {
            if let index = rissModels.firstIndex(where: { $0.id == key }) {
              rissModels[index].updateRssi(value)
            } else {
              rissModels.append(RissModel(ssid: key, rssi: value))
            }
          }
          
          withAnimation {
            self.updateTime = Date()
            if self.disconnectCount < 20 {
              self.rissModels = rissModels.sorted(by: { $0.rssi > $1.rssi })
            } else {
              self.disconnectCount = 0
              self.rissModels = []
            }
          }
        } catch let error {
          print(error)
          return
        }
      }
    }
  }
  
  func onDisappear() {
    self.task?.cancel()
  }
  
  deinit {
    self.task?.cancel()
  }
  
  func addExcel(_ location: String) {
    let newExcelTitles = self.filtersModels.map(\.ssid) + ["Location"]
    
    if self.excelTitles.isEmpty {
      self.excelTitles = newExcelTitles
    }
    
    if self.excelTitles != newExcelTitles {
      self.alertMessage = "Should Reset Excel Data"
      return
    }
    
    self.excels.append(ExcelRow(datas: self.filtersModels.map { String($0.rssi) }.map(ExcelData.init) + [ExcelData(data: location)]))
  }
  
  func writeExcel() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
    let timestamp = dateFormatter.string(from: Date())
    let filename = "RSSI_\(timestamp).csv"
    
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let fileURL = documentsURL.appendingPathComponent(filename)
    
    var csvText: String = ""
    
    let rowText = excelTitles.joined(separator: ",")
    csvText.append(rowText)
    csvText.append("\n")
    
    for row in self.excels {
      let rowText = row.datas.map(\.data).joined(separator: ",")
      csvText.append(rowText)
      csvText.append("\n")
    }
    
    do {
      try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
      self.alertMessage = "Saved Excel! 🎉"
    } catch {
      print("CSV 파일 저장 오류: \(error)")
    }
  }
  
  func clearExcelData() {
    self.excels.removeAll()
    self.excelTitles.removeAll()
  }
}
