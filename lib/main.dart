import 'dart:math';

import 'package:dynamic_color_theme/dynamic_color_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sudoku/fade_dialog.dart';
import 'package:sudoku/game.dart';
import 'package:sudoku/leaderboard.dart';
import 'package:sudoku/painters.dart';
import 'package:sudoku/save_manager.dart';
import 'package:sudoku/sudoku.dart';
import 'package:sudoku/theme.dart';
import 'package:sudoku/tutorial.dart';
import 'package:system_theme/system_theme.dart';

import 'about.dart';
import 'color_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // set my favorite color as a fallback
  SystemTheme.fallbackColor = const Color.fromARGB(0xFF, 0xAA, 0x8E, 0xD6);

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]).then((_) => runApp(const Splash()));
}

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  SplashState createState() => SplashState();
}

class SplashState extends State<Splash> {
  Future<String> checkFirstSeen() async {
    bool seen = await SaveManager().hasSeenTutorial();

    if (seen) {
      return HomePage.id;
    } else {
      return Tutorial.id;
    }
  }

  @override
  void initState() {
    super.initState();
    checkFirstSeen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkFirstSeen(),
      builder: (context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        return DynamicColorTheme(
            data: (Color color, bool isDark) {
              return buildTheme(color, isDark);
            },
            defaultColor: SystemTheme.accentColor.accent,
            defaultIsDark: SystemTheme.isDarkMode,
            themedWidgetBuilder: (BuildContext context, ThemeData theme) {
              return MaterialApp(
                title: 'Sudoku',
                theme: theme,
                initialRoute: snapshot.data,
                routes: {
                  HomePage.id: (context) => const HomePage(),
                  Tutorial.id: (context) => const Tutorial(),
                },
              );
            });
      },
    );
  }
}

class HomePage extends StatefulWidget {
  static String id = 'HomePage';

  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _difficulty = 0;
  String _difficultyStr = "Medium";
  bool _hasSave = false;

  _HomePageState() {
    // start at saved difficulty
    SaveManager().getLastDifficulty().then((value) => _updateDifficulty(value));
  }

  void _updateDifficulty(int delta) {
    // clamp difficulty within bounds of array
    setState(() => _difficulty =
        max(0, min(difficulties.length - 1, _difficulty + delta)));

    Future<bool> saveFuture = SaveManager().saveExists(_difficulty);

    saveFuture.then((value) => setState(() {
          _difficultyStr = difficulties[_difficulty];
          _hasSave = value;
        }));

    SaveManager().saveLastDifficulty(_difficulty);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: DynamicColorTheme.of(context).isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                children: [
                  IconButton(
                    enableFeedback: false,
                    onPressed: null,
                    icon: Icon(Icons.color_lens,
                        color: Theme.of(context).canvasColor),
                  )
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(500)
                        //more than 50% of width makes circle
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CustomPaint(
                        size: Size(screenWidth * .50, screenWidth * .50),
                        painter: LogoPainter(Theme.of(context).canvasColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _difficulty == 0
                            ? null
                            : () {
                                _updateDifficulty(-1);
                              },
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) =>
                                      states.contains(MaterialState.disabled)
                                          ? Colors.grey
                                          : Theme.of(context).primaryColor),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0))),
                        ),
                        child: const Icon(Icons.arrow_left),
                      ),
                      SizedBox(
                        width: 100,
                        child: Center(
                          child: Text(
                            _difficultyStr,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _difficulty == difficulties.length - 1
                            ? null
                            : () {
                                _updateDifficulty(1);
                              },
                        style: ButtonStyle(
                          foregroundColor:
                              MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) =>
                                      states.contains(MaterialState.disabled)
                                          ? Colors.grey
                                          : Theme.of(context).primaryColor),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0))),
                        ),
                        child: const Icon(Icons.arrow_right),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton(
                      onPressed: () async {
                        final temp = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SudokuGame(difficulty: _difficulty),
                          ),
                        );
                        setState(() => _updateDifficulty(0));
                      },
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0))),
                        foregroundColor: MaterialStateProperty.all(
                            Theme.of(context).textTheme.bodyMedium!.color!),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("New Game", style: TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                  FutureBuilder<Sudoku>(
                      future: SaveManager().load(_difficulty),
                      builder:
                          (BuildContext context, AsyncSnapshot<Sudoku> sudoku) {
                        // TODO how can I check whether the AsyncSnapshot has completed yet?

                        return OutlinedButton(
                            onPressed: _hasSave
                                ? () async {
                                    final temp = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SudokuGame(
                                          difficulty: _difficulty,
                                          savedGame: sudoku.data!,
                                        ),
                                      ),
                                    );
                                    setState(() => _updateDifficulty(0));
                                  }
                                : null,
                            style: ButtonStyle(
                              shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(30.0))),
                              foregroundColor: MaterialStateProperty.all(
                                  Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color!
                                      .withOpacity(_hasSave ? 1 : 0.5)),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text("Continue",
                                  style: TextStyle(fontSize: 20)),
                            ));
                      }),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    color: Theme.of(context).textTheme.bodyMedium!.color!,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ColorSettings()),
                    ),
                    icon: const Icon(Icons.color_lens),
                  ),
                  IconButton(
                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                      onPressed: () => SaveManager()
                          .getScores(_difficulty)
                          .then((List<Score> scores) => fadePopup(
                              context,
                              AlertDialog(
                                title: const Center(child: Text("Scores")),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    makeLeaderboard(context, scores),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 16.0, 0, 0),
                                      child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          style: ButtonStyle(
                                            shape: MaterialStateProperty.all(
                                                RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30.0))),
                                          ),
                                          child: const Text("Close")),
                                    ),
                                  ],
                                ),
                              ),
                              dismissable: true)),
                      icon: const Icon(Icons.leaderboard)),
                  IconButton(
                      color: Theme.of(context).textTheme.bodyMedium!.color!,
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => const About()));
                      },
                      icon: const Icon(Icons.question_mark))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
