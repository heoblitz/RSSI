//
//  CoreMLService.swift
//  RSSI
//
//  Created by woody on 2023/05/19.
//

import Foundation
import CoreML

enum MLModelLabel: Int64, CaseIterable {
  case a1
  case a2
  case a3
  case a4
  case a5

  case b1
  case b2
  case b3
  case b4
  case b5

  case c1
  case c2
  case c3
  case c4
  case c5
  
  case d1
  case d2
  case d3
  case d4
  case d5
  
  var text: String {
    switch self {
    case .a1: return "a1"
    case .a2: return "a2"
    case .a3: return "a3"
    case .a4: return "a4"
    case .a5: return "a5"
      
    case .b1: return "b1"
    case .b2: return "b2"
    case .b3: return "b3"
    case .b4: return "b4"
    case .b5: return "b5"

    case .c1: return "c1"
    case .c2: return "c2"
    case .c3: return "c3"
    case .c4: return "c4"
    case .c5: return "c5"

    case .d1: return "d1"
    case .d2: return "d2"
    case .d3: return "d3"
    case .d4: return "d4"
    case .d5: return "d5"
    }
  }
}

final class CoreMLService {
  static let shared = CoreMLService()
  
  private let model: MLModel
  
  private init() {
    guard let model = try? RSSIModel(configuration: MLModelConfiguration()).model else {
      fatalError("Failed to load Core ML model")
    }
    
    self.model = model
  }
  
  func predictLocation(features: [Double]) -> MLModelLabel? {
    guard let inputData = try? RSSIModelInput(input: .init(features.prefix(4))) else {
      return nil
    }

    guard let prediction = try? model.prediction(from: inputData) else {
      fatalError("Failed to make prediction")
    }
    
    guard let labelValue = prediction.featureValue(for: "classLabel")?.int64Value else {
      fatalError("Failed to make prediction")
    }
    
    return MLModelLabel(rawValue: labelValue)
  }
}
