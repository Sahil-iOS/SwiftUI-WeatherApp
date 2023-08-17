//
//  GeocodingDataProvider.swift
//  WeatherApp
//
//  Created by Sahil Patel on 8/15/23.
//

import Foundation
protocol GeocodingDataProvider {
    func geocode(city: String, state: String) async throws -> Location?
    func geocode(zip: String) async throws -> Location
}

struct Location: Codable {
    let name: String
    let lat: Double
    let lon: Double
}

class OpenWeatherGeocoder: GeocodingDataProvider {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func geocode(city: String, state: String) async throws -> Location? {
        guard let url = URL(string: "https://api.openweathermap.org/geo/1.0/direct?q=\(city),\(state),US&appid=\(self.apiKey)") else { throw GeocodingDataError.invalidURL }
        
        print(url)
        do {
            let (data,_) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
           return try decoder.decode([Location].self, from: data).first //api returns back an Array of locations
        } catch {
            throw GeocodingDataError.requestFailed(error)
        }
    }

    func geocode(zip: String) async throws -> Location {
        guard let url = URL(string: "https://api.openweathermap.org/geo/1.0/zip?zip=\(zip)&appid=\(self.apiKey)") else { throw GeocodingDataError.invalidURL }
        do {
            let (data,_) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Location.self, from: data)
        } catch {
            throw GeocodingDataError.requestFailed(error)
        }
    }
}

enum GeocodingDataError: Error {
case invalidURL
case requestFailed(Error)
}




