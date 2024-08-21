import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: WeatherScreen(
        toggleTheme: () {
          setState(() {
            isDarkMode = !isDarkMode;
          });
        },
      ),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  WeatherScreen({required this.toggleTheme});

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController controller = TextEditingController();
  String cityName = '';
  String weatherInfo = '';
  List<String> searchHistory = [];
  final apiKey = 'f6439b4601bb49f6d353921d95c5f1df';
  String sunriseTime = '';
  String sunsetTime = '';

  void fetchWeather() async {
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric&lang=vi';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        weatherInfo = 'Thời tiết tại $cityName:\n${data['weather'][0]['description']}'
            '\nNhiệt độ: ${data['main']['temp']}°C'
            '\nĐộ ẩm: ${data['main']['humidity']}%'
            '\nTốc độ gió: ${data['wind']['speed']} m/s'
            '\nÁp suất: ${data['main']['pressure']} hPa';

        sunriseTime = DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000).toLocal().toString();
        sunsetTime = DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000).toLocal().toString();

        addToHistory(cityName);
      });
    } else {
      setState(() {
        weatherInfo = 'Không tìm thấy thông tin thời tiết cho $cityName';
      });
    }
  }

  void fetchWeatherByLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    final lat = position.latitude;
    final lon = position.longitude;

    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=vi';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        weatherInfo = 'Thời tiết hiện tại:\n${data['weather'][0]['description']}'
            '\nNhiệt độ: ${data['main']['temp']}°C'
            '\nĐộ ẩm: ${data['main']['humidity']}%'
            '\nTốc độ gió: ${data['wind']['speed']} m/s';

        sunriseTime = DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000).toLocal().toString();
        sunsetTime = DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000).toLocal().toString();
      });
    } else {
      setState(() {
        weatherInfo = 'Không thể lấy thông tin thời tiết cho vị trí hiện tại';
      });
    }
  }

  void addToHistory(String city) {
    setState(() {
      if (!searchHistory.contains(city)) {
        searchHistory.add(city);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nhập tên thành phố',
              ),
              onSubmitted: (value) {
                setState(() {
                  cityName = value;
                  fetchWeather();
                });
              },
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                setState(() {
                  cityName = controller.text;
                  fetchWeather();
                });
              },
              child: Text('Xem dự báo thời tiết'),
            ),
            TextButton(
              onPressed: fetchWeatherByLocation,
              child: Text('Lấy thời tiết hiện tại'),
            ),
            SizedBox(height: 20),
            Text(
              weatherInfo,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            if (sunriseTime.isNotEmpty && sunsetTime.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      FaIcon(FontAwesomeIcons.solidSun, size: 40, color: Colors.orange),
                      Text('Mặt trời mọc', style: TextStyle(fontSize: 16)),
                      Text(sunriseTime.split(' ')[1], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      FaIcon(FontAwesomeIcons.solidSun, size: 40, color: Colors.red),
                      Text('Mặt trời lặn', style: TextStyle(fontSize: 16)),
                      Text(sunsetTime.split(' ')[1], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
            Divider(),
            Text(
              'Lịch sử tìm kiếm:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: searchHistory.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(searchHistory[index]),
                    onTap: () {
                      setState(() {
                        cityName = searchHistory[index];
                        fetchWeather();
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
