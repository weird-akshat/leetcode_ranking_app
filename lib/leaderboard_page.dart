import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:leetcode_ranking/ranking_card.dart';
import 'package:leetcode_ranking/registeration_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LeaderboardPage extends StatefulWidget {
  LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

void sortLeetCodeUsers(List<Map<String, dynamic>> users) {
  users.sort((a, b) {
    int score(Map<String, dynamic> user) {
      final submissions = user['submitStats']['acSubmissionNum'] as List;
      int easy =
          submissions.firstWhere((d) => d['difficulty'] == 'Easy')['count'];
      int medium =
          submissions.firstWhere((d) => d['difficulty'] == 'Medium')['count'];
      int hard =
          submissions.firstWhere((d) => d['difficulty'] == 'Hard')['count'];
      return 3 * hard + 2 * medium + 1 * easy;
    }

    return score(b).compareTo(score(a)); // Descending order
  });
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> list = [];

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

  Future<Map<String, dynamic>?> fetchFromSupabase(String username) async {
    final result = await Supabase.instance.client
        .from('leetcode_users')
        .select()
        .eq('username', username)
        .maybeSingle();

    if (result == null) return null;

    final lastUpdated = DateTime.parse(result['last_updated']).toUtc();
    final now = DateTime.now().toUtc();

    if (now.difference(lastUpdated) < Duration(minutes: 15)) {
      return result['data'];
    }

    return result['data']..['stale'] = true;
  }

  Future<void> updateSupabase(
      String username, Map<String, dynamic> user) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await Supabase.instance.client.from('leetcode_users').upsert({
      'username': username,
      'data': user,
      'last_updated': now,
    });
  }

  Future<Map<String, dynamic>?> fetchFromLeetCode(String username) async {
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
        return data['data']['matchedUser'];
      }
    } catch (e) {
      debugPrint('LeetCode API error for $username: $e');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    () async {
      final data = await Supabase.instance.client.from('details').select();
      await fetchAllProfiles(data);
      setState(() {
        sortLeetCodeUsers(list);
        isLoading = false;
      });
    }();
  }

  Future<void> fetchAllProfiles(List data) async {
    List<Future<void>> tasks = [];

    for (final entry in data) {
      final username = entry['leetcode_id'];
      tasks.add(_processUser(username));
    }

    await Future.wait(tasks);
  }

  Future<void> _processUser(String username) async {
    final localData = await fetchFromSupabase(username);

    if (localData != null) {
      list.add(localData);
      if (localData['stale'] == true) {
        // Refresh in background
        fetchFromLeetCode(username).then((user) {
          if (user != null) updateSupabase(username, user);
        });
      }
    } else {
      final freshUser = await fetchFromLeetCode(username);
      if (freshUser != null) {
        list.add(freshUser);
        await updateSupabase(username, freshUser);
      }
    }
  }

  Future<void> storeLeetCodeUsers(List<Map<String, dynamic>> users) async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now().toUtc();

    final rows = users
        .map((user) => {
              'username': user['username'],
              'data': user,
              'last_updated': now.toIso8601String(),
            })
        .toList();

    final response = await supabase.from('leetcode_users').upsert(rows);

    if (response.error != null) {
      throw Exception(
          'Failed to store LeetCode data: ${response.error!.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(),
          )
        : SafeArea(
            child: Scaffold(
              body: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final profile = list[index];

                          final name =
                              profile['profile']?['realName'] ?? 'Anonymous';
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
                    ),
                    // ElevatedButton(
                    //     onPressed: () {
                    //       print(list);
                    //     },
                    //     child: Text('data'))
                  ],
                ),
              ),
            ),
          );
  }
}
