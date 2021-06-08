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
        // PACKAGE SOURCE: https://github.com/AppPear/ChartView
        // PACKAGE LICENSE: https://github.com/AppPear/ChartView/blob/master/LICENSE
        
        // Create line chart
        LineView(data: chartData.data, title: chartData.title, legend: chartData.legend, style: chartData.lineColour).padding(.top, -40.0).padding().disabled(chartData.data.isEmpty)
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
    
    // MARK: - Properties
    
    @Published var title: String
    @Published var legend: String
    @Published var data: [Double] {
        didSet {
            // Update graph colour
            self.updateColour()
        }
    }
    @Published var lineColour = Styles.lineChartStyleOne
    
    // MARK: - Constructor
    
    init(title: String, legend: String, data: [Double]) {
        self.title = title
        self.legend = legend
        self.data = data
    }
    
    // MARK: - Methods
    
    /// Updates the graph's colour to match trends
    func updateColour() {
        if !data.isEmpty {
            if data.last! > 0 {
                // Positive growth
                
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
                // Neither positive nor negative
                
                let newGradient = GradientColor(
                    // Backup colour is neutral grey
                    start: Color(Constant.BACKUP_COLOUR),
                    end: Color(Constant.BACKUP_COLOUR)
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

