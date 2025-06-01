import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:leetcode_ranking/ranking_card.dart';

class LeaderboardPage extends StatefulWidget {
  LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final list = [];

  Future<void> fetchLeetCodeProfile(String username) async {
    final url = Uri.parse('https://leetcode.com/graphql');
    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'query': '''
      query getUserProfile(\$username: String!) {
        matchedUser(username: \$username) {
          username
          profile {
            realName
            userAvatar
          }
          submitStats {
            acSubmissionNum {
              difficulty
              count
            }
          }
        }
      }
    ''',
      'variables': {'username': username},
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data['data']['matchedUser'];

        if (user != null) {
          list.add(user);
          // print('Username: ${user['username']}');
          // print('Real Name: ${user['profile']['realName']}');
          // print('Avatar: ${user['profile']['userAvatar']}');
          // print('AC Stats: ${user['submitStats']['acSubmissionNum']}');

          // print(list);
        } else {
          print('User not found.');
        }
      } else {
        print('Failed to fetch profile. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    print('a');
    () async {
      print('b');
      await fetchLeetCodeProfile('Roonil03');
      setState(() {});

      print('c');
    }();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Leaderboard',
            style: TextStyle(
                fontSize: MediaQuery.of(context).size.height * .025,
                fontWeight: FontWeight.bold),
          ),
          leading:
              IconButton(onPressed: () {}, icon: Icon(Icons.arrow_back_ios)),
        ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final profile = list[index];

                    final name = profile['profile']?['realName'] ?? 'Anonymous';
                    final image = profile['profile']?['userAvatar'] ?? '';
                    final username = profile['username'] ?? 'N/A';

                    final acSubmissions =
                        profile['submitStats']?['acSubmissionNum'] ?? [];
                    final allSolved = acSubmissions.firstWhere(
                      (item) => item['difficulty'] == 'All',
                      orElse: () => {'count': 0},
                    )['count'];
                    final easySolved = acSubmissions.firstWhere(
                      (item) => item['difficulty'] == 'Easy',
                      orElse: () => {'count': 0},
                    )['count'];
                    final mediumSolved = acSubmissions.firstWhere(
                      (item) => item['difficulty'] == 'Medium',
                      orElse: () => {'count': 0},
                    )['count'];
                    final hardSolved = acSubmissions.firstWhere(
                      (item) => item['difficulty'] == 'Hard',
                      orElse: () => {'count': 0},
                    )['count'];

                    return RankingCard(
                      position: (index + 1).toString(),
                      name: name,
                      image: image,
                      profileId: username,
                      numOfQues: allSolved.toString(),
                      easy: easySolved.toString(),
                      hard: hardSolved.toString(),
                      medium: mediumSolved.toString(),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
