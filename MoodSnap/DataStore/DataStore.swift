import Disk
import SwiftUI
import WidgetKit

/**
 Struct for main data storage type.
 */
struct DataStoreStruct: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var version: Int = 1

    var settings: SettingsStruct = SettingsStruct()
    var uxState: UXStateStruct = UXStateStruct()
    var moodSnaps: [MoodSnapStruct] = makeIntroSnap()
    var healthSnaps: [HealthSnapStruct] = []
    var processedData: ProcessedDataStruct = ProcessedDataStruct()
}

/**
 Class for main data storage type.
 */
final class DataStoreClass: Identifiable, ObservableObject {
    var id: UUID = UUID()
    var version: Int = 1

    @Published var settings: SettingsStruct = SettingsStruct()
    @Published var uxState: UXStateStruct = UXStateStruct()
    @Published var moodSnaps: [MoodSnapStruct] = makeIntroSnap()
    @Published var processedData: ProcessedDataStruct = ProcessedDataStruct()
    @Published var processingTask: Task<Void, Never>? = nil
    @Published var hashtagList: [String] = []
    @Published var eventsList: [(String,Date)] = []
    @Published var symptomOccurrenceCount: Int = 0
    @Published var activityOccurrenceCount: Int = 0
    @Published var socialOccurrenceCount: Int = 0
    @Published var hashtagOccurrenceCount: Int = 0
    @Published var eventOccurrenceCount: Int = 0
    var sequencedMoodSnaps: [[MoodSnapStruct]] = []
    var flattenedSequencedMoodSnaps: [MoodSnapStruct?] = []
    var healthSnaps: [HealthSnapStruct] = []
    var hapticGeneratorLight = UIImpactFeedbackGenerator(style: .light)
    
//    init() {
//        self.id = UUID()
//        self.settings = SettingsStruct()
//        self.uxState = UXStateStruct()
//        self.moodSnaps = makeIntroSnap()
//        self.healthSnaps = []
//
//        do {
//            let retrieved = try Disk.retrieve(
//                "data.json",
//                from: .documents,
//                as: DataStoreStruct.self)
//
//            self.id = retrieved.id
//            self.version = retrieved.version
//            self.settings = retrieved.settings
//            self.uxState = retrieved.uxState
//            self.moodSnaps = retrieved.moodSnaps
//            self.healthSnaps = retrieved.healthSnaps
//            self.processedData = retrieved.processedData
//        } catch {
//        }
//    }
    
    init(shared: Bool = false, process: Bool = false) {
        self.id = UUID()
        self.settings = SettingsStruct()
        self.uxState = UXStateStruct()
        self.moodSnaps = makeIntroSnap()
        self.healthSnaps = []
        
        do {
            if shared == false {
                let retrieved = try Disk.retrieve(
                    "data.json",
                    from: .documents,
                    as: DataStoreStruct.self)
                
                self.id = retrieved.id
                self.version = retrieved.version
                self.settings = retrieved.settings
                self.uxState = retrieved.uxState
                self.moodSnaps = retrieved.moodSnaps
                self.healthSnaps = retrieved.healthSnaps
                self.processedData = retrieved.processedData
            } else {
                let retrieved = try Disk.retrieve(
                    "data.json",
                    from: .sharedContainer(appGroupName: "group.MoodSnap"),
                    as: DataStoreStruct.self)
                
                self.id = retrieved.id
                self.version = retrieved.version
                self.settings = retrieved.settings
                self.uxState = retrieved.uxState
                self.moodSnaps = retrieved.moodSnaps
                self.healthSnaps = retrieved.healthSnaps
                self.processedData = retrieved.processedData
            }
        } catch {
        }
        
        if process {
            self.startProcessing()
        }
    }

    /**
     Process history
     */
    func processHistory() async -> Bool {
        let history = await generateHistory(data: self)

        DispatchQueue.main.async {
            // Mood history
            self.processedData.levelE = history.levelE
            self.processedData.levelD = history.levelD
            self.processedData.levelA = history.levelA
            self.processedData.levelI = history.levelI
            
            // Sliding average history
            self.processedData.averageE = history.averageE
            self.processedData.averageD = history.averageD
            self.processedData.averageA = history.averageA
            self.processedData.averageI = history.averageI
            
            // Volatility history
            self.processedData.volatilityE = history.volatilityE
            self.processedData.volatilityD = history.volatilityD
            self.processedData.volatilityA = history.volatilityA
            self.processedData.volatilityI = history.volatilityI
        }
        
        return true
    }
    
    /**
     Process events
     */
    func processEvents() async -> Bool {
        let eventsListUI = getEventsList(data: self)
        var eventButterflies: [ButterflyEntryStruct] = []
        for i in 0 ..< eventsListUI.count {
            let dates = [eventsListUI[i].1]
            var thisButterfly = averageTransientForDates(
                dates: dates,
                data: self,
                maxWindow: butterflyWindowLong)
            thisButterfly.activity = eventsListUI[i].0
            thisButterfly.timestamp = eventsListUI[i].1
            eventButterflies.append(thisButterfly)
        }
        let eventButterfliesUI = eventButterflies
        let eventOccurrenceCountUI = countAllOccurrences(butterflies: eventButterflies)
        DispatchQueue.main.async {
            self.eventsList = eventsListUI
            self.processedData.eventButterfly = eventButterfliesUI
            self.eventOccurrenceCount = eventOccurrenceCountUI
        }
        return true
    }
    
