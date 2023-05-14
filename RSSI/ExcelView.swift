//
//  ExcelView.swift
//  RSSI
//
//  Created by woody on 2023/04/22.
//

import SwiftUI
import SecurityFoundation

struct ExcelRow: Identifiable {
  let id = UUID()
  var datas: [ExcelData]
}

struct ExcelData: Identifiable {
  let id = UUID()
  var data: String
}

struct ExcelView: View {
  @EnvironmentObject private var viewModel: ViewModel
  @State private var isShowingClearButton: Bool = false
  
  var body: some View {
    List {
      HStack(spacing: 5) {
        Button("Export Excel File") {
          self.viewModel.writeExcel()
        }
        Button("Clear Excel Data") {
          self.isShowingClearButton = true
        }
        Text("Current Excel Row: \(self.viewModel.excels.count)")
          .font(.title3)
      }
      Section("Excel") {
        VStack {
          HStack {
            ForEach(self.viewModel.excelTitles, id: \.self) { titles in
              Text(titles)
                .lineLimit(1)
                .font(.title2)
                .frame(width: 100, alignment: .leading)
            }
          }
          
          ForEach(self.$viewModel.excels) { $excel in
            HStack {
              ForEach($excel.datas) { $data in
                TextField("Target", text: $data.data)
                  .frame(width: 100, alignment: .leading)
              }
            }
          }
        }
      }
    }
    .listStyle(.inset)
    .confirmationDialog("Clear Excel Data?", isPresented: self.$isShowingClearButton) {
      Button("Clear", role: .destructive) {
        self.viewModel.clearExcelData()
      }
      Button("Cancel", role: .cancel) { }
    }
  }
}
  
