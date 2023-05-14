//
//  MapView.swift
//  RSSI
//
//  Created by woody on 2023/03/26.
//

import SwiftUI
import CoreML

struct MapView: View {
  var body: some View {
    var columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0), count: 10)
    
    ScrollView {
      LazyVGrid(columns: columns, spacing: 0) {
        ForEach((1...50), id: \.self) { num in
          ZStack {
            if num == 16 {
              Color.pink
            } else {
              Color.gray
            }
            Text("\(num)")
          }
          .frame(height: 120)
          .border(.black)

        }
      }
    }
    .onAppear {

      // Core ML 모델 로드
      guard let model = try? RSSIModel(configuration: MLModelConfiguration()).model else {
          fatalError("Failed to load Core ML model")
      }

      // 입력 데이터 생성
      let inputData = RSSIModelInput(input: try! .init([-44, -54, -48, -50]))

      // 모델 예측 수행
      guard let prediction = try? model.prediction(from: inputData) else {
          fatalError("Failed to make prediction")
      }

      // 예측 결과 가져오기
      let outputData = prediction.featureNames
      print(prediction.featureValue(for: "classLabel"))
      print(outputData)
    }
  }
}
