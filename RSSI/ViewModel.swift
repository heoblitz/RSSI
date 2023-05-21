//
//  ViewModel.swift
//  RSSI
//
//  Created by woody on 2023/04/26.
//

import SwiftUI

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
  @Published var selectedLabel: MLModelLabel?

  init() { }
  
  func onAppear() {
    self.task = Task {
      while true {
        do {
          try await Task.sleep(for: .milliseconds(100))
          let rssiMap: [String: Int] = try await AirportService.shared.getRSSIMap()
          
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
            
            let filteredRSSIs = self.filtersModels.map { Double($0.rssi) }
            
            if filteredRSSIs.count == 4 {
              self.selectedLabel = CoreMLService.shared.predictLocation(features: filteredRSSIs)
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
