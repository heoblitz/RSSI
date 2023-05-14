//
//  RSSIApp.swift
//  RSSI
//
//  Created by woody on 2023/03/09.
//

import SwiftUI
import CoreML

@main
struct RSSIApp: App {
  @StateObject private var viewModel = ViewModel()

  var body: some Scene {
    WindowGroup {
      TabView {
        RSSIListView()
          .tabItem {
            Text("RSSI")
          }
        ExcelView()
          .tabItem {
            Text("Excel")
          }
        MapView()
          .tabItem {
            Text("Map")
          }
      }
      .environmentObject(viewModel)
      .alert(self.viewModel.alertMessage, isPresented: self.$viewModel.isShowingAlert) {
        
      }
    }
  }
}
