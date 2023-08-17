//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Sahil Patel on 8/15/23.
//

import CoreLocation
import SwiftUI

//to display the segmented control and determine which api to use
enum InputMode: String, CaseIterable, Identifiable {
    case cityState = "City & State"
    case zip = "Zip Code"
    var id: String { self.rawValue }
}

class WeatherViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    let states = [ "","AK","AL","AR","AS","AZ","CA","CO","CT","DC","DE","FL","GA","GU","HI","IA","ID","IL","IN","KS","KY","LA","MA","MD","ME","MI","MN","MO","MS","MT","NC","ND","NE","NH","NJ","NM","NV","NY","OH","OK","OR","PA","PR","RI","SC","SD","TN","TX","UT","VA","VI","VT","WA","WI","WV","WY"]
    
    @Published var city = ""
    @Published var state = ""
    @Published var zip = ""
    @Published var weatherData: WeatherData?
    @Published var inputMode: InputMode = .cityState
    @Published var errorMessage = ""
    @Published var showLocationAlert = false
    
    private var locationManager = CLLocationManager()
    private let userDefaults = UserDefaults.standard
    private let weatherProvider: WeatherDataProvider
    private let geocodingProvider: GeocodingDataProvider
    
    init(geocodingDataProvider: GeocodingDataProvider, weatherDataProvider: WeatherDataProvider) {
        self.geocodingProvider = geocodingDataProvider
        self.weatherProvider = weatherDataProvider
        super.init()
        self.locationManager.delegate = self
    }
    
    //To fetch weather data we need to first get the lat long values using the geocoding api and handle the request based on the input provided
    func fetchLatLong() async {
        do {
            var location: Location?
            if inputMode == .cityState {
                location = try await geocodingProvider.geocode(city: city, state: state)
            } else {
                location = try await geocodingProvider.geocode(zip: zip)
            }
            
            guard let loc = location else {
                DispatchQueue.main.async {
                    self.errorMessage = "Error fetching location"
                }
                return
            }
            
            await fetchWeatherData(lat: loc.lat, lon: loc.lon)
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    //once we have a latitude and longitude we can call the weather api to get the data and display it by assigning the data to weatherData
    func fetchWeatherData(lat: Double, lon: Double) async {
        do {
            //save the coordinates in user defaults to retain the last searched location
            userDefaults.set(lat, forKey: "lat")
            userDefaults.set(lon, forKey: "lon")
            
            let data = try await weatherProvider.fetchWeatherData(latitude: lat, longitude: lon)
            DispatchQueue.main.async {
                self.errorMessage = ""
                self.weatherData = data
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func fetchSavedWeatherData() async {
        let lat = userDefaults.double(forKey: "lat")
        let lon = userDefaults.double(forKey: "lon")
        // only fetch the weather if there is something saved in userDefaults
        if !(lat == 0.0 && lon == 0.0) {
            await fetchWeatherData(lat: lat, lon: lon)
        }
    }
 
    func verifyInputs() -> Bool {
        if inputMode == .cityState {
            if city == "" {
                errorMessage = "Please enter a city"
                return false
            }
            if state == "" {
                errorMessage = "Please select a state"
                return false
            }
        } else {
            if zip == "" {
                errorMessage = "Please enter a zip code"
                return false
            }
        }
        
        return true
    }
    
    func clearInputs(inputMode: InputMode) {
        errorMessage = ""
        if inputMode == .zip {
            city = ""
            state = ""
        }else {
            zip = ""
        }
    }
  
    
    func fetchCurrentLocationData() async {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways :
            locationManager.startUpdatingLocation()
            let lastLocation = locationManager.location
            let lat = lastLocation?.coordinate.latitude ?? 0.0
            let lon = lastLocation?.coordinate.longitude ?? 0.0
            locationManager.stopUpdatingLocation()
            
            await fetchWeatherData(lat: lat, lon: lon)
           
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showLocationAlert = true
            }
        default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways :
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
    }
    
    func createImageURL() -> URL?{
        if let code = weatherData?.weather.first?.icon {
            print(code)
            return URL(string: "https://openweathermap.org/img/wn/\(code)@2x.png")
        }
        return nil
    }
}


struct WeatherImage: View {
    @State private var cachedImage: UIImage = UIImage()
    var url: URL?
    
    init(url: URL?) {
        self.url = url
    }
    
    //update the image whenever url changes and on appear to load it initially
    var body: some View {
        Image(uiImage: cachedImage)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: 250, maxHeight: 100)
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20))
            .onChange(of: url) { newURL in
                if let updatedURL = newURL {
                    Task(priority: .background) {
                        await loadImage(url: updatedURL)
                    }
                }
            }
            .onAppear {
                if let loadURL = url {
                    Task(priority: .background) {
                        await loadImage(url: loadURL)
                    }
                }
            }
    }

    func loadImage(url: URL) async {
        print(url)
        //load image if saved in cachae
        if let cache  = URLCache.shared.cachedResponse(for: URLRequest(url: url)) {
            DispatchQueue.main.async {
                cachedImage = UIImage(data: cache.data) ?? UIImage()
            }
        } else {
            do {
                //make a request and save response to cache
                let (data, response) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        cachedImage = image
                    }
                    if let httpResponse = response as? HTTPURLResponse {
                        let cacheData = CachedURLResponse(response: httpResponse, data: data)
                        URLCache.shared.storeCachedResponse(cacheData, for: URLRequest(url: url))
                    }
                }
            } catch {
                return
            }
        }
    }
}


extension Double {
    func kelvinToFarenheit() -> String {
        let f = (self - 273.15) * 9/5 + 32
        let roundedF = Int(f.rounded())
        return "\(roundedF)°F"
    }
}
