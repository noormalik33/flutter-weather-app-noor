## 🌤️ Weather App

A beautiful, feature-rich Flutter weather application with real-time weather data, voice search, and customizable location names.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![OpenWeatherMap](https://img.shields.io/badge/OpenWeatherMap-orange?style=for-the-badge)

## ✨ Features

### 🎯 Core Features
- **Real-time Weather Data** - Get current weather conditions for any city worldwide
- **5-Day Forecast** - View detailed weather predictions for the next 5 days
- **GPS Location** - Automatically detect and display weather for your current location
- **Custom Location Names** - Override GPS-detected names with your preferred location display name
- **Voice Search** - Search for cities using voice commands
- **Recent Searches** - Quick access to your previously searched locations

### 🎨 UI/UX Features
- **Dynamic Backgrounds** - Beautiful weather-appropriate backgrounds that change based on:
    - Current weather conditions (clear, cloudy, rainy, stormy, snowy, foggy)
    - Time of day (morning, afternoon, evening, night)
- **Dark/Light Mode** - Toggle between themes with persistent preference
- **Temperature Units** - Switch between Celsius and Fahrenheit
- **Smooth Animations** - Fade-in effects and rotation animations for better user experience
- **Glassmorphism Design** - Modern, translucent UI elements

### 📊 Weather Information Displayed
- Current temperature with weather icon
- Weather condition and description
- Feels-like temperature
- Humidity percentage
- Wind speed
- Atmospheric pressure
- Visibility distance
- Sunrise and sunset times
- 5-day forecast with min/max temperatures

## 📱 Screenshots

<!-- Add your app screenshots here -->
```
[Main Screen] [Weather Details] [Forecast View]
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- OpenWeatherMap API key

### Dependencies
Add these dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  geolocator: ^10.1.0
  speech_to_text: ^6.5.1
  permission_handler: ^11.1.0
  intl: ^0.18.1
```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/noormalik33/flutter-weather-app-noor.git
   cd weather-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Get your OpenWeatherMap API Key**
    - Visit [OpenWeatherMap](https://openweathermap.org/api)
    - Sign up for a free account
    - Generate your API key

4. **Add your API key**
    - Open `lib/main.dart`
    - Replace `YOUR_API_KEY_HERE` with your actual API key:
   ```dart
   static const String apiKey = 'your_actual_api_key_here';
   ```

5. **Configure permissions**

   **For Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   ```

   **For iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>This app needs access to location for weather information.</string>
   <key>NSMicrophoneUsageDescription</key>
   <string>This app needs microphone access for voice search.</string>
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 🎮 How to Use

### Search for Weather
1. **Manual Search**: Type a city name in the search bar and press enter or tap the search icon
2. **Voice Search**: Tap the microphone icon and speak the city name
3. **GPS Location**: Tap the location icon to get weather for your current location
4. **Recent Searches**: Tap any recent search chip to quickly view that location's weather

### Customize Location Name
1. Tap the 📍 location icon to get GPS weather
2. A dialog will appear showing the detected location
3. Enter your preferred display name (e.g., "Gulberg Greens, Islamabad")
4. Tap "Set Custom" to save
5. Edit anytime using the ✏️ edit icon in the top bar

### Change Settings
- **Theme**: Tap the sun/moon icon to toggle dark/light mode
- **Temperature Unit**: Use the °C/°F toggle to switch between Celsius and Fahrenheit
- **Refresh**: Tap the refresh icon to update weather data
- **Home**: Tap the home icon to return to the search screen

## 🏗️ Project Structure

```
lib/
├── main.dart                 # Main application file
├── models/                   # Data models (if separated)
├── services/                 # API services (if separated)
├── widgets/                  # Reusable widgets (if separated)
└── utils/                    # Helper functions (if separated)
```

## 🔧 Configuration

### API Configuration
The app uses OpenWeatherMap API with the following endpoints:
- Current Weather: `api.openweathermap.org/data/2.5/weather`
- 5-Day Forecast: `api.openweathermap.org/data/2.5/forecast`

### Storage
User preferences are stored locally using SharedPreferences:
- Last searched city
- Custom location name
- Recent searches (up to 5)
- Theme preference (dark/light mode)
- Temperature unit preference

## 🎨 Customization

### Change App Title
Edit the app bar text in `_buildAppBar()` method:
```dart
const Text(
  'YOUR APP NAME',
  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
),
```

### Modify Color Scheme
Change the seed color in `MaterialApp` theme:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xYourColorHex),
  brightness: Brightness.light,
),
```

### Add More Weather Details
Extend `_buildWeatherDetails()` method to include additional weather parameters available in the API response.

## 🐛 Troubleshooting

### Common Issues

**1. API Key Error**
- Ensure your API key is correctly added in the code
- Verify the API key is active on OpenWeatherMap dashboard

**2. Location Permission Denied**
- Go to device Settings → Apps → Weather App → Permissions
- Enable Location and Microphone permissions

**3. Voice Search Not Working**
- Check microphone permissions
- Ensure device has internet connection
- Try speaking clearly and slowly

**4. Network Errors**
- Check internet connection
- Verify firewall/proxy settings
- Ensure OpenWeatherMap API is not blocked

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Developer

**Noor Malik**  
IT Student  
📍 Islamabad, Pakistan  
📧 Email: noormalik56500@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/noormalik56500/)

Social 📱

📧 Email: mailto:coreittech1@gmail.com  
📹 YouTube: https://www.youtube.com/@CoreITTech1  
📸 Instagram: https://www.instagram.com/coreit.tech  
📘 Facebook: https://www.facebook.com/share/1AmgLDUnc9/


## 🙏 Acknowledgments

- [OpenWeatherMap](https://openweathermap.org/) for providing the weather API
- [Unsplash](https://unsplash.com/) for beautiful background images
- Flutter community for amazing packages

## 📈 Future Enhancements

- [ ] Hourly forecast view
- [ ] Weather alerts and notifications
- [ ] Multiple location bookmarks
- [ ] Weather widgets
- [ ] Offline mode with cached data
- [ ] Weather maps and radar
- [ ] Air quality index
- [ ] UV index information
- [ ] More detailed weather statistics
- [ ] Share weather information

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/yourusername/weather-app/issues).

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## ⭐ Show your support

Give a ⭐️ if you like this project!

---

Happy coding! 🚀 Let’s build amazing UIs together! 💪