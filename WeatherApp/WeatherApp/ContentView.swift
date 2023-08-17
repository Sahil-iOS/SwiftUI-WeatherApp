//
//  ContentView.swift
//  WeatherApp
//
//  Created by Sahil Patel on 8/15/23.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: WeatherViewModel
    
    init(viewModel: WeatherViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Picker("", selection: $viewModel.inputMode, content: {
                    ForEach(InputMode.allCases, id: \.self) { input in
                        Text(input.rawValue)
                    }
                })
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: viewModel.inputMode) { newValue in
                    viewModel.clearInputs(inputMode: newValue)
                }
                
                
                if viewModel.inputMode == .cityState {
                    HStack {
                        TextField("City", text: $viewModel.city)
                            .padding()
                        
                        Picker("State", selection: $viewModel.state) {
                            ForEach(viewModel.states, id: \.self) { state in
                                state.isEmpty ? Text("State") : Text(state)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                    }
                } else {
                    TextField("Zip", text: $viewModel.zip)
                        .padding()
                }
                
                Text(viewModel.errorMessage)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxHeight: viewModel.errorMessage == "" ? 0 : .none)
                
                Button("Get weather") {
                    Task(priority: .background) {
                        if viewModel.verifyInputs() {
                            await viewModel.fetchLatLong()
                        }
                    }
                }
                
                Button("Use Current Location") {
                    Task {
                        await viewModel.fetchCurrentLocationData()
                    }
                }.padding()
                
                
                if let data = viewModel.weatherData {
                    WeatherImage(url: viewModel.createImageURL())
                        .padding()

                    Text("\(data.main.temp.kelvinToFarenheit())").font(.system(size: 100))
                    Text("\(data.weather[0].title) - \(data.weather[0].description)").font(.system(size: 35))
                    
                    HStack {
                        Text("Feels Like").font(.system(size: 25))
                        Spacer()
                        Text(data.main.feelsLike.kelvinToFarenheit()).font(.system(size: 25))
                    }.padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    HStack {
                        Text("Today's Low").font(.system(size: 25))
                        Spacer()
                        Text(data.main.tempMin.kelvinToFarenheit()).font(.system(size: 25))
                    }.padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    HStack {
                        Text("Today's High").font(.system(size: 25))
                        Spacer()
                        Text(data.main.tempMax.kelvinToFarenheit()).font(.system(size: 25))
                    }.padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                    HStack {
                        Text("Humidity").font(.system(size: 25))
                        Spacer()
                        Text("\(data.main.humidity)%").font(.system(size: 25))
                    }.padding(EdgeInsets(top: 5, leading: 20, bottom: 5, trailing: 20))
                }
            }
        }.onAppear {
            Task {
                await viewModel.fetchSavedWeatherData()
            }
        }.alert(isPresented: $viewModel.showLocationAlert){
            Alert(
                title: Text("Location Access Required"),
                message: Text("Please enable location access from settings to access this feature"),
                dismissButton: .default(Text("OK")) {
                viewModel.showLocationAlert = false
            })
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let apiKey = "41c4d579910b3c09f1256adb9d019810"
        let viewModel = WeatherViewModel(geocodingDataProvider: OpenWeatherGeocoder(apiKey: apiKey), weatherDataProvider: OpenWeatherData(apiKey: apiKey))
        
        return ContentView(viewModel: viewModel)
    }
}