    /**
     Process hashtags
     */
    func processHashtags() async -> Bool {
        let hashtagListUI = getHashtags(data: self)
        var hashtagButterflies: [ButterflyEntryStruct] = []
        for i in 0 ..< hashtagListUI.count {
            let dates = getDatesForHashtag(
                hashtag: hashtagListUI[i],
                moodSnaps: self.moodSnaps)
            var thisButterfly = averageTransientForDates(
                dates: dates,
                data: self,
                maxWindow: butterflyWindowShort)
            thisButterfly.activity = hashtagListUI[i]
            hashtagButterflies.append(thisButterfly)
        }
        let hashtagButterfliesUI = hashtagButterflies
        let hashtagOccurrenceCountUI = countAllOccurrences(butterflies: hashtagButterflies)
        DispatchQueue.main.async {
            self.hashtagList = hashtagListUI
            self.processedData.hashtagButterfly = hashtagButterfliesUI
            self.hashtagOccurrenceCount = hashtagOccurrenceCountUI
        }
        return true
    }

    /**
     Process activities
     */
    func processActivities() async -> Bool {
        var activityButterflies: [ButterflyEntryStruct] = []
        for i in 0 ..< activityList.count {
            let dates = getDatesForType(
                type: .activity,
                item: i,
                data: self)
            var thisButterfly = averageTransientForDates(
                dates: dates,
                data: self,
                maxWindow: butterflyWindowShort)
            thisButterfly.activity = activityList[i]
            activityButterflies.append(thisButterfly)
        }
        let activityButterfliesUI = activityButterflies
        let activityOccurrenceCountUI = countAllOccurrences(butterflies: activityButterflies)
        DispatchQueue.main.async {
            self.processedData.activityButterfly = activityButterfliesUI
            self.activityOccurrenceCount = activityOccurrenceCountUI
        }
        return true
    }
    
    /**
     Process symptoms
     */
    func processSymptoms() async -> Bool {
        var symptomButterflies: [ButterflyEntryStruct] = []
        for i in 0 ..< symptomList.count {
            let dates = getDatesForType(
                type: .symptom,
                item: i,
                data: self)
            var thisButterfly = averageTransientForDates(
                dates: dates,
                data: self,
                maxWindow: butterflyWindowShort)
            thisButterfly.activity = symptomList[i]
            symptomButterflies.append(thisButterfly)
        }
        let symptomButterfliesUI = symptomButterflies
        let symptomOccurrenceCountUI = countAllOccurrences(butterflies: symptomButterflies)
        DispatchQueue.main.async {
            self.processedData.symptomButterfly = symptomButterfliesUI
            self.symptomOccurrenceCount = symptomOccurrenceCountUI
        }
        return true
    }
    
    /**
     Process social
     */
    func processSocial() async -> Bool {
        var socialButterflies: [ButterflyEntryStruct] = []
        for i in 0 ..< socialList.count {
            let dates = getDatesForType(
                type: .social,
                item: i,
                data: self)
            var thisButterfly = averageTransientForDates(
                dates: dates,
                data: self,
                maxWindow: butterflyWindowShort)
            thisButterfly.activity = socialList[i]
            socialButterflies.append(thisButterfly)
        }
        let socialButterfliesUI = socialButterflies
        let socialOccurrenceCountUI = countAllOccurrences(butterflies: socialButterflies)
        DispatchQueue.main.async {
            self.processedData.socialButterfly = socialButterfliesUI
            self.socialOccurrenceCount = socialOccurrenceCountUI
        }
        return true
    }
    
    /**
     Pre-process data.
     */
    func process() async {
        // Sequence MoodSnaps
        self.sequencedMoodSnaps = await sequenceMoodSnaps(moodSnaps: self.moodSnaps)
        self.flattenedSequencedMoodSnaps = await flattenSequence(sequence: self.sequencedMoodSnaps)
        
        // Processing
        async let historyComplete = processHistory()
        async let eventsComplete = processEvents()
        async let hashtagsComplete = processHashtags()
        async let activitiesComplete = processActivities()
        async let socialComplete = processSocial()
        async let symptomsComplete = processSymptoms()
        
        // Wait for all asynchronous threads to complete
        await _ = [historyComplete, eventsComplete, hashtagsComplete, activitiesComplete, socialComplete, symptomsComplete]
    }

    /**
     Start asynchronous processing of data
     */
    @inline(__always) func startProcessing(priority: TaskPriority = .high) {
        self.stopProcessing()
        self.save()
        
        DispatchQueue.main.async {
            self.processingTask = Task(priority: priority) {
                await self.process()
                DispatchQueue.main.async {
                    self.processingTask = nil
                }
            }
        }
    }
    
    /**
     Stop asynchronous processing of data.
     */
    @inline(__always) func stopProcessing() {
        if self.processingTask != nil {
            self.processingTask?.cancel()
        }
        DispatchQueue.main.async {
            self.processingTask = nil
        }
    }
    
    /**
     Dave `DataStoreClass` to disk.
     */
    @inline(__always) func save() {
        do {
            try Disk.save(self.toStruct(),
                          to: .documents,
                          as: "data.json")
        } catch {
        }
        
        do {
            try Disk.save(self.toStruct(),
                          to: .sharedContainer(appGroupName: "group.MoodSnap"),
                          as: "data.json")
        } catch {
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /**
     Convert class to struct
     */
    @inline(__always) func toStruct() -> DataStoreStruct {
        var dataStore: DataStoreStruct = DataStoreStruct()
        
        dataStore.id = self.id
        dataStore.version = self.version
        dataStore.settings = self.settings
        dataStore.uxState = self.uxState
        dataStore.moodSnaps = self.moodSnaps
        dataStore.healthSnaps = self.healthSnaps
        dataStore.processedData = self.processedData
        
        return dataStore
    }
}
