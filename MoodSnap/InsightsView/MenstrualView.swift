import SwiftUI

struct MenstrualView: View {
    var timescale: Int
    var data: DataStoreStruct
    var health: HealthManager 

    var body: some View {
        let samples: Int = countHealthSnaps(healthSnaps: health.healthSnaps, type: .menstrual)
       // let average: CGFloat = average(healthSnaps: health.healthSnaps, type: .menstrual) ?? 0.0
        //let averageStr: String = String(format: "%.1f", average) + "kg"
       // let r2mood: [CGFloat?] = getCorrelation(data: data, health: health, type: .menstrual)
        let weightData: [CGFloat?] = getMenstrualData(data: data, health: health)
        // let entries = makeBarData(y: weightData, timescale: timescale)
        let entries2 = makeBarData2(y: weightData, timescale: timescale)
        
        if samples == 0 {//|| r2mood[0] == nil || r2mood[1] == nil || r2mood[2] == nil || r2mood[3] == nil {
            Text("insufficient_data")
                .font(.caption)
                .foregroundColor(.secondary)
        } else {
            VerticalBarChart2(values: entries2, color: themes[data.settings.theme].buttonColor, min: 0, max: 1, settings: data.settings)
                .frame(height: 60)
        }
    }
}

// import SwiftUI
// import Charts
//
// struct MenstrualView: View {
//    var data: DataStoreStruct
//
//    var body: some View {
//        let samplesE = getMenstrualMoodDistribution(type: .elevation, data: data)
//        let samplesD = getMenstrualMoodDistribution(type: .depression, data: data)
//        let samplesA = getMenstrualMoodDistribution(type: .anxiety, data: data)
//        let samplesI = getMenstrualMoodDistribution(type: .irritability, data: data)
//
//        let scatterE = makeLineData(x: samplesE.0, y: samplesE.1)
//        let scatterD = makeLineData(x: samplesD.0, y: samplesD.1)
//        let scatterA = makeLineData(x: samplesA.0, y: samplesA.1)
//        let scatterI = makeLineData(x: samplesI.0, y: samplesI.1)
//
//        let color = moodUIColors(settings: data.settings)
//
//        VStack(alignment: .center) {
//            if (samplesE.0.count == 0) {
//                Text("Insufficient data")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            } else {
//                ScatterChart(entries: scatterE, color: color[0], zeroOrigin: true)
//                    .frame(height: 170)
//                ScatterChart(entries: scatterD, color: color[1], zeroOrigin: true)
//                    .frame(height: 170)
//                ScatterChart(entries: scatterA, color: color[2], zeroOrigin: true)
//                    .frame(height: 170)
//                ScatterChart(entries: scatterI, color: color[3], zeroOrigin: true)
//                    .frame(height: 170)
//                Text("Days since last cycle")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding([.top], -10)
//            }
//        }
//    }
// }
