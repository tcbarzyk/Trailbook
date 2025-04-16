//
//  OWWeatherResponse.swift
//  Trailbook
//
//  Created by Teddy Barzyk on 4/15/25.
//

struct OWWeatherResponse: Codable {
    let name: String
    let main: Main
    let weather: [Weather]
    
    struct Main: Codable {
        let temp: Double
        let feels_like: Double
    }
    
    struct Weather: Codable {
        let description: String
        let icon: String
    }
}
