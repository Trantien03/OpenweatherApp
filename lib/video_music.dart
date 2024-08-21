import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:share/share.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Music App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MusicScreen(),
    );
  }
}

class MusicScreen extends StatefulWidget {
  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController controller = TextEditingController();
  String singerName = '';
  String videoTitle = '';
  String channelTitle = '';
  String videoId = '';
  String searchType = 'singer';
  String videoDescription = '';
  String publishDate = '';
  List<Map<String, String>> favoriteSongs = [];
  List relatedSongs = [];

  void fetchMusic() async {
    final apiKey = 'YOUR_API_KEY';
    String query = '';

    if (searchType == 'genre') {
      query = 'genre: ${Uri.encodeComponent(controller.text)}';
    } else {
      query = '${Uri.encodeComponent(controller.text)}';
    }

    final url = 'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['items'].isNotEmpty) {
        setState(() {
          videoId = data['items'][0]['id']['videoId'];
          videoTitle = data['items'][0]['snippet']['title'];
          channelTitle = data['items'][0]['snippet']['channelTitle'];
          videoDescription = data['items'][0]['snippet']['description'];
          publishDate = data['items'][0]['snippet']['publishedAt'];
        });

        fetchRelatedSongs();
      } else {
        setState(() {
          videoId = '';
          videoTitle = 'Không tìm thấy bài hát';
          channelTitle = '';
          videoDescription = '';
          publishDate = '';
        });
      }
    } else {
      setState(() {
        videoId = '';
        videoTitle = 'Lỗi kết nối';
        channelTitle = '';
        videoDescription = '';
        publishDate = '';
      });
    }
  }

  void fetchRelatedSongs() async {
    final apiKey = 'YOUR_API_KEY';
    final suggestionUrl =
        'https://www.googleapis.com/youtube/v3/search?relatedToVideoId=$videoId&type=video&key=$apiKey';

    final suggestionResponse = await http.get(Uri.parse(suggestionUrl));

    if (suggestionResponse.statusCode == 200) {
      final suggestionData = json.decode(suggestionResponse.body);
      setState(() {
        relatedSongs = suggestionData['items'];
      });
    }
  }

  void addToFavorites() {
    setState(() {
      favoriteSongs.add({
        'videoId': videoId,
        'title': videoTitle,
        'channel': channelTitle,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('YouTube Music App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Nhập tên ca sĩ hoặc thể loại',
                ),
                onSubmitted: (value) {
                  setState(() {
                    singerName = value;
                    fetchMusic();
                  });
                },
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: searchType,
                items: [
                  DropdownMenuItem(value: 'singer', child: Text('Tìm theo ca sĩ')),
                  DropdownMenuItem(value: 'genre', child: Text('Tìm theo thể loại')),
                ],
                onChanged: (value) {
                  setState(() {
                    searchType = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    singerName = controller.text;
                    fetchMusic();
                  });
                },
                child: Text('Xem bài hát'),
              ),
              SizedBox(height: 20),
              if (videoId.isNotEmpty) ...[
                YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: videoId,
                    flags: YoutubePlayerFlags(
                      autoPlay: false,
                      mute: false,
                    ),
                  ),
                  showVideoProgressIndicator: true,
                ),
                SizedBox(height: 20),
                Text(
                  'Bài hát: $videoTitle',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Ca sĩ: $channelTitle',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Mô tả: $videoDescription',
                  style: TextStyle(fontSize: 14),
                ),
                Text(
                  'Ngày phát hành: ${publishDate.substring(0, 10)}',
                  style: TextStyle(fontSize: 14),
                ),
                ElevatedButton(
                  onPressed: addToFavorites,
                  child: Text('Lưu vào danh sách yêu thích'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Share.share('Nghe bài hát này: https://www.youtube.com/watch?v=$videoId');
                  },
                  child: Text('Chia sẻ'),
                ),
                Divider(),
                Text('Bài hát gợi ý', style: TextStyle(fontSize: 18)),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: relatedSongs.length,
                  itemBuilder: (context, index) {
                    final song = relatedSongs[index];
                    return ListTile(
                      title: Text(song['snippet']['title']),
                      subtitle: Text(song['snippet']['channelTitle']),
                    );
                  },
                ),
              ] else if (videoTitle.isNotEmpty) ...[
                Text(
                  videoTitle,
                  style: TextStyle(fontSize: 18),
                ),
              ],
              Divider(),
              Text('Danh sách yêu thích', style: TextStyle(fontSize: 18)),
              ListView.builder(
                shrinkWrap: true,
                itemCount: favoriteSongs.length,
                itemBuilder: (context, index) {
                  final song = favoriteSongs[index];
                  return ListTile(
                    title: Text(song['title']!),
                    subtitle: Text(song['channel']!),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
