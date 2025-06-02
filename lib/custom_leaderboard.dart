import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:leetcode_ranking/ranking_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomLeaderboard extends StatefulWidget {
  const CustomLeaderboard({super.key});

  @override
  State<CustomLeaderboard> createState() => _LeaderboardPageState();
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

    return score(b).compareTo(score(a));
  });
}

class _LeaderboardPageState extends State<CustomLeaderboard> {
  bool isLoading = true;
  List<Map<String, dynamic>> list = [];
  List<String> usernames = [];

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
        final matchedUser = data['data']['matchedUser'];
        // Return null if user doesn't exist
        return matchedUser;
      }
    } catch (e) {
      debugPrint('LeetCode API error for $username: $e');
    }
    return null;
  }

  Future<void> fetchAllProfiles(List data) async {
    list.clear();
    usernames.clear();
    List<Future<void>> tasks = [];

    for (final entry in data) {
      final username = entry['leetcode_id'];
      usernames.add(username);
      tasks.add(_processUser(username));
    }

    await Future.wait(tasks);
  }

  Future<void> _processUser(String username) async {
    final localData = await fetchFromSupabase(username);

    if (localData != null) {
      list.add(localData);
      if (localData['stale'] == true) {
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

  Future<void> _reloadLeaderboard() async {
    setState(() => isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;

    final data = await Supabase.instance.client
        .from('user_leetcode_list')
        .select('leetcode_id')
        .eq('user_id', user!.id);

    final usernames =
        data.map((row) => {'leetcode_id': row['leetcode_id']}).toList();

    await fetchAllProfiles(usernames);
    setState(() {
      sortLeetCodeUsers(list);
      isLoading = false;
    });
  }

  Future<void> _addLeetCodeIdDialog() async {
    final controller = TextEditingController();
    bool isValidating = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add LeetCode ID'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration:
                    InputDecoration(hintText: 'Enter LeetCode username'),
                enabled: !isValidating,
              ),
              if (isValidating)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Validating user...'),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isValidating ? null : () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isValidating
                  ? null
                  : () async {
                      final username = controller.text.trim();
                      if (username.isEmpty) return;

                      setDialogState(() => isValidating = true);

                      // Check if user exists on LeetCode
                      final user = await fetchFromLeetCode(username);

                      if (user == null) {
                        setDialogState(() => isValidating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'User "$username" does not exist on LeetCode.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Check if user is already in the list
                      final currentUser =
                          Supabase.instance.client.auth.currentUser!.id;
                      final existingUsers = await Supabase.instance.client
                          .from('user_leetcode_list')
                          .select('leetcode_id')
                          .eq('user_id', currentUser)
                          .eq('leetcode_id', username);

                      if (existingUsers.isNotEmpty) {
                        setDialogState(() => isValidating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'User "$username" is already in your list.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      try {
                        // Add user to the list
                        await Supabase.instance.client
                            .from('user_leetcode_list')
                            .upsert({
                          'user_id': currentUser,
                          'leetcode_id': username,
                        });

                        await updateSupabase(username, user);

                        Navigator.pop(context); // Close dialog

                        // Reload the leaderboard
                        await _reloadLeaderboard();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "$username" to your list.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        setDialogState(() => isValidating = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding user: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeUser(String username) async {
    final currentUser = Supabase.instance.client.auth.currentUser!.id;
    debugPrint(
        'Attempting to delete user_leetcode_list row for user_id=$currentUser, leetcode_id=$username');

    try {
      // First, let's find the actual record (case-insensitive)
      final allUserRecords = await Supabase.instance.client
          .from('user_leetcode_list')
          .select('*')
          .eq('user_id', currentUser);

      debugPrint('All records for current user: $allUserRecords');
      debugPrint('Looking for username: $username');

      // Find the record with case-insensitive matching
      final matchingRecord = allUserRecords.firstWhere(
        (record) =>
            record['leetcode_id'].toString().toLowerCase() ==
            username.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (matchingRecord.isEmpty) {
        debugPrint('No record found to delete (even case-insensitive)');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User $username not found in your list.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final actualLeetcodeId = matchingRecord['leetcode_id'].toString();
      final recordId = matchingRecord['id'];

      debugPrint(
          'Found matching record with leetcode_id: $actualLeetcodeId, id: $recordId');

      // Delete using the primary key (most reliable)
      await Supabase.instance.client
          .from('user_leetcode_list')
          .delete()
          .eq('id', recordId);

      debugPrint('Delete operation completed using id: $recordId');

      // Verify deletion using the record ID
      final verifyDeletion = await Supabase.instance.client
          .from('user_leetcode_list')
          .select('*')
          .eq('id', recordId)
          .maybeSingle();

      if (verifyDeletion != null) {
        debugPrint('Record still exists after deletion attempt');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove $username from database.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      debugPrint('Record successfully deleted from database');

      // Remove from local state using case-insensitive matching
      setState(() {
        list.removeWhere((profile) =>
            profile['username'].toString().toLowerCase() ==
            username.toLowerCase());
        usernames.removeWhere(
            (name) => name.toLowerCase() == username.toLowerCase());
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed $username from your list.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error deleting user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing $username: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      // Reload to restore state if deletion failed
      await _reloadLeaderboard();
    }
  }

  Future<bool?> _showRemoveConfirmDialog(String username) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove LeetCode ID'),
        content: Text('Remove "$username" from your list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _reloadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addLeetCodeIdDialog,
        child: Icon(Icons.add),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
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

                        return Dismissible(
                          key: Key(username),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            final confirm =
                                await _showRemoveConfirmDialog(username);
                            if (confirm == true) {
                              await _removeUser(username);
                              return true; // Allow dismissal
                            }
                            return false; // Prevent dismissal
                          },
                          child: RankingCard(
                            position: (index + 1).toString(),
                            name: name,
                            image: image,
                            profileId: username,
                            numOfQues: allSolved.toString(),
                            easy: easySolved.toString(),
                            hard: hardSolved.toString(),
                            medium: mediumSolved.toString(),
                          ),
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
