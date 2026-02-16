import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'screen/splash_screen.dart';
import 'screen/login_screen.dart';
import 'screen/dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';

void main() {
  // त्वरित सुरू होण्यासाठी ensureInitialized() आणि runApp() मध्ये अंतर नको
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
          useMaterial3: true, // उशीर टाळण्यासाठी नवीन रेंडरिंग इंजिन वापरा
          primaryColor: Color(0xFFE64A19),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          scaffoldBackgroundColor: Colors.white,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
        home: SplashScreen(),
        routes: {
          '/dashboard': (context) => DashboardScreen(),
          '/login': (context) => LoginScreen(),
        },
      ),
    );
  }
}
