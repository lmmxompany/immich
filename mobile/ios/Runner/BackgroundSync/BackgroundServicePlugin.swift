//
//  BackgroundServicePlugin.swift
//  Runner
//
//  Created by Marty Fuhry on 2/14/23.
//

import Flutter
import BackgroundTasks
import path_provider_foundation

class BackgroundServicePlugin: NSObject, FlutterPlugin {
    
    public static var flutterPluginRegistrantCallback: FlutterPluginRegistrantCallback?
    
    public static func setPluginRegistrantCallback(_ callback: FlutterPluginRegistrantCallback) {
        flutterPluginRegistrantCallback = callback
    }

    //  Pause the application in XCode, then enter
    // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"immichBackground"]
    // Then resume the application see the background code run
    // Tested on a physical device, not a simulator
    // This will simulate running the BGAppRefreshTask, which is the "quick sync" task.
    // I'm not sure how to simulate running the BGProcessingTask
    
    // This is the task ID in Info.plist to register as our background task ID
    public static let backgroundSyncTaskID = "immichBackground"
    
    // Establish communication with the main isolate and set up the channel call
    // to this BackgroundServicePlugion()
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "immich/foregroundChannel",
            binaryMessenger: registrar.messenger()
        )

        let instance = BackgroundServicePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    // Registers the Flutter engine with the plugins, used by the other Background Flutter engine
    public static func register(engine: FlutterEngine) {
        GeneratedPluginRegistrant.register(with: engine)
    }

    // Registers the task IDs from the system so that we can process them here in this class
    public static func registerBackgroundProcessing() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BackgroundServicePlugin.backgroundSyncTaskID, using: nil) { task in
            if task is BGAppRefreshTask {
                BackgroundServicePlugin.handleBackgroundFetch(task: task as! BGAppRefreshTask)
            }
            
            if task is BGProcessingTask {
                BackgroundServicePlugin.handleBackgroundProcessing(task: task as! BGProcessingTask)
            }
        }
    }

    // Handles the channel methods from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "enable":
                handleBackgroundEnable(call: call, result: result)
                break
            case "configure":
                handleConfigure(call: call, result: result)
                break
            case "disable":
                handleDisable(call: call, result: result)
                break
            case "isEnabled":
                handleIsEnabled(call: call, result: result)
                break
            case "isIgnoringBatteryOptimizations":
                result(FlutterMethodNotImplemented)
                break
            default:
                result(FlutterMethodNotImplemented)
                break
        }
    }
    
    // Called by the flutter code when enabled so that we can turn on the backround services
    // and save the callback information to communicate on this method channel
    public func handleBackgroundEnable(call: FlutterMethodCall, result: FlutterResult) {
        
        // Needs to parse the arguments from the method call
        guard let args = call.arguments as? Array<Any> else {
            print("Cannot parse args as array: \(call.arguments)")
            result(FlutterMethodNotImplemented)
            return
        }
        
        // Requires 3 arguments in the array
        guard args.count == 3 else {
            print("Requires 3 arguments and received \(args.count)")
            result(FlutterMethodNotImplemented)
            return
        }
        
        // Parses the arguments
        let callbackHandle = args[0] as? Int64
        let notificationTitle = args[1] as? String
        let instant = args[2] as? Bool
        
        // Store these to user defaults
        let defaults = UserDefaults.standard
        
        // The callback handle is an int64 address to communicate with the main isolate's
        // entry function
        defaults.set(callbackHandle, forKey: "callback_handle")
        
        // This is not used yet and will need to be implemented
        defaults.set(notificationTitle, forKey: "notification_title")
        
        // Schedule the background services
        BackgroundServicePlugin.scheduleBackgroundSync()
        BackgroundServicePlugin.scheduleBackgroundFetch()
        result(true)
    }
    
    // Called by the flutter code at launch to let us know to schedule the services
    func handleIsEnabled(call: FlutterMethodCall, result: FlutterResult) {
        // Schedule the background services
        BackgroundServicePlugin.scheduleBackgroundSync()
        BackgroundServicePlugin.scheduleBackgroundFetch()
        
        result(true)
    }
    
    // Called by the Flutter code whenever a change in configuration is set
    func handleConfigure(call: FlutterMethodCall, result: FlutterResult) {
        
        // Needs to be able to parse the arguments or else fail
        guard let args = call.arguments as? Array<Any> else {
            print("Cannot parse args as array: \(call.arguments)")
            result(FlutterError())
            return
        }
        
        // Needs to have 4 arguments in the call or else fail
        guard args.count == 4 else {
            print("Not enough arguments, 4 required: \(args.count) given")
            result(FlutterError())
            return
        }
        
        // Parse the arguments from the method call
        let requireUnmeteredNetwork = args[0] as? Bool
        let requireCharging = args[1] as? Bool
        let triggerUpdateDelay = args[2] as? Int
        let triggerMaxDelay = args[3] as? Int
        
        // Store the values from the call in the defaults
        let defaults = UserDefaults.standard
        defaults.set(requireUnmeteredNetwork, forKey: "require_unmetered_network")
        defaults.set(requireCharging, forKey: "require_charging")
        defaults.set(triggerUpdateDelay, forKey: "trigger_update_delay")
        defaults.set(triggerMaxDelay, forKey: "trigger_max_delay")

        // Cancel the background services and reschedule them
        BGTaskScheduler.shared.cancelAllTaskRequests()
        BackgroundServicePlugin.scheduleBackgroundSync()
        BackgroundServicePlugin.scheduleBackgroundFetch()
        result(true)
    }
    
    // Disables the service, cancels all the task requests
    func handleDisable(call: FlutterMethodCall, result: FlutterResult) {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        result(true)
    }
  
    // Schedules a short-running background sync to sync only a few photos
    static func scheduleBackgroundFetch() {
        // We will only schedule this task to run if the user has explicitely allowed us to backup while
        // not using a metered connection and not connected to power
        let defaults = UserDefaults.standard
        if defaults.value(forKey: "require_unmetered_network") as? Bool == true ||
           defaults.value(forKey: "require_charging") as? Bool == true {
            // We won't run while either of these are required
            return
        }
                
        let backgroundFetch = BGAppRefreshTaskRequest(identifier: BackgroundServicePlugin.backgroundSyncTaskID)
        
        // Use 5 minutes from now as earliest begin date
        backgroundFetch.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(backgroundFetch)
        } catch {
            print("Could not schedule the background task \(error.localizedDescription)")
        }
    }
    
    // Schedules a long-running background sync for syncing all of the photos
    static func scheduleBackgroundSync() {
        let backgroundProcessing = BGProcessingTaskRequest(identifier: BackgroundServicePlugin.backgroundSyncTaskID)
        // We need the values for requiring charging or unmetered network usage
        let defaults = UserDefaults.standard
        let requireCharging = defaults.value(forKey: "require_charging") as? Bool
        let requireUnmeteredNetwork = defaults.value(forKey: "require_unmetered_network") as? Bool
        
        // Add these to the processing task request so the system knows to only run them when
        // they are both appropriately set
        backgroundProcessing.requiresNetworkConnectivity = requireUnmeteredNetwork ?? true
        backgroundProcessing.requiresExternalPower = requireCharging ?? true
                
        // Use 15 minutes from now as earliest begin date
        backgroundProcessing.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            // Submit the task to the scheduler
            try BGTaskScheduler.shared.submit(backgroundProcessing)
        } catch {
            print("Could not schedule the background task \(error.localizedDescription)")
        }
    }
    
    // This function runs when the system kicks off the BGAppRefreshTask from the Background Task Scheduler
    static func handleBackgroundFetch(task: BGAppRefreshTask) {
        // Schedule the next sync task so we can run this again later
        scheduleBackgroundFetch()
        
        // The background sync task should only run for 10 seconds at most
        BackgroundServicePlugin.runBackgroundSync(maxSeconds: 10)
        task.setTaskCompleted(success: true)
    }
    
    // This function runs when the system kicks off the BGProcessingTask from the Background Task Scheduler
    static func handleBackgroundProcessing(task: BGProcessingTask) {
        // Schedule the next sync task so we run this again later
        scheduleBackgroundSync()
        
        // We won't specify a max time for the background sync service, so this can run for longer
        BackgroundServicePlugin.runBackgroundSync(maxSeconds: nil)
        task.setTaskCompleted(success: true)
    }
    
    // This is a synchronous function which uses a semaphore to run the background sync worker's run
    // function, which will create a background Isolate and communicate with the Flutter code to back
    // up the assets. When it completes, we signal the semaphore and complete the execution allowing the
    // control to pass back to the caller synchronously
    static func runBackgroundSync(maxSeconds: Int?) {
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            let backgroundWorker = BackgroundSyncWorker { _ in
                semaphore.signal()
            }
            backgroundWorker.run(maxSeconds: maxSeconds)
        }
        semaphore.wait()
    }


}
