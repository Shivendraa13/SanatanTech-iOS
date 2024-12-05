//
//  StepCount+CoreDataProperties.swift
//  SanatanTech-App
//
//  Created by Preyash on 05/12/24.
//
//

import Foundation
import CoreData


extension StepCount {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StepCount> {
        return NSFetchRequest<StepCount>(entityName: "StepCount")
    }

    @NSManaged public var steps: Int64
    @NSManaged public var date: Date?

}

extension StepCount : Identifiable {

}
