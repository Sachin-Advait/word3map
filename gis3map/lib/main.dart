// ignore_for_file: constant_identifier_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:word3map/routes/pages.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.white,
      systemNavigationBarColor: Colors.white,
    ),
  );

  runApp(const MyApp());
}

const double CELL_SIZE = 3.0;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: AppPages.getInitialRoute(),
      onGenerateRoute: AppPages.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}
