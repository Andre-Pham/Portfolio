//
//  ChartView.swift
//  portfolio
//
//  Created by Andre Pham on 27/4/21.
//

import SwiftUI
import SwiftUICharts

struct ChartView: View {
    
    // MARK: - ChartView Properties
    
    @EnvironmentObject var chartData: ChartData
    
    // MARK: - ChartView Views
    
    var body: some View {
        // Create line chart
        LineView(data: chartData.data, title: chartData.title, legend: chartData.legend, style: chartData.lineColour).padding(.top, -40.0).padding().disabled(chartData.data.isEmpty)
        // legend is optional, use optional .padding()
        // Package SwiftUICharts has a bug where if the chart is interacted with but isn't loaded in yet, the application fatally crashes, so view interaction is disabled when empty
    }
    
}

struct ChartSwiftUIView_Previews: PreviewProvider {
    
    static var previews: some View {
        ChartView()
    }
    
}

class ChartData: ObservableObject {
    // SOURCE: https://stackoverflow.com/questions/61732887/pass-data-from-uikit-to-swiftui-container-uihostingcontroller
    // AUTHOR: James - https://stackoverflow.com/users/828768/james
    
    // MARK: - ChartData Properties
    
    @Published var title: String
    @Published var legend: String
    @Published var data: [Double] {
        didSet {
            self.updateColour()
        }
    }
    @Published var lineColour = Styles.lineChartStyleOne
    
    // MARK: - ChartData Constructor
    
    init(title: String, legend: String, data: [Double]) {
        self.title = title
        self.legend = legend
        self.data = data
    }
    
    // MARK: - ChartData Methods
    
    func updateColour() {
        if !data.isEmpty {
            if data.last! > 0 {
                let newGradient = GradientColor(
                    start: Color(UIColor(named: "Green1")  ?? Constant.BACKUP_COLOUR
                    ),
                    end: Color(UIColor(named: "Green2")  ?? Constant.BACKUP_COLOUR
                    )
                )
                let newStyle = ChartStyle(
                    backgroundColor: Color.white,
                    accentColor: Color.black,
                    gradientColor: newGradient,
                    textColor: Color.black,
                    legendTextColor: Color.gray,
                    dropShadowColor: Color.black
                )
                self.lineColour = newStyle
            }
            else if data.last! == 0 {
                let newGradient = GradientColor(
                    start: Color.gray,
                    end: Color.gray
                )
                let newStyle = ChartStyle(
                    backgroundColor: Color.white,
                    accentColor: Color.black,
                    gradientColor: newGradient,
                    textColor: Color.black,
                    legendTextColor: Color.gray,
                    dropShadowColor: Color.black
                )
                self.lineColour = newStyle
            }
            else {
                self.lineColour = Styles.lineChartStyleOne
            }
        }
    }
    
}

