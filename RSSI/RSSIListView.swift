//
//  RSSIListView.swift
//  RSSI
//
//  Created by woody on 2023/03/09.
//

import SwiftUI


struct RSSIListView: View {
  @EnvironmentObject private var viewModel: ViewModel
  @State private var location: String = "A1"

  var body: some View {
    VStack {
      Text("\(self.viewModel.updateTime)")
      if self.viewModel.rissModels.isEmpty {
        HStack(spacing: 10) {
          Text("Waiting for fetching")
            .font(.title)
          
          ProgressView()
        }
      } else {
        List {
          HStack(spacing: 10) {
            TextField("Location", text: self.$location)
              .textFieldStyle(.roundedBorder)
              .frame(width: 80)
            Button("Add to Excel") {
              self.viewModel.addExcel(self.location)
            }
            Text("Current Excel Row: \(self.viewModel.excels.count)")
              .font(.title3)
            Spacer()
          }
          Section("Pin") {
            ForEach(self.viewModel.filtersModels) { rissModel in
              if rissModel.isPinned {
                HStack {
                  Toggle(
                    isOn: .init(
                      get: { rissModel.isPinned },
                      set: { isPinned in
                        guard let index = self.viewModel.rissModels.firstIndex(where: { $0.id == rissModel.id }) else { return }
                        
                        var rissModel = rissModel
                        rissModel.isPinned = isPinned
                        self.viewModel.rissModels[index] = rissModel
                      }
                    )
                  ) {

                  }
                  Text(rissModel.ssid)
                    .font(.title2)
                    .badge(
                      Text("\(Int(rissModel.rssi))")
                        .font(.title3)
                        .foregroundColor(rissModel.rssiStatusColor)
                    )
                }
              }
            }
          }
          
          Section("RSSI") {
            ForEach(self.$viewModel.rissModels) { $rissModel in
              HStack {
                Toggle(isOn: $rissModel.isPinned) {
                  
                }
                
                Text(rissModel.ssid)
                  .font(.title2)
                  .badge(
                    Text("\(Int(rissModel.rssi))")
                      .font(.title3)
                      .foregroundColor(rissModel.rssiStatusColor)
                  )
              }
            }
          }
        }
        .listStyle(.inset)
      }
    }
    .padding()
    .onAppear {
      self.viewModel.onAppear()
    }
    .onDisappear {
      self.viewModel.onDisappear()
    }
  }
}
