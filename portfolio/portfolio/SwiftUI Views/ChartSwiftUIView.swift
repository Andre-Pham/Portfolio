//
//  ChartSwiftUIView.swift
//  portfolio
//
//  Created by Andre Pham on 27/4/21.
//

import SwiftUI
import SwiftUICharts

struct ChartSwiftUIView: View {
    @EnvironmentObject var chartObject: ChartObject
    
    var body: some View {
        LineView(data: chartObject.data, title: chartObject.title, legend: chartObject.legend).padding(.top, -40.0).padding() // legend is optional, use optional .padding()
    }
}

struct ChartSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ChartSwiftUIView()
    }
}

// SOURCE: https://stackoverflow.com/questions/61732887/pass-data-from-uikit-to-swiftui-container-uihostingcontroller
// AUTHOR: James - https://stackoverflow.com/users/828768/james
class ChartObject: ObservableObject {
    @Published var title: String
    @Published var legend: String
    @Published var data: [Double]
    
    init(title: String, legend: String, data: [Double]) {
        self.title = title
        self.legend = legend
        self.data = data
    }
}

