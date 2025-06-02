import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import your existing pages
import 'package:leetcode_ranking/leaderboard_page.dart';
import 'package:leetcode_ranking/custom_leaderboard.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int selectedIndex = 0;
  bool isLoading = false;
  bool isReloading = false;

  // Keys to force rebuild of pages
  final List<GlobalKey> pageKeys = [
    GlobalKey(),
    GlobalKey(),
  ];

  // List of pages
  List<Widget> get pages => [
        LeaderboardPage(key: pageKeys[0]), // Your existing leaderboard page
        CustomLeaderboard(key: pageKeys[1]), // Your custom leaderboard page
      ];

  final List<String> pageTitles = [
    'Leaderboard',
    'Custom Leaderboard',
  ];

  final List<IconData> pageIcons = [
    Icons.leaderboard,
    Icons.group,
  ];

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    // Close drawer on mobile
    if (MediaQuery.of(context).size.width < 768) {
      Navigator.pop(context);
    }
  }

  Future<void> _reloadCurrentPage() async {
    setState(() => isReloading = true);

    try {
      // Force rebuild by creating a new key for the current page
      setState(() {
        pageKeys[selectedIndex] = GlobalKey();
      });

      // Add a small delay to show the loading indicator
      await Future.delayed(Duration(milliseconds: 300));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pageTitles[selectedIndex]} reloaded'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reloading page: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isReloading = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        // Navigate to login page - replace with your actual login route
        Navigator.of(context).pushReplacementNamed('/login');
        // Or if you're using a specific login widget:
        // Navigator.of(context).pushReplacement(
        //   MaterialPageRoute(builder: (context) => LoginPage()),
        // );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<bool?> _showLogoutConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'LeetCode Ranking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      Supabase.instance.client.auth.currentUser?.email ??
                          'User',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: pageTitles.length,
              itemBuilder: (context, index) {
                final isSelected = selectedIndex == index;
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                  ),
                  child: ListTile(
                    leading: Icon(
                      pageIcons[index],
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    title: Text(
                      pageTitles[index],
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : Colors.grey[800],
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _onItemTapped(index),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout Button
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : () async {
                        final confirm = await _showLogoutConfirmDialog();
                        if (confirm == true) {
                          await _logout();
                        }
                      },
                icon: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.logout),
                label: Text(isLoading ? 'Signing out...' : 'Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitles[selectedIndex]),
        leading: MediaQuery.of(context).size.width < 768
            ? Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: Icon(Icons.menu),
                ),
              )
            : null,
        automaticallyImplyLeading: MediaQuery.of(context).size.width < 768,
        actions: [
          // Reload button
          IconButton(
            onPressed: isReloading ? null : _reloadCurrentPage,
            icon: isReloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).appBarTheme.foregroundColor ??
                            Colors.black,
                      ),
                    ),
                  )
                : Icon(Icons.refresh),
            tooltip: 'Reload ${pageTitles[selectedIndex]}',
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width < 768 ? _buildSidebar() : null,
      body: Row(
        children: [
          // Desktop Sidebar
          if (MediaQuery.of(context).size.width >= 768)
            Container(
              width: 280,
              child: _buildSidebar(),
            ),

          // Main Content
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}
