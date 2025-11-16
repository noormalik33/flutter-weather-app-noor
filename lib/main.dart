import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatefulWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App by Noor Malik',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: _themeMode,
      home: WeatherHomePage(onThemeChanged: _toggleTheme),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  final Function(bool) onThemeChanged;

  const WeatherHomePage({Key? key, required this.onThemeChanged}) : super(key: key);

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage>
    with TickerProviderStateMixin {
  // API Configuration - Replace with your OpenWeatherMap API key
  static const String apiKey = 'YOUR_API_KEY_HERE';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  final TextEditingController _searchController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDarkMode = false;
  bool _showCelsius = true;

  Map<String, dynamic>? _currentWeather;
  List<dynamic>? _forecast;
  String? _lastCity;
  String? _customLocationName;
  List<Map<String, String>> _recentSearches = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadLastCity();
    _loadRecentSearches();
    _loadThemePreference();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
    widget.onThemeChanged(_isDarkMode);
  }

  Future<void> _saveThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', isDark);
  }

  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    _lastCity = prefs.getString('last_city');
    _customLocationName = prefs.getString('custom_location_name');
    if (_lastCity != null && _lastCity!.isNotEmpty) {
      _fetchWeatherByCity(_lastCity!);
    }
  }

  Future<void> _saveLastCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_city', city);
  }

  Future<void> _saveCustomLocationName(String locationName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_location_name', locationName);
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      _recentSearches = searches.map((s) {
        final parts = s.split('|');
        return {'city': parts[0], 'country': parts.length > 1 ? parts[1] : ''};
      }).toList();
    });
  }

  Future<void> _saveRecentSearch(String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    final searchString = '$city|$country';

    _recentSearches.removeWhere((s) => s['city'] == city);
    _recentSearches.insert(0, {'city': city, 'country': country});
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }

    await prefs.setStringList(
      'recent_searches',
      _recentSearches.map((s) => '${s['city']}|${s['country']}').toList(),
    );
    setState(() {});
  }

  Future<void> _fetchWeatherByCity(String city) async {
    if (city.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final currentResponse = await http.get(
        Uri.parse('$baseUrl/weather?q=$city&appid=$apiKey&units=metric'),
      ).timeout(const Duration(seconds: 10));

      if (currentResponse.statusCode == 200) {
        final currentData = json.decode(currentResponse.body);

        final forecastResponse = await http.get(
          Uri.parse('$baseUrl/forecast?q=$city&appid=$apiKey&units=metric'),
        ).timeout(const Duration(seconds: 10));

        if (forecastResponse.statusCode == 200) {
          final forecastData = json.decode(forecastResponse.body);

          setState(() {
            _currentWeather = currentData;
            _forecast = _processForecast(forecastData['list']);
            _isLoading = false;
            _lastCity = city;
          });

          _saveLastCity(city);
          _saveRecentSearch(currentData['name'], currentData['sys']['country']);
          _animationController.forward(from: 0.0);
        }
      } else if (currentResponse.statusCode == 404) {
        setState(() {
          _hasError = true;
          _errorMessage = 'City not found. Please check the spelling.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to fetch weather data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  List<dynamic> _processForecast(List<dynamic> forecastList) {
    Map<String, dynamic> dailyForecasts = {};

    for (var item in forecastList) {
      String date = item['dt_txt'].split(' ')[0];
      if (!dailyForecasts.containsKey(date)) {
        dailyForecasts[date] = {
          'date': date,
          'temp_min': item['main']['temp_min'],
          'temp_max': item['main']['temp_max'],
          'description': item['weather'][0]['description'],
          'icon': item['weather'][0]['icon'],
        };
      } else {
        dailyForecasts[date]['temp_min'] = (dailyForecasts[date]['temp_min'] <
            item['main']['temp_min'])
            ? dailyForecasts[date]['temp_min']
            : item['main']['temp_min'];
        dailyForecasts[date]['temp_max'] = (dailyForecasts[date]['temp_max'] >
            item['main']['temp_max'])
            ? dailyForecasts[date]['temp_max']
            : item['main']['temp_max'];
      }
    }

    return dailyForecasts.values.take(5).toList();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      var status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Location permission denied.';
          _isLoading = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = await http.get(
        Uri.parse(
            '$baseUrl/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric'),
      );

      if (response.statusCode == 200) {
        final currentData = json.decode(response.body);
        String cityName = currentData['name'];
        _searchController.text = cityName;

        // Show dialog to ask if user wants to set custom location name
        if (mounted) {
          _showLocationNameDialog(cityName);
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to get location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showLocationNameDialog(String detectedCity) {
    final TextEditingController locationController = TextEditingController(
      text: _customLocationName ?? detectedCity,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Location Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Detected: $detectedCity',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  hintText: 'e.g., Gulberg Greens, Islamabad',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchWeatherByCity(detectedCity);
              },
              child: const Text('Use Detected'),
            ),
            ElevatedButton(
              onPressed: () {
                String customName = locationController.text.trim();
                if (customName.isNotEmpty) {
                  setState(() {
                    _customLocationName = customName;
                  });
                  _saveCustomLocationName(customName);
                }
                Navigator.of(context).pop();
                _fetchWeatherByCity(detectedCity);
              },
              child: const Text('Set Custom'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _startListening() async {
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition error: $error')),
        );
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
          });
          if (result.finalResult) {
            _fetchWeatherByCity(result.recognizedWords);
          }
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _refreshWeather() {
    _rotationController.repeat();
    if (_lastCity != null) {
      _fetchWeatherByCity(_lastCity!).then((_) {
        _rotationController.stop();
        _rotationController.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Weather data refreshed!'),
            duration: Duration(seconds: 2),
          ),
        );
      });
    } else {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  void _resetToMainPage() {
    setState(() {
      _currentWeather = null;
      _forecast = null;
      _searchController.clear();
      _hasError = false;
      _errorMessage = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ready to search new city!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _getWeatherIcon(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@4x.png';
  }

  String _getBackgroundImage() {
    if (_currentWeather == null) {
      // Beautiful default home page backgrounds - changes based on time
      final hour = DateTime.now().hour;

      if (hour >= 5 && hour < 12) {
        // Morning - Sunrise/Early morning vibes
        return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80';
      } else if (hour >= 12 && hour < 17) {
        // Afternoon - Bright sky
        return 'https://images.unsplash.com/photo-1536514072410-5019a3c69182?w=800&q=80';
      } else if (hour >= 17 && hour < 20) {
        // Evening - Golden hour/Sunset
        return 'https://images.unsplash.com/photo-1495567720989-cebdbdd97913?w=800&q=80';
      } else {
        // Night - Stars/Night sky
        return 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800&q=80';
      }
    }

    final condition = _currentWeather!['weather'][0]['main'].toLowerCase();
    final hour = DateTime.now().hour;
    final isDaytime = hour >= 6 && hour < 18;

    if (isDaytime) {
      if (condition.contains('clear')) {
        return 'https://images.unsplash.com/photo-1601297183305-6df142704ea2?w=800&q=80';
      }
      if (condition.contains('cloud')) {
        return 'https://images.unsplash.com/photo-1534088568595-a066f410bcda?w=800&q=80';
      }
      if (condition.contains('rain') || condition.contains('drizzle')) {
        return 'https://images.unsplash.com/photo-1515694346937-94d85e41e6f0?w=800&q=80';
      }
      if (condition.contains('thunder') || condition.contains('storm')) {
        return 'https://images.unsplash.com/photo-1605727216801-e27ce1d0cc28?w=800&q=80';
      }
      if (condition.contains('snow')) {
        return 'https://images.unsplash.com/photo-1491002052546-bf38f186af56?w=800&q=80';
      }
      if (condition.contains('mist') || condition.contains('fog') || condition.contains('haze')) {
        return 'https://images.unsplash.com/photo-1487621167305-5d248087c724?w=800&q=80';
      }
    } else {
      // Night time backgrounds
      if (condition.contains('clear')) {
        return 'https://images.unsplash.com/photo-1532178910-7815d6919875?w=800&q=80';
      }
      if (condition.contains('cloud')) {
        return 'https://images.unsplash.com/photo-1509803874385-db7c23652552?w=800&q=80';
      }
      if (condition.contains('rain') || condition.contains('drizzle')) {
        return 'https://images.unsplash.com/photo-1428908728789-d2de25dbd4e2?w=800&q=80';
      }
      if (condition.contains('thunder') || condition.contains('storm')) {
        return 'https://images.unsplash.com/photo-1475116127127-e3ce09ee84e1?w=800&q=80';
      }
    }

    return 'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=800&q=80';
  }

  double _convertTemp(double temp) {
    return _showCelsius ? temp : (temp * 9 / 5) + 32;
  }

  String _getTempUnit() {
    return _showCelsius ? '°C' : '°F';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(_getBackgroundImage()),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              isDark
                  ? Colors.black.withOpacity(0.5)
                  : Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              _buildSearchBar(isDark),
              if (_recentSearches.isNotEmpty && _currentWeather == null)
                _buildRecentSearches(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _hasError
                    ? _buildErrorState()
                    : _currentWeather == null
                    ? _buildEmptyState()
                    : _buildWeatherContent(),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  RotationTransition(
                    turns: _rotationController,
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                      onPressed: _currentWeather != null ? _refreshWeather : null,
                      tooltip: 'Refresh weather data',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: Colors.white, size: 28),
                    onPressed: _resetToMainPage,
                    tooltip: 'Back to search',
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white, size: 28),
                    onPressed: _getCurrentLocation,
                    tooltip: 'Current location',
                  ),
                  if (_customLocationName != null)
                    IconButton(
                      icon: const Icon(Icons.edit_location_alt, color: Colors.white, size: 28),
                      onPressed: () => _showLocationNameDialog(_lastCity ?? ''),
                      tooltip: 'Edit location name',
                    ),
                ],
              ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Text(
                            '°C',
                            style: TextStyle(
                              color: _showCelsius ? Colors.white : Colors.white60,
                              fontWeight: _showCelsius ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () => setState(() => _showCelsius = true),
                        ),
                        IconButton(
                          icon: Text(
                            '°F',
                            style: TextStyle(
                              color: !_showCelsius ? Colors.white : Colors.white60,
                              fontWeight: !_showCelsius ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () => setState(() => _showCelsius = false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isDarkMode = !_isDarkMode;
                            });
                            widget.onThemeChanged(_isDarkMode);
                            _saveThemePreference(_isDarkMode);
                          },
                          tooltip: 'Toggle theme',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'WEATHER APP',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          const Text(
            'BY NOOR MALIK',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Search city...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: (value) => _fetchWeatherByCity(value),
              ),
            ),
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.white,
                size: 28,
              ),
              onPressed: _isListening ? _stopListening : _startListening,
              tooltip: 'Voice search',
            ),
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: () => _fetchWeatherByCity(_searchController.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Searches',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recentSearches.map((search) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = search['city']!;
                  _fetchWeatherByCity(search['city']!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${search['city']}, ${search['country']}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          SizedBox(height: 20),
          Text(
            'Fetching weather data...',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 120, color: Colors.white70),
            const SizedBox(height: 20),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                if (_lastCity != null) {
                  _fetchWeatherByCity(_lastCity!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 120, color: Colors.white70),
            const SizedBox(height: 20),
            const Text(
              'Search for a city to get weather information',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _getCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Use My Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCurrentWeather(),
            const SizedBox(height: 20),
            _buildWeatherDetails(),
            const SizedBox(height: 20),
            _buildSunriseSunset(),
            const SizedBox(height: 20),
            _buildForecast(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWeather() {
    final temp = _convertTemp(_currentWeather!['main']['temp'].toDouble()).round();
    final condition = _currentWeather!['weather'][0]['main'];
    final description = _currentWeather!['weather'][0]['description'];
    final icon = _currentWeather!['weather'][0]['icon'];
    final city = _customLocationName ?? _currentWeather!['name'];
    final country = _currentWeather!['sys']['country'];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '$city, $country',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Image.network(
            _getWeatherIcon(icon),
            width: 140,
            height: 140,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.wb_sunny, size: 140, color: Colors.white),
          ),
          Text(
            '$temp${_getTempUnit()}',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            condition,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetails() {
    final humidity = _currentWeather!['main']['humidity'];
    final windSpeed = _currentWeather!['wind']['speed'];
    final feelsLike = _convertTemp(_currentWeather!['main']['feels_like'].toDouble()).round();
    final pressure = _currentWeather!['main']['pressure'];
    final visibility = (_currentWeather!['visibility'] / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(Icons.water_drop, 'Humidity', '$humidity%'),
              _buildDetailItem(Icons.air, 'Wind', '${windSpeed.toStringAsFixed(1)} m/s'),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDetailItem(Icons.thermostat, 'Feels Like', '$feelsLike${_getTempUnit()}'),
              _buildDetailItem(Icons.speed, 'Pressure', '$pressure hPa'),
            ],
          ),
          const SizedBox(height: 25),
          _buildDetailItem(Icons.visibility, 'Visibility', '$visibility km'),
        ],
      ),
    );
  }

  Widget _buildSunriseSunset() {
    final sunrise = DateTime.fromMillisecondsSinceEpoch(
      _currentWeather!['sys']['sunrise'] * 1000,
    );
    final sunset = DateTime.fromMillisecondsSinceEpoch(
      _currentWeather!['sys']['sunset'] * 1000,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDetailItem(
            Icons.wb_sunny,
            'Sunrise',
            DateFormat('HH:mm').format(sunrise),
          ),
          _buildDetailItem(
            Icons.nightlight_round,
            'Sunset',
            DateFormat('HH:mm').format(sunset),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildForecast() {
    if (_forecast == null || _forecast!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text(
                '5-Day Forecast',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _forecast!.length,
            separatorBuilder: (context, index) => const Divider(
              color: Colors.white30,
              height: 25,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final day = _forecast![index];
              final date = DateTime.parse(day['date']);
              final dayName = DateFormat('EEEE').format(date);
              final shortDate = DateFormat('MMM dd').format(date);
              final tempMax = _convertTemp(day['temp_max'].toDouble()).round();
              final tempMin = _convertTemp(day['temp_min'].toDouble()).round();

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shortDate,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Image.network(
                        _getWeatherIcon(day['icon']),
                        width: 55,
                        height: 55,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.wb_sunny, color: Colors.white, size: 45),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        day['description'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                              Text(
                                '$tempMax${_getTempUnit()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Icon(Icons.arrow_downward, color: Colors.white70, size: 16),
                              Text(
                                '$tempMin${_getTempUnit()}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${DateFormat('HH:mm').format(DateTime.now())}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Developed by Noor Malik',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}