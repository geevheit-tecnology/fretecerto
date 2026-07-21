import 'package:url_launcher/url_launcher.dart';

class AnttOfficialConsultationService {
  const AnttOfficialConsultationService();

  static final Uri officialCalculatorUri = Uri.parse(
    'https://calculadorafrete.antt.gov.br/',
  );

  Future<bool> openOfficialCalculator() {
    return launchUrl(
      officialCalculatorUri,
      mode: LaunchMode.externalApplication,
    );
  }
}
