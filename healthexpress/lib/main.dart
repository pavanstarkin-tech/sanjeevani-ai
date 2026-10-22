import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_assistant_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/pharmacy_provider.dart';
import 'providers/doctor_portal_provider.dart';
import 'providers/store_provider.dart';
import 'providers/offline_medical_slm_provider.dart';
import 'services/offline_health_grid_service.dart';
import 'services/explainable_clinical_ai_service.dart';
import 'services/emergency_medicine_hold_service.dart';
import 'services/government_scheme_service.dart';
import 'services/public_health_surveillance_service.dart';
import 'providers/doctor_reels_provider.dart';
import 'core/constants/app_constants.dart';
import 'screens/common/splash_screen.dart';
import 'screens/user/user_main_nav.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/doctor/doctor_main_nav.dart';
import 'screens/store/store_main_nav.dart';

import 'data/production_database.dart';
import 'services/clinical_rag_service.dart';
import 'services/api_service.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Disable runtime HTTP fetching so offline operations never fail with SocketException
  GoogleFonts.config.allowRuntimeFetching = false;
  await AppConfig.loadEnv();
  ApiService.fetchActiveSarvamKey();
  ProductionDatabase.syncWithLiveBackend();
  ClinicalRagService.instance.init();
  runApp(const SanjeevaniApp());
}

class SanjeevaniApp extends StatelessWidget {
  const SanjeevaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AiAssistantProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => PharmacyProvider()),
        ChangeNotifierProvider(create: (_) => DoctorPortalProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => OfflineMedicalSlmProvider()),
        ChangeNotifierProvider(create: (_) => OfflineHealthGridService()),
        ChangeNotifierProvider(create: (_) => ExplainableClinicalAiService()),
        ChangeNotifierProvider(create: (_) => EmergencyMedicineHoldService()),
        ChangeNotifierProvider(create: (_) => GovernmentSchemeService()),
        ChangeNotifierProvider(create: (_) => PublicHealthSurveillanceService()),
        ChangeNotifierProvider(create: (_) => DoctorReelsProvider()),
        ChangeNotifierProvider.value(value: ClinicalRagService.instance),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Sanjeevani.AI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: auth.isAuthenticated && auth.isOnboarded
                ? (auth.currentRole == UserRole.doctor
                    ? const DoctorMainNav()
                    : (auth.currentRole == UserRole.store
                        ? const StoreMainNav()
                        : const UserMainNav()))
                : const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Backward compatibility alias
typedef HealthExpressApp = SanjeevaniApp;
