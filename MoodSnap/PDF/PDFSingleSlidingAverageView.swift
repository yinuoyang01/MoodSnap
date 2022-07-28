import SwiftUI

struct PDFSingleSlidingAverageView: View {
    var type: MoodsEnum
    var timescale: Int
    var data: DataStoreClass
    var blackAndWhite: Bool
    
    var body: some View {
        let entries = [Array(data.processedData.averageE.suffix(28)),
                       Array(data.processedData.averageD.suffix(28)),
                       Array(data.processedData.averageA.suffix(28)),
                       Array(data.processedData.averageI.suffix(28))]
        
        if blackAndWhite {
            VerticalBarChart(values: entries[type.rawValue],
                             color: Color.black,
                             min: 0,
                             max: 4,
                             horizontalGridLines: 0,
                             verticalGridLines: 0,
                             blackAndWhite: true,
                             shaded: true,
                             settings: data.settings)
            .frame(height: 65)
        } else {
            let color = moodUIColors(settings: data.settings)[type.rawValue]
            VerticalBarChart(values: entries[type.rawValue],
                             color: Color(color),
                             min: 0,
                             max: 4,
                             horizontalGridLines: 0,
                             verticalGridLines: 0,
                             blackAndWhite: false,
                             shaded: true,
                             settings: data.settings)
            .frame(height: 65)
        }
    }
}
