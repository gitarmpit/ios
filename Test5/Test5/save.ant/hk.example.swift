    private func requestAuth() {
        let typesToRead: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .stepCount)!, HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!, HKObjectType.quantityType(forIdentifier: .heartRate)!]

        let typesToWrite: Set<HKSampleType> = [HKObjectType.quantityType(forIdentifier: .stepCount)!, HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!]
        
        let healthStore = HKHealthStore()
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { (success, error) in
            if success {
               // Success
            } else {
                // Error handle
            }
        }
    }
    
    private func requestAuthorization() {
        let healthStore = HKHealthStore()
        
        // Check if HealthKit is available on the device
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        
        // Define the HealthKit types you want to read
        let typesToRead: Set<HKObjectType> = [HKObjectType.quantityType(forIdentifier: .stepCount)!]
        
        // Request authorization from the user
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.status = "authorized"
                    // self.fetchStepCount()
                } else if let error = error {
                    // Handle authorization error
                    self.status = "Authorization failed:"  + error.localizedDescription
                }
            }
        }
    }

    
    private func fetchStepCount() {
           let healthStore = HKHealthStore()
           
           // Define the step count type
           let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
           
           // Create the query for step count
           let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: nil, options: .cumulativeSum) { query, result, error in
               DispatchQueue.main.async {
                   guard let result = result, let sum = result.sumQuantity() else {
                       self.status = "error fetching steps"
                       return
                   }
                   
                   self.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                   self.status = "steps: " + String (self.stepCount)
               }
           }
           
           // Execute the query
           healthStore.execute(query)
       }
    
    
    func startTimer3() {
        DispatchQueue.global(qos: .background).async {
            Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                self.fs.sendDebug(msg: "timer")
            }
            RunLoop.current.run()
        }
    }
    
    func startTimer2() {
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.fs.sendDebug(msg: "timer")
        }
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour], from: Date())
            self.fs.sendDebug(msg: "timer")
            if let currentHour = components.hour {
                self.fs.sendDebug(msg: "timer hour: " + String(currentHour))
                if (currentHour == 10 && self.GPS_Running) {
                    self.fs.sendDebug(msg: "timer: stopping GPS")
                    self.stopUpdatingLocation()
                }
                else if (currentHour == 11 && !self.GPS_Running) {
                    self.fs.sendDebug(msg: "timer: starting GPS")
                    self.startUpdatingLocation()
                }
            }
        }
    }
    func scheduleEvent() {
        let calendar = Calendar.current
        let date = Date()
        
        // Get the current date and time components
        let currentDateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        
        // Set the desired date and time components for 3 AM
        var eventDateComponents = DateComponents()
        eventDateComponents.hour = 3
        eventDateComponents.minute = 0
        eventDateComponents.second = 0
        
        // Adjust the date components to the next occurrence of 3 AM
        if let nextEventDate = calendar.nextDate(after: date, matching: eventDateComponents, matchingPolicy: .nextTime) {
            // Calculate the time interval between the current date and the next event date
            let timeInterval = nextEventDate.timeIntervalSince(date)
            
            // Schedule the event using a timer
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { _ in
                // Handle the event here
                self.eventFired()
            }
        }
    }
    
    func eventFired() {
        fs.sendDebug(msg: "3 am timer fired")
        //scheduleEvent()
    }

