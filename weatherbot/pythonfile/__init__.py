import logging
import requests
import os
import azure.functions as func

WEATHER_API_KEY = 'e8dd4c2ddd9cf4334e4a81c6b1f7b564'

def get_weather(city):
    url = f'http://api.openweathermap.org/data/2.5/weather?q={city}&appid={WEATHER_API_KEY}&units=metric'
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        weather = {
            'city': city,
            'temperature': data['main']['temp'],
            'description': data['weather'][0]['description'],
            'humidity': data['main']['humidity'],
            'wind_speed': data['wind']['speed']
        }
        return weather
    else:
        return None

def main(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    # Get the city from the query parameters
    city = req.params.get('city')
    if not city:
        return func.HttpResponse(
            "Please pass a city name on the query string",
            status_code=400
        )

    weather_data = get_weather(city)
    
    if weather_data:
        return func.HttpResponse(
            f"Weather in {weather_data['city']}:\n"
            f"Temperature: {weather_data['temperature']}°C\n"
            f"Description: {weather_data['description']}\n"
            f"Humidity: {weather_data['humidity']}%\n"
            f"Wind Speed: {weather_data['wind_speed']} m/s",
            status_code=200
        )
    else:
        return func.HttpResponse(
            "Could not retrieve weather data. Please try again later.",
            status_code=500
        )
