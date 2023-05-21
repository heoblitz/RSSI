//
//  MapView.swift
//  RSSI
//
//  Created by woody on 2023/03/26.
//

import SwiftUI
import CoreML

struct MapView: View {
  @EnvironmentObject private var viewModel: ViewModel
  private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0), count: 5)

  var body: some View {
    ScrollView {
      VStack {
        Text("\(self.viewModel.updateTime)")

        LazyVGrid(columns: columns, spacing: 0) {
          ForEach(MLModelLabel.allCases, id: \.self) { label in
            ZStack {
              if self.viewModel.selectedLabel == label {
                Color.pink
              } else {
                Color.gray
              }
              Text("\(label.text)")
            }
            .frame(height: 120)
            .border(.black)
          }
        }
      }
    }
  }
}
