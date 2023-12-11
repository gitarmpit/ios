//
//  ContentView.swift
//  hktest
//
//  Created by zolo on 11/30/23.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Hello, world!")
        }
        .padding()
        .onAppear() {
            do
            {
                let typesToRead: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .stepCount)!, HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, HKObjectType.quantityType(forIdentifier: .heartRate)!]
                
                let typesToWrite: Set<HKSampleType> = [HKObjectType.quantityType(forIdentifier: .stepCount)!, HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!]
                
                let healthStore = HKHealthStore()
                try healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { (success, error) in
                    if success {
                        // Success
                    } else {
                        // Error handle
                    }
                }
            }
            catch {
                
            }
        }
    }
        
}

