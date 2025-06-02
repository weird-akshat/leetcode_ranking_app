import 'package:flutter/material.dart';

class RankingCard extends StatelessWidget {
  const RankingCard({
    super.key,
    required this.position,
    required this.name,
    required this.image,
    required this.profileId,
    required this.numOfQues,
    required this.easy,
    required this.hard,
    required this.medium,
  });

  final String position;
  final String numOfQues;
  final String name;
  final String profileId;
  final String image;
  final String easy;
  final String medium;
  final String hard;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = const Color(0xff1E1E1E);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Fixed width for position
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  position,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color.fromARGB(255, 26, 38, 48),
              backgroundImage: NetworkImage(image),
            ),

            const SizedBox(width: 16),

            // Name and profileId
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold)),
                  Text(profileId,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.blueGrey))
                ],
              ),
            ),

            // Stats
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(easy, Colors.green),
                  _buildStat(medium, Colors.orangeAccent),
                  _buildStat(hard, Colors.redAccent),
                  _buildStat(numOfQues, Colors.blue, bold: true),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String text, Color color, {bool bold = false}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
        fontSize: 14,
      ),
    );
  }
}
