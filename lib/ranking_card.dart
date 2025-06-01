import 'package:flutter/material.dart';

class RankingCard extends StatelessWidget {
  const RankingCard(
      {super.key,
      required this.position,
      required this.name,
      required this.image,
      required this.profileId,
      required this.numOfQues,
      required this.easy,
      required this.hard,
      required this.medium});
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
    Color color = Color(0xff1E1E1E);
    if (position == '5') {
      color = Colors.white;
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: constraints.maxWidth * 1 / 5,
              child: Center(
                child: Text(
                  position.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: constraints.maxWidth * .05),
                ),
              ),
            ),
            SizedBox(
              width: constraints.maxWidth * 4 / 5,
              // height: MediaQuery.of(context).size.height * .10,
              child: AspectRatio(
                aspectRatio: 16 / 4,
                child: Material(
                  // color: Color(),
                  color: color,
                  borderRadius: BorderRadius.circular(50),
                  elevation: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 26, 38, 48),
                        backgroundImage: NetworkImage(image),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            profileId,
                            style:
                                TextStyle(fontSize: 14, color: Colors.blueGrey),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              easy,
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              medium,
                              style: TextStyle(color: Colors.orangeAccent),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              hard,
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              numOfQues.toString(),
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
