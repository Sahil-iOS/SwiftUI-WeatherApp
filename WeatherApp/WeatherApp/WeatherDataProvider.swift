//
//  WeatherDataProvider.swift
//  WeatherApp
//
//  Created by Sahil Patel on 8/15/23.
//

import Foundation
import UIKit
protocol WeatherDataProvider {
    func fetchWeatherData(latitude: Double, longitude: Double) async throws -> WeatherData
}


struct WeatherData: Codable {
    
    struct Weather: Codable {
        let title: String
        let description: String
        let icon: String
        
        //use of codingkeys so that main can be renamed to title for better readability
        enum CodingKeys: String, CodingKey {
            case title = "main"
            case description
            case icon
        }
    }
    
    struct Main: Codable {
        let temp: Double
        let feelsLike: Double
        let tempMin: Double
        let tempMax: Double
        let humidity: Int
    }
    
    let weather: [Weather]
    let main: Main
}

class OpenWeatherData: WeatherDataProvider {
    
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func fetchWeatherData(latitude: Double, longitude: Double) async throws -> WeatherData {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(self.apiKey)") else { throw WeatherDataError.invalidURL }
        
        do {
            let response = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(WeatherData.self, from: response.0)
        } catch {
            throw WeatherDataError.requestFailed(error)
        }
    }
}

enum WeatherDataError: Error {
    case invalidURL
    case requestFailed(Error)
}
