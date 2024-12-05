//
//  HeartRate+CoreDataProperties.swift
//  SanatanTech-App
//
//  Created by Preyash on 05/12/24.
//
//

import Foundation
import CoreData


extension HeartRate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HeartRate> {
        return NSFetchRequest<HeartRate>(entityName: "HeartRate")
    }

    @NSManaged public var heartRate: Double
    @NSManaged public var date: Date?

}

extension HeartRate : Identifiable {

}
