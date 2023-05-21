//
//  AirportSerivce.swift
//  RSSI
//
//  Created by woody on 2023/05/19.
//

import Foundation

actor ProcessWithLines {
  static let command = "/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  static let options = ["-s"]
  
  private let process = Process()
  private let stdin = Pipe()
  private let stdout = Pipe()
  private let stderr = Pipe()
  private var buffer = Data()
  private(set) var lines: AsyncLineSequence<FileHandle.AsyncBytes>?
  
  init() {
    self.process.standardInput = stdin
    self.process.standardOutput = stdout
    self.process.standardError = stderr
    self.process.launchPath = Self.command
    self.process.arguments = Self.options
  }
  
  func start() throws {
    self.lines = stdout.fileHandleForReading.bytes.lines
    try self.process.run()
  }
  
  func terminate() {
    self.process.terminate()
  }
  
  func send(_ string: String) {
    guard let data = "\(string)\n".data(using: .utf8) else { return }
    
    self.stdin.fileHandleForWriting.write(data)
  }
}

extension Collection {
  subscript (safe index: Index) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

final class AirportService{
  static let shared = AirportService()
  
  private init() { }
  
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
