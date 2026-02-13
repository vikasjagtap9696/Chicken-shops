import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screen/splash_screen.dart';
import 'screen/login_screen.dart';
import 'screen/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

void main() async {
  // Ensures flutter is ready before rendering
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => DatabaseService()),
      ],
      child: MaterialApp(
        title: 'Chicken Mart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Color(0xFFE64A19),
          primarySwatch: Colors.orange,
          scaffoldBackgroundColor: Colors.white,
          fontFamily: GoogleFonts.poppins().fontFamily,
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFFE64A19),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        home: SplashScreen(),
        routes: {
          '/dashboard': (context) => DashboardScreen(),
          '/login': (context) => LoginScreen(),
          '/splash': (context) => SplashScreen(),
        },
      ),
    );
  }
}
