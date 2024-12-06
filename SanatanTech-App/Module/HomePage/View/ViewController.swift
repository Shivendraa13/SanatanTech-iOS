//
//  ViewController.swift
//  SanatanTech-App
//
//  Created by Shivendra on 05/12/24.
//

import UIKit
import HealthKit
import CoreData


class ViewController: UIViewController {
    
    @IBOutlet weak var heartDataTableView: UITableView!
    @IBOutlet weak var stepDataTableView: UITableView!
    
    let healthStore = HKHealthStore()
    var persistentContainer: NSPersistentContainer! 
    var context: NSManagedObjectContext!
    
    
    private var stepData = [StepData]()
    private var heartData = [HeartData]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            persistentContainer = appDelegate.persistentContainer
            context = persistentContainer.viewContext
        } else {
            fatalError("Unable to access AppDelegate or PersistentContainer")
        }
        
        fetchSavedData()
        requestAuthorization()
        setTableView()
    }
    
    func setTableView() {
        let cellNib = UINib(nibName: "DataCell", bundle: nil)
        heartDataTableView.register(cellNib, forCellReuseIdentifier: "DataCell")
        stepDataTableView.register(cellNib, forCellReuseIdentifier: "DataCell")
    }
    
    func requestAuthorization() {
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        healthStore.requestAuthorization(toShare: nil, read: [stepCountType, heartRateType]) { success, error in
            if success {
                print("Authorization granted!")
                self.fetchStepCountData()
                self.fetchHeartRateData()
            } else {
                print("Authorization denied: \(error?.localizedDescription ?? "No error")")
            }
        }
    }
    
    func fetchStepCountData() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }
        
        var interval = DateComponents()
        interval.day = 1
        
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: nil,
            options: .cumulativeSum,
            anchorDate: calendar.startOfDay(for: startDate),
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
            if let statsCollection = results {
                statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let steps = sum.doubleValue(for: HKUnit.count())
                        let stepDate = statistics.startDate
                        
                        self.saveStepCountData(steps: steps, date: stepDate)
                        print("Steps on \(stepDate): \(steps)")
                    }
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    
    func saveStepCountData(steps: Double, date: Date) {
        let stepCountEntity = StepCount(context: context)
        stepCountEntity.steps = Int64(steps)
        stepCountEntity.date = date
        
        do {
            try context.save()
            print("Step data saved successfully")
        } catch {
            print("Error saving step data: \(error.localizedDescription)")
        }
    }
    
    
    func fetchHeartRateData() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { query, samples, error in
            if let samples = samples as? [HKQuantitySample] {
                for sample in samples {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    let heartRateDate = sample.startDate
                    self.saveHeartRateData(heartRate: heartRate, date: heartRateDate)
                    print("Heart Rate on \(heartRateDate): \(heartRate) BPM")
                }
            } else {
                print("Error fetching heart rate data: \(error?.localizedDescription ?? "No error")")
            }
        }
        
        healthStore.execute(query)
    }
    
    func saveHeartRateData(heartRate: Double, date: Date) {
        let heartRateEntity = HeartRate(context: context)
        heartRateEntity.heartRate = heartRate
        heartRateEntity.date = date
        
        do {
            try context.save()
            print("Heart rate data saved successfully")
        } catch {
            print("Error saving heart rate data: \(error.localizedDescription)")
        }
    }
    
    func fetchSavedData() {
        let fetchRequest: NSFetchRequest<StepCount> = StepCount.fetchRequest()
        let fetchRequest1: NSFetchRequest<HeartRate> = HeartRate.fetchRequest()
        
        do {
            let savedSteps = try context.fetch(fetchRequest)
            for step in savedSteps {
//                print("Saved Step Count: \(step.steps), Date: \(step.date)")
                stepData.append(StepData(stepCount: Int(step.steps), Date: formatDate(step.date)))
            }
        } catch {
            print("Error fetching saved steps: \(error.localizedDescription)")
        }
        
        do {
            let savedSteps = try context.fetch(fetchRequest1)
            for step in savedSteps {
//                print("Saved Heart Count: \(step.heartRate), Date: \(step.date)")
                heartData.append(HeartData(heartRate: Double(step.heartRate), Date: formatDate(step.date)))
            }
        } catch {
            print("Error fetching saved steps: \(error.localizedDescription)")
        }
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }

}

extension ViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == heartDataTableView {
            return heartData.count
        } else if tableView == stepDataTableView {
            return stepData.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == heartDataTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath) as! DataCell
            cell.heartRateLabel.text = "Heart Rate: \(heartData[indexPath.item].heartRate ?? 0.0)"
            cell.dateLabel.text = "\(heartData[indexPath.item].Date ?? "")"
            return cell
        } else if tableView == stepDataTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DataCell", for: indexPath) as! DataCell
            cell.heartRateLabel.text = "Step Count; \(stepData[indexPath.item].stepCount ?? 0)"
            cell.dateLabel.text = "\(stepData[indexPath.item].Date ?? "")"
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.contentView.layer.cornerRadius = 8
        cell.contentView.layer.masksToBounds = false
        cell.backgroundColor = .clear
        let margin = 10.0
        cell.contentView.frame = cell.contentView.frame.insetBy(dx: margin, dy: margin / 2)
    }
}
