//
//  MapView.swift
//  RSSI
//
//  Created by woody on 2023/03/26.
//

import SwiftUI

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
  }
}
