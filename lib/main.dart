import 'package:anomaly/personal.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late TabController tabController;

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TabController tabController = TabController(length: 2, vsync: this);

    return Scaffold(
      primary: true,
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: TabBar(
              automaticIndicatorColorAdjustment: true,
              tabs: const [Text("personale"), Text("locazioni")],
              controller: tabController,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height - 50,
            child: TabBarView(
              controller: tabController,
              children: [
                const Personal(),
                const Flex(direction: Axis.vertical, children: []),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
