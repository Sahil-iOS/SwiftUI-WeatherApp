//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Sahil Patel on 8/15/23.
//

import SwiftUI

@main
struct WeatherApp: App {
    let persistenceController = PersistenceController.shared
    let apiKey = "41c4d579910b3c09f1256adb9d019810"
    var viewModel: WeatherViewModel{
        //Use of dependency injection to pass the dataproviders from a higher level to the viewModel
        WeatherViewModel(geocodingDataProvider: OpenWeatherGeocoder(apiKey: apiKey), weatherDataProvider: OpenWeatherData(apiKey: apiKey))
    }
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
