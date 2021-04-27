//
//  ChartSwiftUIView.swift
//  portfolio
//
//  Created by Andre Pham on 27/4/21.
//

import SwiftUI
import SwiftUICharts

struct ChartSwiftUIView: View {
    var body: some View {
        LineView(data: [8,23,54,32,12,37,7,23,43,-5], title: "MSFT", legend: "Percentage Gain").padding() // legend is optional, use optional .padding()
    }
}

struct ChartSwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        ChartSwiftUIView()
    }
}
