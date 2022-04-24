import HealthKit
import SwiftUI

class HealthManager: ObservableObject {
    public var healthSnaps: [HealthSnapStruct] = [] // make published???

    public let healthStore = HKHealthStore()

    public func requestPermissions() {
        let readDataTypes: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
                                  HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!]

        healthStore.requestAuthorization(toShare: nil, read: readDataTypes, completion: { success, error in
            if success {
                print("Authorization complete")
                //  return true
                // self.fetchWeightData()
            } else {
                print("Authorization error: \(String(describing: error?.localizedDescription))")
                // return false
            }
        })
    }

    func makeHealthSnaps(data: DataStoreStruct) {
        var date: Date = getLastDate(moodSnaps: data.moodSnaps)
        let earliest: Date = getFirstDate(moodSnaps: data.moodSnaps)

        while date >= earliest {
            makeHealthSnapForDate(date: date)
            date = date.addDays(days: -1)
        }
    }

    func makeHealthSnapForDate(date: Date) {
        print("Fetching data")
        let startDate = date.startOfDay()
        let endDate = date.endOfDay()

        let quantityTypeWeight: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!]
        let quantityTypeDistance: Set = [HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!]

        let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                    end: endDate,
                                                    options: .strictStartDate)

        let sampleQueryWeight = HKSampleQuery(sampleType: quantityTypeWeight.first!,
                                              predicate: predicate,
                                              limit: HKObjectQueryNoLimit,
                                              sortDescriptors: nil,
                                              resultsHandler: { _, results, _ in
                                                  DispatchQueue.main.async {
                                                      let maxWeight = self.maxWeight(results: results)
                                                      if maxWeight != nil {
                                                          var healthSnap = HealthSnapStruct()
                                                          healthSnap.timestamp = date
                                                          healthSnap.weight = CGFloat(maxWeight!)
                                                          self.healthSnaps.append(healthSnap)
                                                          print("HealthSnap", healthSnap)
                                                      }
                                                  }
                                              })
        
        let sampleQueryDistance = HKSampleQuery(sampleType: quantityTypeDistance.first!,
                                                predicate: predicate,
                                                limit: HKObjectQueryNoLimit,
                                                sortDescriptors: nil,
                                                resultsHandler: { _, results, _ in
                                                    DispatchQueue.main.async {
                                                        let distance = self.totalDistance(results: results)
                                                        if distance != nil {
                                                            var healthSnap = HealthSnapStruct()
                                                            healthSnap.timestamp = date
                                                            healthSnap.walkingRunningDistance = CGFloat(distance!)
                                                            self.healthSnaps.append(healthSnap)
                                                            print("HealthSnap", healthSnap)
                                                        }
                                                    }
                                                })

        healthStore.execute(sampleQueryWeight)
        healthStore.execute(sampleQueryDistance)
    }

    /**
     Maximum weight for given HealthKit `results`
     */
    func maxWeight(results: [HKSample]?) -> Double? {
        if results == nil {
            return nil
        }

        if results!.count == 0 {
            return nil
        }

        var maxKg: Double = 0

        for result in results! {
            let thisMassSample = result as! HKQuantitySample
            let thisMassKg = thisMassSample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            maxKg = max(maxKg, thisMassKg)
        }

        return maxKg
    }

    /**
     Total distance for given HealthKit `results`
     */
    func totalDistance(results: [HKSample]?) -> Double? {
        var distance: Double = 0.0

        for result in results! {
            let thisDistanceSample = result as! HKQuantitySample
            distance += thisDistanceSample.quantity.doubleValue(for: HKUnit.meterUnit(with: .kilo))
        }
        
        return distance
    }
}
