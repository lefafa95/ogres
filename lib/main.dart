import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:fl_chart/fl_chart.dart';

const String kBaseUrl = 'http://192.168.1.20:8080';
const Color kBleuFonce = Color(0xFF0D1B2A);
const Color kBleuMoyen = Color(0xFF1A3A5C);
const Color kOrange = Color(0xFFE87722);
const Color kVert = Color(0xFF2ECC71);
const Color kRouge = Color(0xFFE74C3C);
const Color kJaune = Color(0xFFF1C40F);

// ─────────────────────────────────────────────
// LANGUAGE NOTIFIER
// ─────────────────────────────────────────────
class LanguageNotifier extends ValueNotifier<String> {
  static final LanguageNotifier _instance = LanguageNotifier._internal();
  factory LanguageNotifier() => _instance;
  LanguageNotifier._internal() : super('fr');
}

final languageNotifier = LanguageNotifier();

// ─────────────────────────────────────────────
// APP LOCALIZATIONS
// ─────────────────────────────────────────────
class AppLocalizations {
  static Map<String, String> _translations = {};

  static void initEmpty() {
    _translations = {};
  }

  static Future<void> load(String locale) async {
    final String jsonString =
        await rootBundle.loadString('assets/i18n/$locale.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _translations =
        jsonMap.map((key, value) => MapEntry(key, value.toString()));
    languageNotifier.value = locale;
  }

  static String tr(String key) => _translations[key] ?? key;
}

String tr(String key) => AppLocalizations.tr(key);

// ─────────────────────────────────────────────
// LANGUAGE SELECTOR WIDGET
// ─────────────────────────────────────────────
class LanguageSelectorWidget extends StatelessWidget {
  const LanguageSelectorWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, currentLang, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _flagButton('fr', '🇫🇷', currentLang),
            _flagButton('en', '🇬🇧', currentLang),
            _flagButton('de', '🇩🇪', currentLang),
            const SizedBox(width: 4),
          ],
        );
      },
    );
  }

  Widget _flagButton(String locale, String flag, String currentLang) {
    final isSelected = locale == currentLang;
    return GestureDetector(
      onTap: () async {
        await AppLocalizations.load(locale);
        languageNotifier.value = locale;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
        ),
        child: Text(flag, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// LOCALIZED PAGE MIXIN
// ─────────────────────────────────────────────
mixin LocalizedPage<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    languageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    languageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }
}

// ─────────────────────────────────────────────
// STATS CALAGE
// ─────────────────────────────────────────────
class StatsCalage {
  final double devStd;
  final double devMin;
  final double devMax;
  final double sommeEcartsQuad;
  final double devMoy;

  StatsCalage({
    required this.devStd,
    required this.devMin,
    required this.devMax,
    required this.sommeEcartsQuad,
    required this.devMoy,
  });

  static StatsCalage compute(List<double> reels, List<double> simules) {
    if (reels.isEmpty || simules.isEmpty) {
      return StatsCalage(devStd: 0, devMin: 0, devMax: 0, sommeEcartsQuad: 0, devMoy: 0);
    }
    final n = min(reels.length, simules.length);
    final deviations = List.generate(n, (i) => simules[i] - reels[i]);
    final moy = deviations.reduce((a, b) => a + b) / n;
    final variance = deviations.map((d) => (d - moy) * (d - moy)).reduce((a, b) => a + b) / n;
    final std = sqrt(variance);
    final minDev = deviations.reduce((a, b) => a < b ? a : b);
    final maxDev = deviations.reduce((a, b) => a > b ? a : b);
    final somme = deviations.map((d) => d * d).reduce((a, b) => a + b);
    return StatsCalage(
      devStd: double.parse(std.toStringAsFixed(2)),
      devMin: double.parse(minDev.toStringAsFixed(2)),
      devMax: double.parse(maxDev.toStringAsFixed(2)),
      sommeEcartsQuad: double.parse(somme.toStringAsFixed(2)),
      devMoy: double.parse(moy.toStringAsFixed(2)),
    );
  }
}

// ─────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLocalizations.initEmpty();
  runApp(const OgresApp());
}

class OgresApp extends StatelessWidget {
  const OgresApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, lang, _) {
        return MaterialApp(
          title: 'OGRES',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: kBleuMoyen, brightness: Brightness.dark),
            useMaterial3: true,
          ),
          home: const SitesListPage(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// PAGE : LISTE DES SITES
// ─────────────────────────────────────────────
class SitesListPage extends StatefulWidget {
  const SitesListPage({super.key});
  @override
  State<SitesListPage> createState() => _SitesListPageState();
}

class _SitesListPageState extends State<SitesListPage> with LocalizedPage {
  List<dynamic> _sites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  Future<void> _loadSites() async {
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl/api/sites'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        setState(() {
          _sites = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = tr('Erreur chargement des sites');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showLoginDialog(Map<String, dynamic> site) {
    final passwordController = TextEditingController();
    String? errorMsg;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kBleuMoyen,
          title: Text(site['nom'] ?? '',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: tr('Mot de passe'),
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kOrange),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              if (errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorMsg!, style: const TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('Annuler'), style: const TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  final r = await http
                      .get(Uri.parse('$kBaseUrl/api/sites/nom/${site['nom']}'))
                      .timeout(const Duration(seconds: 5));
                  if (r.statusCode == 200) {
                    final s = jsonDecode(r.body);
                    final salt = [5, 3, 3, 100];
                    final hash = sha256
                        .convert([...salt, ...utf8.encode(passwordController.text)])
                        .toString();
                    if (s['password'] == hash) {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CavitePage(
                            siteName: site['nom'],
                            siteId: site['id'],
                          ),
                        ),
                      );
                    } else {
                      setDialogState(() => errorMsg = tr('Mot de passe incorrect'));
                    }
                  } else {
                    setDialogState(() => errorMsg = tr('Site introuvable'));
                  }
                } catch (e) {
                  setDialogState(() => errorMsg = tr('Erreur de connexion'));
                }
              },
              child: Text(tr('Connexion')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBleuFonce,
      appBar: AppBar(
        backgroundColor: kBleuMoyen,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('OGRES',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            const SizedBox(width: 12),
            Text(tr('LISTE DES SITES'),
                style: const TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        actions: [
          const LanguageSelectorWidget(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { setState(() => _isLoading = true); _loadSites(); },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSites,
                        style: ElevatedButton.styleFrom(backgroundColor: kOrange),
                        child: Text(tr('Réessayer')),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sites.length,
                  itemBuilder: (context, index) {
                    final site = _sites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: kBleuMoyen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.location_on, color: kOrange),
                        ),
                        title: Text(site['nom'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text('${site['ville'] ?? ''} ${site['pays'] ?? ''}',
                            style: const TextStyle(color: Colors.white54)),
                        trailing: const Icon(Icons.chevron_right, color: kOrange),
                        onTap: () => _showLoginDialog(Map<String, dynamic>.from(site)),
                      ),
                    );
                  },
                ),
    );
  }
}

// ─────────────────────────────────────────────
// PAGE : CAVITÉS DU SITE
// ─────────────────────────────────────────────
class CavitePage extends StatefulWidget {
  final String siteName;
  final int siteId;
  const CavitePage({super.key, required this.siteName, required this.siteId});
  @override
  State<CavitePage> createState() => _CavitePageState();
}

class _CavitePageState extends State<CavitePage> with LocalizedPage {
  List<dynamic> _cavites = [];
  Map<String, dynamic>? _cavite;
  List<dynamic> _realData = [];
  bool _isLoading = true;
  bool _isLoadingData = false;
  String? _errorMessage;
  DateTime? _dateDebut;
  DateTime? _dateFin;

  // Simulation
  bool _isSimulating = false;
  bool _simulationDone = false;
  List<FlSpot> _presReelSpots = [];
  List<FlSpot> _presSimuleSpots = [];
  List<FlSpot> _tempReelSpots = [];
  List<FlSpot> _tempSimuleSpots = [];
  List<FlSpot> _debitSpots = [];
  List<FlSpot> _stockSpots = [];
  List<FlSpot> _pCasingShoeSpots = [];
  List<FlSpot> _tCasingShoeSpots = [];
  List<FlSpot> _pCavernSpots = [];
  List<FlSpot> _tCavernSpots = [];
  List<FlSpot> _pCasingShoeSimSpots = [];
  List<FlSpot> _tCasingShoeSimSpots = [];
  List<FlSpot> _pCavernSimSpots     = [];
  List<FlSpot> _tCavernSimSpots     = [];
  bool _isCalculatingGip = false;
  bool _gipDone = false;
  Map<String, dynamic>? _gipResult;
  StatsCalage? _statsPression;
  StatsCalage? _statsTemp;
  String? _simDateFrom;
  String? _simDateTo;

  @override
  void initState() {
    super.initState();
    _loadCavites();
  }

  Future<void> _loadCavites() async {
    try {
      final response = await http
          .get(Uri.parse('$kBaseUrl/api/cavities/site/${widget.siteId}'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final filtered = data.where((c) => !(c['nom'] as String).startsWith('Pool')).toList();
        setState(() {
          _cavites = filtered;
          _cavite = filtered.isNotEmpty ? Map<String, dynamic>.from(filtered[0]) : null;
          _isLoading = false;
        });
        if (_cavite != null) await _loadRealData();
      } else {
        setState(() {
          _errorMessage = tr('Erreur chargement des cavités');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = tr('Impossible de joindre le serveur');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRealData() async {
    if (_cavite == null) return;
    setState(() => _isLoadingData = true);
    try {
      String url = '$kBaseUrl/api/realdata/cavity/${_cavite!['id']}';
      if (_dateDebut != null && _dateFin != null) {
        url += '?from=${_fmtDate(_dateDebut!)}&to=${_fmtDate(_dateFin!)}';
      }
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      print('RealData URL: $url | Status: ${response.statusCode} | Length: ${response.body.length}');
      if (response.statusCode == 200) {
        setState(() {
          _realData = jsonDecode(response.body);
          _isLoadingData = false;
          if (_realData.isNotEmpty && _dateDebut == null && _dateFin == null) {
            _dateDebut = DateTime.parse(_realData.first['date'].toString().substring(0, 10));
            _dateFin = DateTime.parse(_realData.last['date'].toString().substring(0, 10));
          }
        });
      } else {
        setState(() => _isLoadingData = false);
      }
    } catch (e) {
      print('Erreur _loadRealData: $e');
      setState(() => _isLoadingData = false);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _lancerSimulation() async {
    if (_cavite == null) return;
    setState(() { _isSimulating = true; _simulationDone = false; });

    final cavityId = _cavite!['id'];

    try {
      // ── Étape 1 : récupérer la date de début du calage ──
      print('>>> Récupération calage cavity $cavityId...');
      final rCalage = await http
          .get(Uri.parse('$kBaseUrl/api/calages/cavity/$cavityId'))
          .timeout(const Duration(seconds: 10));

      String dateFrom = '';
      if (rCalage.statusCode == 200) {
        final calages = jsonDecode(rCalage.body) as List<dynamic>;
        if (calages.isNotEmpty) {
          // Prendre le calage le plus récent
          final calage = calages.last;
          dateFrom = calage['dateFrom']?.toString().substring(0, 10) ?? '';
          print('Calage dateFrom: $dateFrom');
        }
      }

      // ── Étape 2 : date de fin = dernière date de l'historique ──
      String dateTo = _realData.isNotEmpty
          ? _realData.last['date'].toString().substring(0, 10)
          : '';

      print('=== SIMULATION START === cavityId=$cavityId from=$dateFrom to=$dateTo');

      // ── Étape 3 : appel simulation ──
      final uri = Uri(
        scheme: 'http',
        host: kBaseUrl.replaceAll('http://', '').split(':')[0],
        port: 8080,
        path: '/api/simulate/cavity/$cavityId',
        queryParameters: {
          if (dateFrom.isNotEmpty) 'from': dateFrom,
          if (dateTo.isNotEmpty) 'to': dateTo,
        },
      );
      print('Simulation URI: $uri');

      final response = await http.get(uri).timeout(const Duration(seconds: 60));
      print('Simulation status: ${response.statusCode} / length: ${response.body.length}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<FlSpot> presReel = [];
        final List<FlSpot> presSimule = [];
        final List<FlSpot> tempReel = [];
        final List<FlSpot> tempSimule = [];
        final List<FlSpot> debit = [];
        final List<FlSpot> stock = [];
        final List<double> presReelVals = [];
        final List<double> presSimVals = [];
        final List<double> tempReelVals = [];
        final List<double> tempSimVals = [];

        for (final point in data) {
          try {
            final x = DateTime.parse(point['date'].toString())
                .millisecondsSinceEpoch.toDouble();

            final pr = point['pressionReelle'];
            final ps = point['pressionSimulee'];
            final tr_ = point['temperatureReelle'];
            final ts = point['temperatureSimulee'];
            final db = point['debit'];

            if (pr != null) { final y = (pr as num).toDouble(); presReel.add(FlSpot(x, y)); presReelVals.add(y); }
            if (ps != null) { final y = (ps as num).toDouble(); presSimule.add(FlSpot(x, y)); presSimVals.add(y); }
            if (tr_ != null) { final y = (tr_ as num).toDouble(); tempReel.add(FlSpot(x, y)); tempReelVals.add(y); }
            if (ts != null) { final y = (ts as num).toDouble(); tempSimule.add(FlSpot(x, y)); tempSimVals.add(y); }
            if (db != null) { final y = (db as num).toDouble(); debit.add(FlSpot(x, y)); }
            final vol = point['volume'];
            if (vol != null) { final y = (vol as num).toDouble(); stock.add(FlSpot(x, y)); }
          } catch (_) {}
        }

        print('=== SIMULATION DONE === presReel:${presReel.length} presSimule:${presSimule.length} tempReel:${tempReel.length} tempSimule:${tempSimule.length} debit:${debit.length}');

        setState(() {
          _presReelSpots = presReel;
          _presSimuleSpots = presSimule;
          _tempReelSpots = tempReel;
          _tempSimuleSpots = tempSimule;
          _debitSpots = debit;
          _stockSpots = stock;
          _statsPression = StatsCalage.compute(presReelVals, presSimVals);
          _statsTemp = StatsCalage.compute(tempReelVals, tempSimVals);
          _simDateFrom = dateFrom;
          _simDateTo = dateTo;
          _isSimulating = false;
          _simulationDone = true;
        });

        // ── Étape 4 : appel fullcavity (CasingShoe + Cavern) ──
        final uriFull = Uri(
          scheme: 'http',
          host: kBaseUrl.replaceAll('http://', '').split(':')[0],
          port: 8080,
          path: '/api/simulate/fullcavity/$cavityId',
          queryParameters: {
            if (dateFrom.isNotEmpty) 'from': dateFrom,
            if (dateTo.isNotEmpty) 'to': dateTo,
          },
        );
        print('FullCavity URI: $uriFull');
        final responseFull = await http.get(uriFull).timeout(const Duration(seconds: 60));
        if (responseFull.statusCode == 200) {
          final List<dynamic> dataFull = jsonDecode(responseFull.body);
          final List<FlSpot> pCS = [], tCS = [], pCav = [], tCav = [];
          final List<FlSpot> pCSsim = [], tCSsim = [], pCavSim = [], tCavSim = [];
          for (final point in dataFull) {
            try {
              final x = DateTime.parse(point['date'].toString()).millisecondsSinceEpoch.toDouble();
              final pcs  = point['pCasingShoe'];       if (pcs  != null) pCS.add(FlSpot(x, (pcs  as num).toDouble()));
              final tcs  = point['tCasingShoe'];       if (tcs  != null) tCS.add(FlSpot(x, (tcs  as num).toDouble()));
              final pcav = point['pCavern'];            if (pcav != null) pCav.add(FlSpot(x, (pcav as num).toDouble()));
              final tcav = point['tCavern'];            if (tcav != null) tCav.add(FlSpot(x, (tcav as num).toDouble()));
              final pcss = point['pCasingShoeSimule'];  if (pcss != null) pCSsim.add(FlSpot(x, (pcss as num).toDouble()));
              final tcss = point['tCasingShoeSimule'];  if (tcss != null) tCSsim.add(FlSpot(x, (tcss as num).toDouble()));
              final pcvs = point['pCavernSimule'];      if (pcvs != null) pCavSim.add(FlSpot(x, (pcvs as num).toDouble()));
              final tcvs = point['tCavernSimule'];      if (tcvs != null) tCavSim.add(FlSpot(x, (tcvs as num).toDouble()));
            } catch (_) {}
          }
          setState(() {
            _pCasingShoeSpots    = pCS;
            _tCasingShoeSpots    = tCS;
            _pCavernSpots        = pCav;
            _tCavernSpots        = tCav;
            _pCasingShoeSimSpots = pCSsim;
            _tCasingShoeSimSpots = tCSsim;
            _pCavernSimSpots     = pCavSim;
            _tCavernSimSpots     = tCavSim;
          });
        } else {
          print('Erreur fullcavity: ${responseFull.statusCode} ${responseFull.body}');
        }
      } else {
        print('Erreur simulation: ${response.statusCode} ${response.body}');
        setState(() => _isSimulating = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur simulation: ${response.statusCode} - ${response.body}'),
            backgroundColor: kRouge,
          ));
        }
      }
    } catch (e) {
      print('=== SIMULATION ERROR: $e ===');
      setState(() => _isSimulating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur simulation: $e'),
          backgroundColor: kRouge,
        ));
      }
    }
  }

  // ─────────────────────────────────────────────
  // CALCUL GIP/WGV/CGV
  // ─────────────────────────────────────────────
  Future<void> _calculerGip() async {
    if (_cavite == null) return;
    setState(() { _isCalculatingGip = true; _gipDone = false; });
    try {
      final cavityId = _cavite!['id'];
      final uri = Uri.parse('$kBaseUrl/api/gip/$cavityId');
      final response = await http.get(uri).timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        setState(() {
          _gipResult = jsonDecode(response.body);
          _gipDone = true;
          _isCalculatingGip = false;
        });
      } else {
        setState(() => _isCalculatingGip = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur GIP: ${response.statusCode}'),
          backgroundColor: kRouge,
        ));
      }
    } catch (e) {
      setState(() => _isCalculatingGip = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur GIP: $e'),
        backgroundColor: kRouge,
      ));
    }
  }

  Widget _buildGipResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isCalculatingGip ? null : _calculerGip,
          icon: _isCalculatingGip
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.calculate, size: 18),
          label: Text(_isCalculatingGip ? tr('Calcul en cours...') : tr('Calculer GIP / WGV / CGV')),
          style: ElevatedButton.styleFrom(backgroundColor: kOrange),
        ),
        if (_gipDone && _gipResult != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBleuMoyen.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(tr('GIP / WGV / CGV')),
                const SizedBox(height: 8),
                _buildGipRow(tr('GIP permis'), _gipResult!['WGV_GIP_CGV_list0']),
                const SizedBox(height: 8),
                _buildGipTable(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGipRow(String label, dynamic value) {
    String v = '—';
    try { if (value != null) v = double.parse(value.toString()).toStringAsFixed(2); } catch (_) {}
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Text('$v Mm³', style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }

  Widget _buildGipTable() {
    if (_gipResult == null) return const SizedBox();

    // Lignes : ordre standalone
    final rows = [
      {'label': tr('Valeurs garanties'),                          'key': 'WGV_GIP_CGV_list11'},
      {'label': tr('Valeurs minimales'),                          'key': 'WGV_GIP_CGV_list12'},
      {'label': tr('Valeurs maximales'),                          'key': 'WGV_GIP_CGV_list_max'},
      {'label': tr('Pmax du permis(Qmax)'),                       'key': 'WGV_GIP_CGV_list1'},
      {'label': tr('Pmax du permis(Qmin)'),                       'key': 'WGV_GIP_CGV_list2'},
      {'label': tr('Pmin du permis(Qmax)'),                       'key': 'WGV_GIP_CGV_list3'},
      {'label': tr('Pmin du permis(Qmin)'),                       'key': 'WGV_GIP_CGV_list4'},
      {'label': tr('Pmax historique(Qmax)'),                      'key': 'WGV_GIP_CGV_list5'},
      {'label': tr('Pmax historique(Qmin)'),                      'key': 'WGV_GIP_CGV_list6'},
      {'label': tr('Pmin historique(Qmax)'),                      'key': 'WGV_GIP_CGV_list7'},
      {'label': tr('Pmin historique(Qmin)'),                      'key': 'WGV_GIP_CGV_list8'},
      {'label': tr('Dernière P histo injection (Qmax)'),          'key': 'WGV_GIP_CGV_list9'},
      {'label': tr('Dernière P histo injection (Qmin)'),          'key': 'WGV_GIP_CGV_list10'},
      {'label': tr('Dernière P histo soutirage (Qmax)'),          'key': 'WGV_GIP_CGV_list13'},
      {'label': tr('Dernière P histo soutirage (Qmin)'),          'key': 'WGV_GIP_CGV_list14'},
    ];

    // Calcul min/max sur scénarios 1-8
    double? maxWGV, minWGV, maxCGV, minCGV;
    for (int i = 1; i <= 8; i++) {
      final v = _gipResult!['WGV_GIP_CGV_list\$i'] as List<dynamic>?;
      if (v != null && v.length >= 3) {
        final w = (v[0] as num).toDouble();
        final c = (v[2] as num).toDouble();
        if (maxWGV == null || w > maxWGV) maxWGV = w;
        if (minWGV == null || w < minWGV) minWGV = w;
        if (maxCGV == null || c > maxCGV) maxCGV = c;
        if (minCGV == null || c < minCGV) minCGV = c;
      }
    }
    final vMax = maxWGV != null ? [maxWGV, (maxWGV + maxCGV!), maxCGV] : null;
    final vMin = minWGV != null ? [minWGV, (minWGV + minCGV!), minCGV] : null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(kBleuMoyen),
        dataRowMinHeight: 28, dataRowMaxHeight: 36,
        columnSpacing: 12,
        headingTextStyle: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10),
        dataTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
        columns: [
          DataColumn(label: Text(tr('Scénario'), style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10))),
          DataColumn(label: const Text('WGV'), numeric: true),
          DataColumn(label: const Text('CGV'), numeric: true),
          DataColumn(label: const Text('GIP'), numeric: true),
        ],
        rows: rows.map((row) {
          final key = row['key']!;
          List<dynamic>? vals;
          if (key == 'dummy_never') {
            vals = null;
          } else {
            vals = _gipResult![key] as List<dynamic>?;
          }
          if (vals == null || vals.length < 3) return const DataRow(cells: []);
          final isHighlight = key == 'WGV_GIP_CGV_list11' || key == 'WGV_GIP_CGV_list12' || key == '_valeursMax' || key == '_valeursMin';
          return DataRow(
            color: WidgetStateProperty.all(
              isHighlight ? kOrange.withValues(alpha: 0.15) : Colors.transparent),
            cells: [
              DataCell(Text(row['label']!, style: TextStyle(
                color: isHighlight ? kOrange : Colors.white70,
                fontSize: 9.5,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ))),
              DataCell(Text((vals[0] as num).toStringAsFixed(2),
                style: TextStyle(color: isHighlight ? Colors.red : Colors.white, fontSize: 10))),
              DataCell(Text((vals[2] as num).toStringAsFixed(2),
                style: TextStyle(color: isHighlight ? Colors.red : Colors.white, fontSize: 10))),
              DataCell(Text((vals[1] as num).toStringAsFixed(2),
                style: TextStyle(color: isHighlight ? Colors.red : Colors.white, fontSize: 10))),
            ],
          );
        }).where((r) => r.cells.isNotEmpty).toList(),
      ),
    );
  }

  Widget _gipRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(children: [
        SizedBox(width: 36, child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold))),
        Text(value, style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10)),
        const Text(' Mm³', style: TextStyle(color: Colors.white38, fontSize: 9)),
      ]),
    );
  }

  Widget _gipCell(String label, String value) {
    return Expanded(child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ]));
  }

  // ─────────────────────────────────────────────
  // GRAPHE SIMULATION (réel + simulé)
  // ─────────────────────────────────────────────
  Widget _buildSimulationChart({
    required List<FlSpot> reelSpots,
    required List<FlSpot> simuleSpots,
    required Color reelColor,
    required Color simuleColor,
    required String unite,
    double? hMin,
    double? hMax,
  }) {
    if (reelSpots.isEmpty && simuleSpots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(tr('Pas de données'), style: const TextStyle(color: Colors.white54)),
      );
    }
    final allSpots = [...reelSpots, ...simuleSpots];
    final minX = allSpots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX = allSpots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    final minY = allSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = allSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final paddingY = (maxY - minY) * 0.1 + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 12, height: 12, color: reelColor, margin: const EdgeInsets.only(right: 4)),
          Text(tr('Données réelles'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 12),
          Container(width: 12, height: 12, color: simuleColor, margin: const EdgeInsets.only(right: 4)),
          Text(tr('Données simulées'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const Spacer(),
          Text(unite, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: LineChart(LineChartData(
            minX: minX, maxX: maxX,
            minY: minY - paddingY, maxY: maxY + paddingY,
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
              getDrawingVerticalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white54, fontSize: 9)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                    return Text('${dt.year}', style: const TextStyle(color: Colors.white54, fontSize: 9));
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
            lineBarsData: [
              if (reelSpots.isNotEmpty)
                LineChartBarData(spots: reelSpots, color: reelColor, barWidth: 1.5, dotData: const FlDotData(show: false)),
              if (simuleSpots.isNotEmpty)
                LineChartBarData(spots: simuleSpots, color: simuleColor, barWidth: 1.5, dotData: const FlDotData(show: false)),
              if (hMin != null && hMin > 0 && reelSpots.isNotEmpty)
                LineChartBarData(
                    spots: [FlSpot(minX, hMin), FlSpot(maxX, hMin)],
                    color: Colors.purple, barWidth: 1.5, dashArray: [5, 5],
                    dotData: const FlDotData(show: false)),
              if (hMax != null && hMax > 0 && reelSpots.isNotEmpty)
                LineChartBarData(
                    spots: [FlSpot(minX, hMax), FlSpot(maxX, hMax)],
                    color: Colors.green, barWidth: 1.5, dashArray: [5, 5],
                    dotData: const FlDotData(show: false)),
            ],
          )),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // GRAPHE SIMPLE (une seule courbe)
  // ─────────────────────────────────────────────
  Widget _buildSimpleSimChart({
    required List<FlSpot> spots,
    required Color lineColor,
    required String unite,
    double? hMin,
    double? hMax,
    List<FlSpot>? simSpots,
    Color? simColor,
  }) {
    if (spots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(tr('Pas de données'), style: const TextStyle(color: Colors.white54)),
      );
    }
    final allSpots = [...spots, ...(simSpots ?? [])];
    final minX = allSpots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX = allSpots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    final minY = allSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = allSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final paddingY = (maxY - minY) * 0.1 + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 12, height: 12, color: lineColor, margin: const EdgeInsets.only(right: 4)),
          Text(tr('Estimated values'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          if (simSpots != null && simSpots.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(width: 12, height: 12, color: simColor ?? Colors.redAccent, margin: const EdgeInsets.only(right: 4)),
            Text(tr('Simulated values'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
          const Spacer(),
          Text(unite, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: LineChart(LineChartData(
            minX: minX, maxX: maxX,
            minY: minY - paddingY, maxY: maxY + paddingY,
            gridData: FlGridData(
              show: true,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
              getDrawingVerticalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 40,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                      style: const TextStyle(color: Colors.white54, fontSize: 9)))),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(v.toInt());
                    return Text('${dt.year}', style: const TextStyle(color: Colors.white54, fontSize: 9));
                  })),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
            lineBarsData: [
              LineChartBarData(
                spots: spots, color: lineColor, barWidth: 1.5,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: lineColor.withValues(alpha: 0.08)),
              ),
              if (simSpots != null && simSpots.isNotEmpty)
                LineChartBarData(
                  spots: simSpots, color: simColor ?? Colors.redAccent, barWidth: 1.5,
                  dotData: const FlDotData(show: false),
                  dashArray: [4, 2],
                ),
            ],
          )),
        ),
      ],
    );
  }

  Widget _buildStatsRow(StatsCalage stats) {
    return Row(children: [
      _statCell('${stats.devStd}', tr('Dév. std')),
      _statCell('${stats.devMin}', tr('Min')),
      _statCell('${stats.devMax}', tr('Max')),
      _statCell('${stats.sommeEcartsQuad}', tr('Écarts²')),
      _statCell('${stats.devMoy}', tr('Moy. dév')),
    ]);
  }

  Widget _statCell(String value, String label) {
    return Expanded(
        child: Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: kBleuMoyen, borderRadius: BorderRadius.circular(6)),
      child: Column(children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ]),
    ));
  }

  Widget _buildSimulationResults() {
    if (!_simulationDone) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: kBleuMoyen.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Période simulation
              if (_simDateFrom != null && _simDateTo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Simulation : $_simDateFrom → $_simDateTo',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              // ── Pression ──
              _buildSectionTitle(tr('Pression tête de puits')),
              const SizedBox(height: 8),
              _buildSimulationChart(
                reelSpots: _presReelSpots,
                simuleSpots: _presSimuleSpots,
                reelColor: Colors.blue,
                simuleColor: Colors.red,
                unite: 'bar',
                hMin: (_cavite?['pminTeteDePuits'] as num?)?.toDouble(),
                hMax: (_cavite?['pmaxTeteDePuits'] as num?)?.toDouble(),
              ),
              if (_statsPression != null) ...[
                const SizedBox(height: 8),
                Text(tr('Calage'), style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                _buildStatsRow(_statsPression!),
              ],
              const SizedBox(height: 16),
              // ── Température ──
              _buildSectionTitle(tr('Température tête de puits')),
              const SizedBox(height: 8),
              _buildSimulationChart(
                reelSpots: _tempReelSpots,
                simuleSpots: _tempSimuleSpots,
                reelColor: Colors.blue,
                simuleColor: Colors.red,
                unite: '°C',
              ),
              if (_statsTemp != null) ...[
                const SizedBox(height: 8),
                Text(tr('Calage'), style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                _buildStatsRow(_statsTemp!),
              ],
              const SizedBox(height: 16),
              // ── Débits ──
              _buildSectionTitle(tr('Débit journalier')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _debitSpots,
                lineColor: kJaune,
                unite: 'Mm³/j',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(tr('Volume stocké')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _stockSpots,
                lineColor: kVert,
                unite: 'Mm³',
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(tr('Pression Casing Shoe')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _pCasingShoeSpots,
                lineColor: Colors.cyan,
                unite: 'bar',
                hMin: (_cavite?['pminCasingShoe'] as num?)?.toDouble(),
                hMax: (_cavite?['pmaxCasingShoe'] as num?)?.toDouble(),
                simSpots: _pCasingShoeSimSpots,
                simColor: Colors.red,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(tr('Température Casing Shoe')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _tCasingShoeSpots,
                lineColor: Colors.cyanAccent,
                unite: '°C',
                simSpots: _tCasingShoeSimSpots,
                simColor: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(tr('Pression Caverne')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _pCavernSpots,
                lineColor: Colors.purple,
                unite: 'bar',
                hMin: (_cavite?['pminCavern'] as num?)?.toDouble(),
                hMax: (_cavite?['pmaxCavern'] as num?)?.toDouble(),
                simSpots: _pCavernSimSpots,
                simColor: Colors.red,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(tr('Température Caverne')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _tCavernSpots,
                lineColor: Colors.purpleAccent,
                unite: '°C',
                simSpots: _tCavernSimSpots,
                simColor: Colors.redAccent,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate(bool isDebut) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDebut
          ? (_dateDebut ?? now.subtract(const Duration(days: 365)))
          : (_dateFin ?? now),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: kOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) _dateDebut = picked;
        else _dateFin = picked;
      });
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return tr('Choisir');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  List<FlSpot> _buildSpotsPression() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _realData.length; i++) {
      final v = _realData[i]['pwelHead'];
      if (v != null) spots.add(FlSpot(i.toDouble(), (v as num).toDouble()));
    }
    return spots;
  }

  List<FlSpot> _buildSpotsTemperature() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _realData.length; i++) {
      final v = _realData[i]['twelHead'];
      if (v != null) spots.add(FlSpot(i.toDouble(), (v as num).toDouble()));
    }
    return spots;
  }

  List<FlSpot> _buildSpotsVolume() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _realData.length; i++) {
      final v = _realData[i]['volume'];
      if (v != null) spots.add(FlSpot(i.toDouble(), (v as num).toDouble()));
    }
    return spots;
  }

  List<FlSpot> _buildSpotsDebit() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _realData.length; i++) {
      final v = _realData[i]['debit'];
      if (v != null) spots.add(FlSpot(i.toDouble(), (v as num).toDouble()));
    }
    return spots;
  }

  String _labelX(int index) {
    if (index < 0 || index >= _realData.length) return '';
    final date = _realData[index]['date'] as String?;
    if (date == null || date.length < 7) return '';
    return date.substring(0, 7);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16,
              decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic valeur, String unite) {
    final String display = valeur != null ? '${valeur.toString()} $unite' : '—';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(flex: 3,
              child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12))),
          Expanded(flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(display,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.right),
              )),
        ],
      ),
    );
  }

  Widget _buildDateButton({required String label, required String date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
            const SizedBox(height: 2),
            Text(date, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart({
    required String title,
    required List<FlSpot> spots,
    required Color lineColor,
    required String uniteY,
  }) {
    if (spots.isEmpty) {
      return Card(
        color: kBleuMoyen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 24),
              Center(child: Text(tr('Aucune donnée disponible'),
                  style: const TextStyle(color: Colors.white38, fontSize: 12))),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final rangeY = (maxY - minY).abs();
    final paddingY = rangeY == 0 ? 1.0 : rangeY * 0.1;
    final step = (spots.length / 5).ceil().clamp(1, spots.length);

    return Card(
      color: kBleuMoyen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Row(
                children: [
                  Container(width: 12, height: 12,
                      decoration: BoxDecoration(color: lineColor, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const Spacer(),
                  Text(uniteY, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            SizedBox(
              height: 180,
              child: LineChart(LineChartData(
                backgroundColor: Colors.transparent,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: Colors.white12, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    bottom: BorderSide(color: Colors.white24, width: 1),
                    left: BorderSide(color: Colors.white24, width: 1),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 40,
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0),
                        style: const TextStyle(color: Colors.white54, fontSize: 9)),
                  )),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 28, interval: step.toDouble(),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      return Transform.rotate(
                        angle: -0.5,
                        child: Text(_labelX(idx),
                            style: const TextStyle(color: Colors.white54, fontSize: 8)),
                      );
                    },
                  )),
                ),
                minY: minY - paddingY, maxY: maxY + paddingY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots, isCurved: true, color: lineColor, barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: lineColor.withValues(alpha: 0.08)),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => kBleuFonce,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      final date = idx < _realData.length ? (_realData[idx]['date'] as String? ?? '') : '';
                      return LineTooltipItem('$date\n${s.y.toStringAsFixed(2)} $uniteY',
                          TextStyle(color: lineColor, fontSize: 11));
                    }).toList(),
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBleuFonce,
      appBar: AppBar(
        backgroundColor: kBleuMoyen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('OGRES',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(widget.siteName.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          const LanguageSelectorWidget(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () { setState(() => _isLoading = true); _loadCavites(); },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kOrange))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () { setState(() => _isLoading = true); _loadCavites(); },
                        style: ElevatedButton.styleFrom(backgroundColor: kOrange),
                        child: Text(tr('Réessayer')),
                      ),
                    ],
                  ),
                )
              : _cavites.isEmpty
                  ? Center(child: Text(tr('Aucune cavité pour ce site'),
                      style: const TextStyle(color: Colors.white54)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Dropdown cavernes ──
                          Card(
                            color: kBleuMoyen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr('Liste des cavernes'),
                                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _cavite?['nom'],
                                    dropdownColor: kBleuMoyen,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.05),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.white24),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Colors.white24),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: _cavites.map((c) {
                                      return DropdownMenuItem<String>(
                                        value: c['nom'],
                                        child: Text(c['nom'] ?? ''),
                                      );
                                    }).toList(),
                                    onChanged: (val) async {
                                      setState(() {
                                        _cavite = Map<String, dynamic>.from(
                                            _cavites.firstWhere((c) => c['nom'] == val));
                                        _realData = [];
                                        _dateDebut = null;
                                        _dateFin = null;
                                        _simulationDone = false;
                                      });
                                      await _loadRealData();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ── Dates ──
                          Card(
                            color: kBleuMoyen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tr("Période d'analyse"),
                                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: _buildDateButton(
                                          label: tr('Du'), date: _formatDate(_dateDebut),
                                          onTap: () => _pickDate(true))),
                                      const SizedBox(width: 8),
                                      Expanded(child: _buildDateButton(
                                          label: tr('Au'), date: _formatDate(_dateFin),
                                          onTap: () => _pickDate(false))),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: kOrange,
                                            minimumSize: const Size(44, 44),
                                            padding: EdgeInsets.zero),
                                        onPressed: _loadRealData,
                                        child: const Icon(Icons.check, color: Colors.white),
                                      ),
                                      const SizedBox(width: 4),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            minimumSize: const Size(44, 44),
                                            padding: EdgeInsets.zero),
                                        onPressed: () async {
                                          setState(() { _dateDebut = null; _dateFin = null; });
                                          await _loadRealData();
                                        },
                                        child: const Icon(Icons.refresh, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // ── Graphes données réelles ──
                          if (_isLoadingData)
                            const Center(child: Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(color: kOrange),
                            ))
                          else ...[
                            _buildSectionTitle(tr('Pression tête de puits') + ' (bar)'),
                            _buildChart(title: tr('Pression tête de puits'),
                                spots: _buildSpotsPression(), lineColor: kOrange, uniteY: 'bar'),
                            _buildSectionTitle(tr('Température tête de puits') + ' (°C)'),
                            _buildChart(title: tr('Température tête de puits'),
                                spots: _buildSpotsTemperature(), lineColor: kRouge, uniteY: '°C'),
                            _buildSectionTitle(tr('Volume stocké - Volume journalier')),
                            _buildChart(title: tr('Volume stocké'),
                                spots: _buildSpotsVolume(), lineColor: kVert, uniteY: 'Mm³'),
                            _buildChart(title: tr('Débit journalier'),
                                spots: _buildSpotsDebit(), lineColor: kJaune, uniteY: 'Mm³/j'),
                          ],
                          const SizedBox(height: 12),
                          // ── Caractéristiques cavité ──
                          if (_cavite != null) ...[
                            _buildSectionTitle(tr('Caractéristiques cavité')),
                            Card(
                              color: kBleuMoyen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSectionTitle(tr('Géométrie')),
                                    _buildInfoRow(tr('Profondeur casing shoe'), _cavite!['hauteur'], tr('m/sol')),
                                    _buildInfoRow(tr('Diamètre tubing'), _cavite!['diametre'], 'm'),
                                    _buildInfoRow(tr('Profondeur total caverne'), _cavite!['profondeur'], tr('m/sol')),
                                    _buildInfoRow(tr('Volume libre'), _cavite!['volume'], 'm³'),
                                    _buildSectionTitle(tr('Pressions tête de puits')),
                                    _buildInfoRow(tr('Pression min'), _cavite!['pminTeteDePuits'], 'bar'),
                                    _buildInfoRow(tr('Pression max'), _cavite!['pmaxTeteDePuits'], 'bar'),
                                    _buildSectionTitle(tr('Pressions casing shoe')),
                                    _buildInfoRow(tr('Pression min'), _cavite!['pminCasingShoe'], 'bar'),
                                    _buildInfoRow(tr('Pression max'), _cavite!['pmaxCasingShoe'], 'bar'),
                                    _buildSectionTitle(tr('Pressions caverne')),
                                    _buildInfoRow(tr('Pression min'), _cavite!['pminCavern'], 'bar'),
                                    _buildInfoRow(tr('Pression max'), _cavite!['pmaxCavern'], 'bar'),
                                    _buildSectionTitle(tr('Débits')),
                                    _buildInfoRow(tr('Soutirage max'), _cavite!['soutirageMax'], 'Mm³/j'),
                                    _buildInfoRow(tr('Soutirage min'), _cavite!['soutirageMin'], 'Mm³/j'),
                                    _buildInfoRow(tr('Injection max'), _cavite!['injectionMax'], 'Mm³/j'),
                                    _buildInfoRow(tr('Injection min'), _cavite!['injectionMin'], 'Mm³/j'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // ── Bouton simulation ──
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(tr('Lancer la simulation'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                              onPressed: _isSimulating ? null : _lancerSimulation,
                            ),
                          ),
                          if (_isSimulating)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator(color: kOrange)),
                            ),
                          _buildSimulationResults(),
                          const SizedBox(height: 24),
                          // ── Menu Caverne ──
                          _buildSectionTitle(tr('Fonctions avancées')),
                          _buildCaverneMenu(),
                          const SizedBox(height: 16),
                          // ── Menu Fonctions générales ──
                          _buildSectionTitle(tr('Fonctions générales')),
                          _buildFonctionsGeneralesMenu(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildCaverneMenu() {
    final menus = [
      {'label': tr('Données importées'), 'icon': Icons.upload_file, 'active': false},
      {'label': tr('Tableau Injection / Soutirage'), 'icon': Icons.table_chart, 'active': false},
      {'label': tr('Calages et simulations'), 'icon': Icons.tune, 'active': false},
      {'label': tr('Calcul paramètres opérationnels'), 'icon': Icons.calculate, 'active': true},
      {'label': tr('Calcul P/T puits / cavité'), 'icon': Icons.compress, 'active': false},
      {'label': tr('Intégrité cavité'), 'icon': Icons.security, 'active': false},
      {'label': tr('Calculs multi-cavités'), 'icon': Icons.account_tree, 'active': true},
      {'label': tr('Pressions fond → surface'), 'icon': Icons.arrow_upward, 'active': false},
      {'label': tr('Réconcilier données'), 'icon': Icons.sync, 'active': false},
      {'label': tr('Fluage et fuite'), 'icon': Icons.water_drop, 'active': false},
      {'label': tr('Modèle physique'), 'icon': Icons.science, 'active': false},
    ];

    return Column(
      children: menus.map((menu) {
        final isActive = menu['active'] as bool;
        final label = menu['label'] as String;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? kBleuMoyen : kBleuMoyen.withValues(alpha: 0.4),
                foregroundColor: isActive ? Colors.white : Colors.white30,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isActive ? kOrange.withValues(alpha: 0.5) : Colors.white12,
                    width: 1,
                  ),
                ),
                elevation: isActive ? 2 : 0,
              ),
              icon: Icon(menu['icon'] as IconData, size: 18),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              onPressed: isActive
                  ? () => _naviguerMenu(label)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  void _naviguerMenu(String label) {
    if (label == tr('Calcul paramètres opérationnels')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => GipPage(cavite: _cavite!, siteName: widget.siteName),
      ));
    } else if (label == tr('Calculs multi-cavités')) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => PoolSimulationPage(siteName: widget.siteName),
      ));
    }
  }

  Widget _buildFonctionsGeneralesMenu() {
    final menus = [
      {'label': tr('Composition gaz'), 'icon': Icons.bubble_chart, 'active': false},
      {'label': tr('Exporter site'), 'icon': Icons.download, 'active': true},
      {'label': tr('Contacts'), 'icon': Icons.contacts, 'active': false},
      {'label': tr('Mail'), 'icon': Icons.mail, 'active': false},
      {'label': tr('Rapport mensuel'), 'icon': Icons.summarize, 'active': false},
    ];

    return Column(
      children: menus.map((menu) {
        final isActive = menu['active'] as bool;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? kBleuMoyen : kBleuMoyen.withValues(alpha: 0.4),
                foregroundColor: isActive ? Colors.white : Colors.white30,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: isActive ? kVert.withValues(alpha: 0.5) : Colors.white12,
                    width: 1,
                  ),
                ),
                elevation: isActive ? 2 : 0,
              ),
              icon: Icon(menu['icon'] as IconData, size: 18),
              label: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  menu['label'] as String,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
              onPressed: isActive
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExportSitePage(
                            siteId: widget.siteId,
                            siteName: widget.siteName,
                          ),
                        ),
                      );
                    }
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// PAGE : CALCUL PARAMÈTRES OPÉRATIONNELS (GIP/WGV/CGV)
// ─────────────────────────────────────────────
class GipPage extends StatefulWidget {
  final Map<String, dynamic> cavite;
  final String siteName;
  const GipPage({super.key, required this.cavite, required this.siteName});
  @override
  State<GipPage> createState() => _GipPageState();
}

class _GipPageState extends State<GipPage> with LocalizedPage {
  bool _isCalculatingGip = false;
  bool _gipDone = false;
  Map<String, dynamic>? _gipResult;

  Future<void> _calculerGip() async {
    setState(() { _isCalculatingGip = true; _gipDone = false; });
    try {
      final cavityId = widget.cavite['id'];
      final uri = Uri.parse('$kBaseUrl/api/gip/$cavityId');
      final response = await http.get(uri).timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        setState(() {
          _gipResult = jsonDecode(response.body);
          _gipDone = true;
          _isCalculatingGip = false;
        });
      } else {
        setState(() => _isCalculatingGip = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur GIP: ${response.statusCode}'),
          backgroundColor: kRouge,
        ));
      }
    } catch (e) {
      setState(() => _isCalculatingGip = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur GIP: $e'),
        backgroundColor: kRouge,
      ));
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16,
              decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildGipRow(String label, dynamic value) {
    String v = '—';
    try { if (value != null) v = double.parse(value.toString()).toStringAsFixed(2); } catch (_) {}
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Text('$v Mm³', style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }

  Widget _gipCell(String label, String value) {
    return Expanded(child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ]));
  }

  Widget _buildGipTable() {
    if (_gipResult == null) return const SizedBox();

    // Lignes : ordre standalone
    final rows = [
      {'label': tr('Valeurs garanties'),                          'key': 'WGV_GIP_CGV_list11'},
      {'label': tr('Valeurs minimales'),                          'key': 'WGV_GIP_CGV_list12'},
      {'label': tr('Valeurs maximales'),                          'key': 'WGV_GIP_CGV_list_max'},
      {'label': tr('Pmax du permis(Qmax)'),                       'key': 'WGV_GIP_CGV_list1'},
      {'label': tr('Pmax du permis(Qmin)'),                       'key': 'WGV_GIP_CGV_list2'},
      {'label': tr('Pmin du permis(Qmax)'),                       'key': 'WGV_GIP_CGV_list3'},
      {'label': tr('Pmin du permis(Qmin)'),                       'key': 'WGV_GIP_CGV_list4'},
      {'label': tr('Pmax historique(Qmax)'),                      'key': 'WGV_GIP_CGV_list5'},
      {'label': tr('Pmax historique(Qmin)'),                      'key': 'WGV_GIP_CGV_list6'},
      {'label': tr('Pmin historique(Qmax)'),                      'key': 'WGV_GIP_CGV_list7'},
      {'label': tr('Pmin historique(Qmin)'),                      'key': 'WGV_GIP_CGV_list8'},
      {'label': tr('Dernière P histo injection (Qmax)'),          'key': 'WGV_GIP_CGV_list9'},
      {'label': tr('Dernière P histo injection (Qmin)'),          'key': 'WGV_GIP_CGV_list10'},
      {'label': tr('Dernière P histo soutirage (Qmax)'),          'key': 'WGV_GIP_CGV_list13'},
      {'label': tr('Dernière P histo soutirage (Qmin)'),          'key': 'WGV_GIP_CGV_list14'},
    ];

    // Calcul min/max sur scénarios 1-8
    double? maxWGV, minWGV, maxCGV, minCGV;
    for (int i = 1; i <= 8; i++) {
      final v = _gipResult!['WGV_GIP_CGV_list\$i'] as List<dynamic>?;
      if (v != null && v.length >= 3) {
        final w = (v[0] as num).toDouble();
        final c = (v[2] as num).toDouble();
        if (maxWGV == null || w > maxWGV) maxWGV = w;
        if (minWGV == null || w < minWGV) minWGV = w;
        if (maxCGV == null || c > maxCGV) maxCGV = c;
        if (minCGV == null || c < minCGV) minCGV = c;
      }
    }
    final vMax = maxWGV != null ? [maxWGV, (maxWGV + maxCGV!), maxCGV] : null;
    final vMin = minWGV != null ? [minWGV, (minWGV + minCGV!), minCGV] : null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(kBleuMoyen),
        dataRowMinHeight: 28, dataRowMaxHeight: 36,
        columnSpacing: 12,
        headingTextStyle: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10),
        dataTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
        columns: [
          DataColumn(label: Text(tr('Scénario'), style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10))),
          DataColumn(label: const Text('WGV'), numeric: true),
          DataColumn(label: const Text('CGV'), numeric: true),
          DataColumn(label: const Text('GIP'), numeric: true),
        ],
        rows: rows.map((row) {
          final key = row['key']!;
          List<dynamic>? vals;
          if (key == 'dummy_never') {
            vals = null;
          } else {
            vals = _gipResult![key] as List<dynamic>?;
          }
          if (vals == null || vals.length < 3) return const DataRow(cells: []);
          final isHighlight = key == 'WGV_GIP_CGV_list11' || key == 'WGV_GIP_CGV_list12' || key == '_valeursMax' || key == '_valeursMin';
          return DataRow(
            color: WidgetStateProperty.all(
              isHighlight ? kOrange.withValues(alpha: 0.15) : Colors.transparent),
            cells: [
              DataCell(Text(row['label']!, style: TextStyle(
                color: isHighlight ? kOrange : Colors.white70,
                fontSize: 9.5,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ))),
              DataCell(Text((vals[0] as num).toStringAsFixed(2),
                style: TextStyle(color: isHighlight ? Colors.red : Colors.white, fontSize: 10))),
              DataCell(Text((vals[2] as num).toStringAsFixed(2),
                style: TextStyle(color: isHighlight ? Colors.red : Colors.white, fontSize: 10))),
              DataCell(Text((vals[1] as num).toStringAsFixed(2),
                style: TextStyle(color: isHighlight ? Colors.red : Colors.white, fontSize: 10))),
            ],
          );
        }).where((r) => r.cells.isNotEmpty).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBleuFonce,
      appBar: AppBar(
        backgroundColor: kBleuMoyen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('OGRES',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(tr('Calcul paramètres opérationnels'),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [
          const LanguageSelectorWidget(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info caverne
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBleuMoyen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: kOrange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.siteName} — ${widget.cavite['nom'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bouton calcul
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCalculatingGip ? null : _calculerGip,
                icon: _isCalculatingGip
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.calculate, size: 18),
                label: Text(_isCalculatingGip ? tr('Calcul en cours...') : tr('Calculer GIP / WGV / CGV'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Résultats GIP
            if (_gipDone && _gipResult != null) ...[
              _buildSectionTitle(tr('GIP / WGV / CGV')),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBleuMoyen.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGipRow(tr('GIP permis'), _gipResult!['WGV_GIP_CGV_list0']),
                    const SizedBox(height: 8),
                    _buildGipTable(),
                    const SizedBox(height: 16),
                    _buildVolumesIndicatifs(),
                    const SizedBox(height: 16),
                    _buildInterruptibleWGV(),
                    const SizedBox(height: 16),
                    _buildValeursGaranties(),
                    const SizedBox(height: 16),
                    _buildValeursRealistes(),
                    const SizedBox(height: 16),
                    _buildGrapheAuPlusTot(),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }

  Widget _buildSectionTitleGip(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(
            color: kOrange, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white,
            fontWeight: FontWeight.bold, fontSize: 13)),
      ]),
    );
  }

  Widget _buildDataRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 10))),
        Text(value, style: TextStyle(
            color: valueColor ?? Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
      ]),
    );
  }

  Widget _buildVolumesIndicatifs() {
    if (_gipResult == null) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitleGip(tr('Volumes indicatifs')),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12)),
        child: Column(children: [
          _buildDataRow(tr('Pression actuelle'), '${_fmt(_gipResult!["pressionActuelle"])} bar'),
          _buildDataRow(tr('Pression moyenne permis'), '${_fmt(_gipResult!["pressionMoyennePermis"])} bar'),
          _buildDataRow(tr('Volume actuel'), '${_fmt(_gipResult!["gipDernier"])} Mm³'),
          _buildDataRow(tr('Volume moyen depuis début année gazière'), '${_fmt(_gipResult!["volumeMoyenDepuisDebut"])} Mm³'),
          _buildDataRow(tr('Volume journalier moyen'), '${_fmt(_gipResult!["volumeJournalierMoyen"])} Mm³/j'),
          _buildDataRow(tr('Dernier jour pour inj/souti'), '${_gipResult!["dernierJourInjSouti"] ?? "-"}'),
        ]),
      ),
    ]);
  }

  Widget _buildInterruptibleWGV() {
    if (_gipResult == null) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitleGip(tr('Interruptible WGV')),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12)),
        child: Column(children: [
          _buildDataRow(tr('Volume interruptible si injection'), '${_fmt(_gipResult!["interruptible_WGV_inj"])} Mm³/j'),
          _buildDataRow(tr('Volume interruptible si soutirage'), '${_fmt(_gipResult!["interruptible_WGV_with"])} Mm³/j'),
        ]),
      ),
    ]);
  }

  Widget _buildValeursGaranties() {
    if (_gipResult == null) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitleGip(tr('Valeurs garanties')),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: kOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kOrange.withValues(alpha: 0.3))),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text('', style: const TextStyle(color: Colors.white54, fontSize: 9))),
            Expanded(child: Text(tr('Avg Interr Sout MNm³'), textAlign: TextAlign.center,
                style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 9))),
            Expanded(child: Text(tr('Avg Interr Inj MNm³'), textAlign: TextAlign.center,
                style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 9))),
            Expanded(child: Text(tr('% vs volume total'), textAlign: TextAlign.center,
                style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 9))),
          ]),
          const Divider(color: Colors.white12, height: 8),
          Row(children: [
            const Expanded(child: Text('', style: TextStyle(fontSize: 9))),
            Expanded(child: Text(_fmt(_gipResult!["average_interruptible_withdrawal_guaranteed"]),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(child: Text(_fmt(_gipResult!["average_interruptible_injection_guaranteed"]),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(child: Text(_fmt(_gipResult!["vs_total_volume_withdrawal_guaranteed"]),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildValeursRealistes() {
    if (_gipResult == null) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitleGip(tr('Valeurs réalistes')),
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12)),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text('', style: const TextStyle(color: Colors.white54, fontSize: 9))),
            Expanded(child: Text(tr('Avg Interr Sout MNm³'), textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 9))),
            Expanded(child: Text(tr('Avg Interr Inj MNm³'), textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 9))),
            Expanded(child: Text(tr('% vs volume total'), textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 9))),
          ]),
          const Divider(color: Colors.white12, height: 8),
          Row(children: [
            const Expanded(child: Text('', style: TextStyle(fontSize: 9))),
            Expanded(child: Text(_fmt(_gipResult!["average_interruptible_withdrawal_realist"]),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(child: Text(_fmt(_gipResult!["average_interruptible_injection_realist"]),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            Expanded(child: Text(_fmt(_gipResult!["vs_total_volume_withdrawal_realist"]),
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ]),
        ]),
      ),
    ]);
  }

  Widget _buildGrapheAuPlusTot() {
    if (_gipResult == null) return const SizedBox();
    final injSerie  = (_gipResult!['serieInjectionAuPlusTot']  as List<dynamic>?) ?? [];
    final soutiSerie = (_gipResult!['serieSoutirageAuPlusTot'] as List<dynamic>?) ?? [];
    if (injSerie.isEmpty && soutiSerie.isEmpty) return const SizedBox();

    List<FlSpot> injSpots  = [];
    List<FlSpot> soutiSpots = [];
    for (int i = 0; i < injSerie.length; i++) {
      final pt = injSerie[i] as List<dynamic>;
      if (pt.length >= 2) injSpots.add(FlSpot(i.toDouble(), (pt[1] as num).toDouble()));
    }
    for (int i = 0; i < soutiSerie.length; i++) {
      final pt = soutiSerie[i] as List<dynamic>;
      if (pt.length >= 2) soutiSpots.add(FlSpot(i.toDouble(), (pt[1] as num).toDouble()));
    }

    final all = [...injSpots, ...soutiSpots];
    if (all.isEmpty) return const SizedBox();
    final minY = all.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = all.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final pad  = (maxY - minY) * 0.1 + 1;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitleGip(tr('Injection / Soutirage au plus tôt')),
      Row(children: [
        Container(width: 10, height: 10, color: Colors.blueAccent, margin: const EdgeInsets.only(right: 4)),
        const Text('Injection', style: TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(width: 10),
        Container(width: 10, height: 10, color: Colors.redAccent, margin: const EdgeInsets.only(right: 4)),
        const Text('Soutirage', style: TextStyle(color: Colors.white70, fontSize: 10)),
        const Spacer(),
        const Text('bar', style: TextStyle(color: Colors.white54, fontSize: 10)),
      ]),
      const SizedBox(height: 6),
      SizedBox(height: 180, child: LineChart(LineChartData(
        minY: minY - pad, maxY: maxY + pad,
        gridData: FlGridData(show: true,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white54, fontSize: 8)))),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
        lineBarsData: [
          if (injSpots.isNotEmpty) LineChartBarData(spots: injSpots,
              color: Colors.blueAccent, barWidth: 1.5, dotData: const FlDotData(show: false)),
          if (soutiSpots.isNotEmpty) LineChartBarData(spots: soutiSpots,
              color: Colors.redAccent, barWidth: 1.5, dotData: const FlDotData(show: false)),
        ],
      ))),
    ]);
  }
}
// ─────────────────────────────────────────────
// PAGE : EXPORT SITE
// ─────────────────────────────────────────────
class ExportSitePage extends StatefulWidget {
  final int siteId;
  final String siteName;
  const ExportSitePage({super.key, required this.siteId, required this.siteName});
  @override
  State<ExportSitePage> createState() => _ExportSitePageState();
}

class _ExportSitePageState extends State<ExportSitePage> with LocalizedPage {
  bool _isExporting = false;
  bool _exportDone = false;
  String? _exportFileName;
  String? _errorMessage;

  Future<void> _exportSite() async {
    // Popup saisie mot de passe
    final pwdController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBleuMoyen,
        title: Text(tr('Mot de passe export'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pwdController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: tr('Mot de passe'),
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: kOrange)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('Annuler'), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('Confirmer'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || pwdController.text.isEmpty) return;
    final password = pwdController.text;

    setState(() { _isExporting = true; _exportDone = false; _errorMessage = null; });
    try {
      final uri = Uri.parse('$kBaseUrl/api/sites/${widget.siteId}/export?password=${Uri.encodeComponent(password)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        // Récupérer le nom du fichier depuis le header
        final disposition = response.headers['content-disposition'] ?? '';
        String fileName = 'export_${widget.siteName}.zip';
        final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
        if (match != null) fileName = match.group(1)!;

        setState(() {
          _exportDone = true;
          _exportFileName = fileName;
          _isExporting = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur serveur : ${response.statusCode}';
          _isExporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur : $e';
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBleuFonce,
      appBar: AppBar(
        backgroundColor: kBleuMoyen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('OGRES',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(tr('Exporter site'),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        actions: [const LanguageSelectorWidget()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info site
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kBleuMoyen, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: kOrange, size: 18),
                  const SizedBox(width: 8),
                  Text(widget.siteName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBleuMoyen.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: kOrange, size: 18),
                  const SizedBox(height: 8),
                  Text(tr('L\'export génère un fichier ZIP contenant :'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 6),
                  _infoLine('site.json — Informations du site'),
                  _infoLine('cavernes.json — Toutes les cavernes'),
                  _infoLine('realdata_{caverne}.json — Données réelles'),
                  _infoLine('calages_{caverne}.json — Calages NARMA'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Bouton export
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportSite,
                icon: _isExporting
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download, size: 18),
                label: Text(_isExporting
                    ? tr('Export en cours...')
                    : tr('Générer et télécharger le ZIP'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kVert,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            // Résultat
            if (_exportDone) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kVert.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kVert.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: kVert, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('Export généré avec succès !'),
                              style: const TextStyle(color: kVert, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(_exportFileName ?? '',
                              style: const TextStyle(color: Colors.white54, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(tr('Fichier disponible dans export/ sur le serveur'),
                              style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kRouge.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kRouge.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: kRouge, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(color: kRouge, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: kOrange, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAGE : CALCULS MULTI-CAVITÉS (POOL)
// ─────────────────────────────────────────────
class PoolSimulationPage extends StatefulWidget {
  final String siteName;
  const PoolSimulationPage({super.key, required this.siteName});
  @override
  State<PoolSimulationPage> createState() => _PoolSimulationPageState();
}

class _PoolSimulationPageState extends State<PoolSimulationPage> with LocalizedPage {
  // Étape courante : 0=sélection, 1=simulation, 2=résultats
  int _step = 0;

  // Étape 0 — liste des cavernes disponibles
  List<Map<String, dynamic>> _cavernes = [];
  Set<String> _selected = {};
  bool _loadingCavernes = false;
  String? _errorCavernes;
  bool _poolPrecedentDisponible = false;
  String _listePrecedente = '';

  // Étape 1 — simulation en cours
  bool _simulating = false;
  Map<String, dynamic>? _simResult;
  List<FlSpot> _seriePresReel = [];
  List<FlSpot> _seriePresSim = [];
  List<FlSpot> _serieTempReel = [];
  List<FlSpot> _serieTempSim = [];
  List<FlSpot> _serieVolume = [];
  List<FlSpot> _serieDebit = [];

  // Étape 2 — résultats GIP/WGV/CGV pool
  bool _loadingGip = false;
  Map<String, dynamic>? _gipResult;
  List<Map<String, dynamic>> _gipResultsPool = [];

  // Ratchet — calcul débits maximaux
  bool _loadingRatchet = false;
  Map<String, dynamic>? _ratchetResult1;
  Map<String, dynamic>? _ratchetResult2;
  Map<String, dynamic>? _ratchetResult3;
  bool _showRatchet = false;
  List<Map<String, dynamic>> _details = [];

  @override
  void initState() {
    super.initState();
    _chargerCavernes();
  }

  // ── Étape 0 : charger la liste des cavernes ──
  Future<void> _chargerCavernes() async {
    setState(() { _loadingCavernes = true; _errorCavernes = null; });
    try {
      final uri = Uri(
        scheme: 'http',
        host: kBaseUrl.replaceAll('http://', '').split(':')[0],
        port: 8080,
        path: '/api/getListCavity',
      );
      print('getListCavity URI: $uri');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'SiteName': widget.siteName}),
      ).timeout(const Duration(seconds: 30));
      print('getListCavity status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Vérifier si un pool précédent existe
        final poolEntry = data
            .where((c) => (c['CavityName'] as String).startsWith('Pool'))
            .toList();
        String listePrecedente = '';
        if (poolEntry.isNotEmpty && poolEntry[0]['listCavityPool'] != null) {
          listePrecedente = poolEntry[0]['listCavityPool'] as String;
        }
        setState(() {
          _cavernes = data
              .map((c) => Map<String, dynamic>.from(c as Map))
              .where((c) => !(c['CavityName'] as String).startsWith('Pool'))
              .toList();
          _loadingCavernes = false;
          _poolPrecedentDisponible = listePrecedente.isNotEmpty;
          _listePrecedente = listePrecedente;
        });
      } else {
        setState(() { _loadingCavernes = false; _errorCavernes = 'Erreur ${response.statusCode}'; });
      }
    } catch (e) {
      setState(() { _loadingCavernes = false; _errorCavernes = e.toString(); });
    }
  }

  // ── Étape 1 : lancer la simulation pool ──
  Future<void> _lancerSimulation() async {
    if (_selected.isEmpty) return;
    setState(() { _simulating = true; _simResult = null; });
    try {
      // 1. Enregistrer la sélection
      final uriSelect = Uri(
        scheme: 'http',
        host: kBaseUrl.replaceAll('http://', '').split(':')[0],
        port: 8080,
        path: '/api/selectCavitePoolSimulation',
      );
      await http.post(uriSelect,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'SiteName': widget.siteName, 'ListeCavites': _selected.join(',')}),
      ).timeout(const Duration(seconds: 30));

      // 2. Calculer P/T/V moyens
      final uri2 = Uri(
        scheme: 'http',
        host: kBaseUrl.replaceAll('http://', '').split(':')[0],
        port: 8080,
        path: '/api/insertRealPresTempVolDebitPool',
      );
      final response = await http.post(
        uri2,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'SiteName': widget.siteName,
          'ListeCavites': _selected.join(','),
        }),
      ).timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final List<dynamic> parsed = jsonDecode(response.body);
        setState(() {
          _simResult = Map<String, dynamic>.from(parsed[0] as Map);
          _seriePresReel = _toSpots(parsed[1] as List);
          _seriePresSim  = _toSpots(parsed[2] as List);
          _serieTempReel = _toSpots(parsed[3] as List);
          _serieTempSim  = _toSpots(parsed[4] as List);
          _serieVolume   = _toSpots(parsed[5] as List);
          _serieDebit    = _toSpots(parsed[6] as List);
          _simulating = false;
          _step = 1;
        });
        await _chargerDetails();
      } else {
        setState(() { _simulating = false; });
        if (mounted) _showError('Erreur simulation: ${response.statusCode}');
      }
    } catch (e) {
      setState(() { _simulating = false; });
      if (mounted) _showError('Erreur: $e');
    }
  }

  // ── Étape 2 : charger les détails de chaque caverne ──
  Future<void> _chargerDetails() async {
    try {
      final uri3 = Uri(
        scheme: 'http',
        host: kBaseUrl.replaceAll('http://', '').split(':')[0],
        port: 8080,
        path: '/api/getDetailCavityPool',
      );
      final response = await http.post(
        uri3,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'SiteName': widget.siteName}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _details = data.map((d) => Map<String, dynamic>.from(d as Map)).toList();
        });
      }
    } catch (_) {}
  }

  // ── Étape 2 : calculer GIP/WGV/CGV pool ──
  Future<void> _calculerGipPool() async {
    setState(() { _loadingGip = true; _gipResult = null; });
    try {
      final uri4 = Uri(
        scheme: 'http',
        host: kBaseUrl.replaceAll('http://', '').split(':')[0],
        port: 8080,
        path: '/api/getMenu_Pool',
      );
      final response = await http.post(
        uri4,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'SiteName': widget.siteName,
          'ListeCavites': _selected.join(','),
          'dateValueDernierPtHistoPlusieursCavite': '',
          'presMoyennePermis': '0',
        }),
      ).timeout(const Duration(seconds: 120));
      if (response.statusCode == 200) {
        final List<dynamic> parsed = jsonDecode(response.body);
        setState(() {
          _gipResult = parsed.isNotEmpty ? Map<String, dynamic>.from(parsed[0] as Map) : {};
          _gipResultsPool = parsed.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loadingGip = false;
          _step = 2;
        });
      } else {
        setState(() => _loadingGip = false);
        if (mounted) _showError('Erreur GIP pool: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadingGip = false);
      if (mounted) _showError('Erreur: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: kRouge),
    );
  }

  // ── Widgets ──

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(children: [
        Container(width: 4, height: 16,
            decoration: BoxDecoration(color: kOrange, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ]),
    );
  }

  Widget _buildStepIndicator() {
    final steps = [tr('Sélection'), tr('Simulation'), tr('Résultats')];
    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = i < _step;
        final isCurrent = i == _step;
        return Expanded(
          child: Row(children: [
            if (i > 0) Expanded(child: Container(height: 2,
                color: isDone ? kOrange : Colors.white12)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? kOrange : (isCurrent ? kBleuMoyen : Colors.white12),
                  border: Border.all(color: isCurrent ? kOrange : Colors.transparent, width: 2),
                ),
                child: Center(child: isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text('\${i+1}', style: TextStyle(
                        color: isCurrent ? kOrange : Colors.white38, fontSize: 11, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 4),
              Text(steps[i], style: TextStyle(
                  color: isCurrent ? kOrange : (isDone ? Colors.white70 : Colors.white30),
                  fontSize: 10)),
            ]),
            if (i < steps.length - 1) Expanded(child: Container(height: 2,
                color: isDone ? kOrange : Colors.white12)),
          ]),
        );
      }),
    );
  }

  // Étape 0 — sélection des cavernes
  Widget _buildSelectionStep() {
    if (_loadingCavernes) {
      return const Center(child: CircularProgressIndicator(color: kOrange));
    }
    if (_errorCavernes != null) {
      return Column(children: [
        Text(_errorCavernes!, style: const TextStyle(color: kRouge)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _chargerCavernes,
          icon: const Icon(Icons.refresh, size: 16),
          label: Text(tr('Réessayer')),
          style: ElevatedButton.styleFrom(backgroundColor: kBleuMoyen, foregroundColor: Colors.white),
        ),
      ]);
    }
    if (_cavernes.isEmpty) {
      return Text(tr('Aucune caverne disponible'),
          style: const TextStyle(color: Colors.white54));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr('Sélectionnez les cavernes à mettre en pool :'),
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 12),
        ..._cavernes.map((c) {
          final name = c['CavityName'] as String;
          final isChecked = _selected.contains(name);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isChecked ? kOrange.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isChecked ? kOrange.withValues(alpha: 0.5) : Colors.white12),
            ),
            child: CheckboxListTile(
              value: isChecked,
              onChanged: (v) => setState(() {
                v! ? _selected.add(name) : _selected.remove(name);
              }),
              title: Text(name, style: const TextStyle(color: Colors.white, fontSize: 13)),

              activeColor: kOrange,
              checkColor: Colors.white,
              dense: true,
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selected.isEmpty || _simulating ? null : _lancerSimulation,
            icon: _simulating
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.play_arrow, size: 18),
            label: Text(_simulating ? tr('Calcul en cours...') : tr('Lancer la simulation pool'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kOrange.withValues(alpha: 0.3),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_poolPrecedentDisponible) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _simulating ? null : _lancerSimPrecedente,
              icon: const Icon(Icons.history, size: 18),
              label: Text(tr('Simulation précédente') + ' ($_listePrecedente)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: kOrange,
                side: BorderSide(color: kOrange.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Lance la simulation avec la sélection précédente (depuis la DB)
  Future<void> _lancerSimPrecedente() async {
    if (_listePrecedente.isEmpty) return;
    setState(() {
      _selected = Set<String>.from(_listePrecedente.split(',').map((s) => s.trim()));
    });
    await _lancerSimulation();
  }

  // Graphe simplifié pour le pool (axe X = index)
  Widget _buildPoolChart({
    required List<FlSpot> reelSpots,
    required List<FlSpot> simSpots,
    required Color reelColor,
    required Color simColor,
    required String unite,
  }) {
    final all = [...reelSpots, ...simSpots];
    if (all.isEmpty) return Text(tr('Pas de données'), style: const TextStyle(color: Colors.white54));
    final minY = all.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = all.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final padY = (maxY - minY) * 0.1 + 1;
    final minX = all.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX = all.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 10, height: 10, color: reelColor, margin: const EdgeInsets.only(right: 4)),
        Text(tr('Réel'), style: const TextStyle(color: Colors.white70, fontSize: 10)),
        if (simSpots.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(width: 10, height: 10, color: simColor, margin: const EdgeInsets.only(right: 4)),
          Text(tr('Simulé'), style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
        const Spacer(),
        Text(unite, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ]),
      const SizedBox(height: 6),
      SizedBox(height: 180, child: LineChart(LineChartData(
        minX: minX, maxX: maxX,
        minY: minY - padY, maxY: maxY + padY,
        gridData: FlGridData(show: true,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
          getDrawingVerticalLine: (_) => FlLine(color: Colors.white12, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40,
            getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1), style: const TextStyle(color: Colors.white54, fontSize: 8)))),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
        lineBarsData: [
          if (reelSpots.isNotEmpty)
            LineChartBarData(spots: reelSpots, color: reelColor, barWidth: 1.5, dotData: const FlDotData(show: false)),
          if (simSpots.isNotEmpty)
            LineChartBarData(spots: simSpots, color: simColor, barWidth: 1.5, dotData: const FlDotData(show: false)),
        ],
      ))),
    ]);
  }

  // Convertit une série JSON [{x:"y,m,d", y:val}] en List<FlSpot>
  List<FlSpot> _toSpots(List<dynamic> serie) {
    final List<FlSpot> spots = [];
    for (int i = 0; i < serie.length; i++) {
      final pt = serie[i] as Map;
      final y = pt['y'];
      if (y != null && y != 'null') {
        spots.add(FlSpot(i.toDouble(), (y as num).toDouble()));
      }
    }
    return spots;
  }

  // Étape 1 — résultats simulation + détails cavernes
  Widget _buildSimulationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cavernes sélectionnées
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: kBleuMoyen, borderRadius: BorderRadius.circular(10)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('Cavernes en pool'), style: const TextStyle(
                  color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: _selected.map((name) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kOrange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kOrange.withValues(alpha: 0.5)),
                  ),
                  child: Text(name, style: const TextStyle(color: kOrange, fontSize: 12)),
                )).toList(),
              ),
            ],
          ),
        ),
        // Détails cavernes
        if (_details.isNotEmpty) ...[ 
          _buildSectionTitle(tr('Détails par caverne')),
          ..._details.map((d) => _buildDetailCard(d)),
        ],
        // Graphes P/T/V
        if (_seriePresReel.isNotEmpty || _seriePresSim.isNotEmpty) ...[
          _buildSectionTitle(tr('Pression moyenne tête de puits')),
          _buildPoolChart(
            reelSpots: _seriePresReel,
            simSpots: _seriePresSim,
            reelColor: kOrange,
            simColor: Colors.blueAccent,
            unite: 'bar',
          ),
        ],
        if (_serieTempReel.isNotEmpty || _serieTempSim.isNotEmpty) ...[
          _buildSectionTitle(tr('Température moyenne tête de puits')),
          _buildPoolChart(
            reelSpots: _serieTempReel,
            simSpots: _serieTempSim,
            reelColor: kOrange,
            simColor: Colors.greenAccent,
            unite: '°C',
          ),
        ],
        if (_serieVolume.isNotEmpty) ...[
          _buildSectionTitle(tr('Volume stocké total')),
          _buildPoolChart(
            reelSpots: _serieVolume,
            simSpots: const [],
            reelColor: kVert,
            simColor: kVert,
            unite: 'Mm³',
          ),
        ],
        if (_serieDebit.isNotEmpty) ...[
          _buildSectionTitle(tr('Débit total')),
          _buildPoolChart(
            reelSpots: _serieDebit,
            simSpots: const [],
            reelColor: kJaune,
            simColor: kJaune,
            unite: 'Mm³/j',
          ),
        ],
        const SizedBox(height: 16),
        // Bouton calcul GIP pool
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadingGip ? null : _calculerGipPool,
            icon: _loadingGip
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.calculate, size: 18),
            label: Text(_loadingGip ? tr('Calcul en cours...') : tr('Calcul des paramètres opérationnels'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadingRatchet ? null : _calculerRatchet,
            icon: _loadingRatchet
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.speed, size: 18),
            label: Text(_loadingRatchet ? tr('Calcul en cours...') : tr('Calcul des débits maximaux'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_showRatchet) ...[
          const SizedBox(height: 16),
          if (_ratchetResult1 != null) _buildRatchetTable('Ratchet 1 — Théorique', _ratchetResult1!),
          if (_ratchetResult2 != null) ...[const SizedBox(height: 12), _buildRatchetTable('Ratchet 2 — Historique', _ratchetResult2!)],
          if (_ratchetResult3 != null) ...[const SizedBox(height: 12), _buildRatchetTable('Ratchet 3 — Combiné', _ratchetResult3!)],
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() { _step = 0; _selected.clear(); }),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(tr('Modifier la sélection')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(Map<String, dynamic> d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(d['CavityName'] ?? '—',
              style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            _detailCell(tr('Soutirage max'), '${d["soutirageMax"] ?? "-"}'),
            _detailCell(tr('Soutirage min'), '${d["soutirageMin"] ?? "-"}'),
            _detailCell(tr('Injection max'), '${d["injectionMax"] ?? "-"}'),
            _detailCell(tr('Injection min'), '${d["injectionMin"] ?? "-"}'),
          ]),
        ],
      ),
    );
  }

  Widget _detailCell(String label, String value) {
    return Expanded(child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ]));
  }

  // Calcul des débits maximaux (Ratchet)
  Future<void> _calculerRatchet() async {
    setState(() { _loadingRatchet = true; _ratchetResult1 = null; _ratchetResult2 = null; _ratchetResult3 = null; _showRatchet = false; });
    try {
      final host = kBaseUrl.replaceAll('http://','').split(':')[0];

      // Ratchet 1
      final resp1 = await http.post(
        Uri(scheme:'http', host:host, port:8080, path:'/api/getTableauRatchet_Pool'),
        headers:{'Content-Type':'application/json'},
        body:jsonEncode({'SiteName':widget.siteName}),
      ).timeout(const Duration(seconds:120));

      // Ratchet 2
      final resp2 = await http.post(
        Uri(scheme:'http', host:host, port:8080, path:'/api/getTableauRatchet2_Pool'),
        headers:{'Content-Type':'application/json'},
        body:jsonEncode({'SiteName':widget.siteName}),
      ).timeout(const Duration(seconds:120));

      // Ratchet 3
      final response = await http.post(
        Uri(scheme:'http', host:host, port:8080, path:'/api/getTableauRatchet3_Pool'),
        headers:{'Content-Type':'application/json'},
        body:jsonEncode({'SiteName':widget.siteName}),
      ).timeout(const Duration(seconds:120));

      if (response.statusCode == 200) {
        setState(() {
          _ratchetResult3 = jsonDecode(response.body) as Map<String, dynamic>;
          _ratchetResult1 = resp1.statusCode == 200 ? jsonDecode(resp1.body) as Map<String, dynamic> : null;
          _ratchetResult2 = resp2.statusCode == 200 ? jsonDecode(resp2.body) as Map<String, dynamic> : null;
          _loadingRatchet = false;
          _showRatchet = true;
        });
      } else {
        setState(() => _loadingRatchet = false);
        if (mounted) _showError('Erreur Ratchet: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _loadingRatchet = false);
      if (mounted) _showError('Erreur: $e');
    }
  }

  Widget _buildRatchetTable(String titre, Map<String, dynamic> data) {
    final pressList = (data['pressionAllPermitSansDoublonList'] as List<dynamic>?) ?? [];
    final volMm3    = (data['volumeMm3'] as List<dynamic>?) ?? [];
    final injMm3    = (data['injectionMm3ByD'] as List<dynamic>?) ?? [];
    final soutiMm3  = (data['soutirageMm3ByD'] as List<dynamic>?) ?? [];
    final filling   = (data['fillingLevelDeChaquePressionPermis'] as List<dynamic>?)
                   ?? (data['fillingLevelTotalList'] as List<dynamic>?) ?? [];
    final nbActif   = (data['nbCaviteActive'] as List<dynamic>?) ?? [];
    final injKW     = (data['injectionKW'] as List<dynamic>?) ?? [];
    final soutiKW   = (data['soutirageKW'] as List<dynamic>?) ?? [];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionTitle(titre),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(kBleuMoyen),
          dataRowColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? kOrange.withValues(alpha:0.1) : Colors.white.withValues(alpha:0.05)),
          columnSpacing: 16,
          headingTextStyle: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 9.5),
          columns: [
            DataColumn(label: Text('P (bar)')),
            DataColumn(label: Text('Filling %')),
            DataColumn(label: Text('Nb cav')),
            DataColumn(label: Text('Vol Mm3')),
            DataColumn(label: Text('Inj Mm3/j')),
            DataColumn(label: Text('Souti Mm3/j')),
            DataColumn(label: Text('Vol kWh')),
            DataColumn(label: Text('Inj kW')),
            DataColumn(label: Text('Souti kW')),
          ],
          rows: List.generate(pressList.length, (i) {
            return DataRow(cells: [
              DataCell(Text(_fmt(pressList[i]))),
              DataCell(Text(i < filling.length ? _fmt(filling[i]) : '-')),
              DataCell(Text(i < nbActif.length ? _fmt(nbActif[i]) : '-')),
              DataCell(Text(i < volMm3.length  ? _fmt(volMm3[i]) : '-')),
              DataCell(Text(i < injMm3.length  ? _fmt(injMm3[i]) : '-')),
              DataCell(Text(i < soutiMm3.length ? _fmt(soutiMm3[i]) : '-')),
              DataCell(Text(i < injKW.length    ? _fmt(injKW[i]) : '-')),
              DataCell(Text(i < soutiKW.length  ? _fmt(soutiKW[i]) : '-')),
              DataCell(Text(i < soutiKW.length  ? _fmt(soutiKW[i]) : '-')),
            ]);
          }),
        ),
      ),
    ]);
  }

  // Étape 2 — résultats GIP/WGV/CGV pool
  Widget _buildResultatsStep() {
    if (_gipResultsPool.isEmpty) {
      return Text(tr('Aucun résultat disponible'),
          style: const TextStyle(color: Colors.white54));
    }
    // Agrégat pool : sommer l1-l8 par caverne, puis calculer garanties/min/max sur les agrégés
    double totalGIPPermis = 0;
    for (final res in _gipResultsPool) {
      totalGIPPermis += (res['WGV_GIP_CGV_list0'] as num? ?? 0).toDouble();
    }
    // Scénarios agrégés l1-l8 (somme sur les 4 cavernes)
    final scenKeys = ['WGV_GIP_CGV_list1','WGV_GIP_CGV_list2','WGV_GIP_CGV_list3','WGV_GIP_CGV_list4',
                      'WGV_GIP_CGV_list5','WGV_GIP_CGV_list6','WGV_GIP_CGV_list7','WGV_GIP_CGV_list8'];
    final agreg = <List<double>>[];
    for (final key in scenKeys) {
      double w = 0, g = 0, c = 0;
      for (final res in _gipResultsPool) {
        final v = res[key] as List<dynamic>?;
        if (v != null && v.length >= 3) {
          w += (v[0] as num).toDouble();
          g += (v[1] as num).toDouble();
          c += (v[2] as num).toDouble();
        }
      }
      agreg.add([w, g, c]);
    }
    // Valeurs garanties : WGV=min(WGV), CGV=max(CGV) des 8 scénarios agrégés
    final minWGV = agreg.isEmpty ? 0.0 : agreg.map((l) => l[0]).reduce((a,b) => a<b?a:b);
    final maxCGV = agreg.isEmpty ? 0.0 : agreg.map((l) => l[2]).reduce((a,b) => a>b?a:b);
    final totalWGV = minWGV, totalCGV = maxCGV, totalGIP = minWGV + maxCGV;
    // Valeurs maximales : WGV=max(WGV), CGV=max(CGV)
    final maxWGV = agreg.isEmpty ? 0.0 : agreg.map((l) => l[0]).reduce((a,b) => a>b?a:b);
    // Valeurs minimales : WGV=min(WGV), CGV=min(CGV)
    final minCGV = agreg.isEmpty ? 0.0 : agreg.map((l) => l[2]).reduce((a,b) => a<b?a:b);
    final labels = [
      tr('Pmax permis / Débit souti max'), tr('Pmax permis / Débit souti min'),
      tr('Pmin permis / Débit souti max'), tr('Pmin permis / Débit souti min'),
      tr('Pmax histo / Débit souti max'), tr('Pmax histo / Débit souti min'),
      tr('Pmin histo / Débit souti max'), tr('Pmin histo / Débit souti min'),
      tr('Dernier pt → Pmin / Débit souti max'), tr('Dernier pt → Pmin / Débit souti min'),
      tr('MAX scénarios 1-8'), tr('MIN scénarios 1-8'),
      tr('Dernier pt → Pmax / Débit souti max'), tr('Dernier pt → Pmax / Débit souti min'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GIP permis
        // ── Résultat agrégé pool ──
        _buildSectionTitle(tr('GIP / WGV / CGV Pool — Agrégé')),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kOrange.withValues(alpha: 0.4)),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.star, color: kOrange, size: 16),
              const SizedBox(width: 8),
              Text(tr('GIP permis total'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              Text('${totalGIPPermis.toStringAsFixed(2)} Mm³',
                  style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _gipCell('WGV total', totalWGV.toStringAsFixed(2)),
              const SizedBox(width: 8),
              _gipCell('GIP total', totalGIP.toStringAsFixed(2)),
              const SizedBox(width: 8),
              _gipCell('CGV total', totalCGV.toStringAsFixed(2)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),
        // ── Détail par caverne ──
        _buildSectionTitle(tr('Détail par caverne')),
        ..._gipResultsPool.map((res) {
          final cavName = res['CavityName'] ?? '';
          // Calculer garanties par caverne : min WGV et max CGV des scénarios l1-l8
          final cavKeys = ['WGV_GIP_CGV_list1','WGV_GIP_CGV_list2','WGV_GIP_CGV_list3','WGV_GIP_CGV_list4',
                           'WGV_GIP_CGV_list5','WGV_GIP_CGV_list6','WGV_GIP_CGV_list7','WGV_GIP_CGV_list8'];
          double cavMinWGV = double.maxFinite, cavMaxCGV = 0;
          for (final k in cavKeys) {
            final v = res[k] as List<dynamic>?;
            if (v != null && v.length >= 3) {
              final w = (v[0] as num).toDouble();
              final c = (v[2] as num).toDouble();
              if (w < cavMinWGV) cavMinWGV = w;
              if (c > cavMaxCGV) cavMaxCGV = c;
            }
          }
          if (cavMinWGV == double.maxFinite) cavMinWGV = 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kBleuMoyen.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_tree, color: kOrange, size: 14),
                const SizedBox(width: 6),
                Text(cavName, style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Text('GIP: ${_fmt(res["WGV_GIP_CGV_list0"])} Mm³',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _gipCell('WGV', cavMinWGV.toStringAsFixed(2)),
                const SizedBox(width: 8),
                _gipCell('GIP', (cavMinWGV + cavMaxCGV).toStringAsFixed(2)),
                const SizedBox(width: 8),
                _gipCell('CGV', cavMaxCGV.toStringAsFixed(2)),
              ]),
            ]),
          );
        }).toList(),
        const SizedBox(height: 8),
        // ── Tableau agrégé 14 scénarios (somme des 4 cavités) ──
        _buildSectionTitle(tr('Scénarios détaillés — Pool agrégé')),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(kBleuMoyen),
            dataRowMinHeight: 28, dataRowMaxHeight: 36,
            columnSpacing: 12,
            headingTextStyle: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10),
            dataTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
            columns: [
              DataColumn(label: Text(tr('Scénario'), style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 10))),
              DataColumn(label: const Text('WGV'), numeric: true),
              DataColumn(label: const Text('CGV'), numeric: true),
              DataColumn(label: const Text('GIP'), numeric: true),
            ],
            rows: () {
              // Clés des scénarios dans l'ordre standalone
              final rows = <DataRow>[];
              // Lignes garanties/min/max calculées côté Flutter sur les agrégés
              final fixedRows = [
                [tr('Valeurs garanties'), totalWGV, totalGIP, totalCGV],
                [tr('Valeurs minimales'), minWGV,   minWGV + minCGV, minCGV],
                [tr('Valeurs maximales'), maxWGV,   maxWGV + maxCGV, maxCGV],
              ];
              for (final r in fixedRows) {
                rows.add(DataRow(
                  color: WidgetStateProperty.all(kOrange.withValues(alpha: 0.15)),
                  cells: [
                    DataCell(Text(r[0] as String, style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 9.5))),
                    DataCell(Text((r[1] as double).toStringAsFixed(2), style: const TextStyle(color: Colors.red, fontSize: 10))),
                    DataCell(Text((r[3] as double).toStringAsFixed(2), style: const TextStyle(color: Colors.red, fontSize: 10))),
                    DataCell(Text((r[2] as double).toStringAsFixed(2), style: const TextStyle(color: Colors.red, fontSize: 10))),
                  ],
                ));
              }
              // Lignes scénarios : somme sur les 4 cavernes
              final scenKeys2 = [
                'WGV_GIP_CGV_list1','WGV_GIP_CGV_list2',
                'WGV_GIP_CGV_list3','WGV_GIP_CGV_list4',
                'WGV_GIP_CGV_list5','WGV_GIP_CGV_list6',
                'WGV_GIP_CGV_list7','WGV_GIP_CGV_list8',
                'WGV_GIP_CGV_list9','WGV_GIP_CGV_list10',
                'WGV_GIP_CGV_list13','WGV_GIP_CGV_list14',
              ];
              final scenLabels2 = [
                tr('Pmax permis(Qmax)'), tr('Pmax permis(Qmin)'),
                tr('Pmin permis(Qmax)'), tr('Pmin permis(Qmin)'),
                tr('Pmax histo(Qmax)'), tr('Pmax histo(Qmin)'),
                tr('Pmin histo(Qmax)'), tr('Pmin histo(Qmin)'),
                tr('Dernière P inj(Qmax)'), tr('Dernière P inj(Qmin)'),
                tr('Dernière P souti(Qmax)'), tr('Dernière P souti(Qmin)'),
              ];
              for (int i = 0; i < scenKeys2.length; i++) {
                double totWGV = 0, totGIP = 0, totCGV = 0;
                bool hasData = false;
                for (final res in _gipResultsPool) {
                  final v = res[scenKeys2[i]] as List<dynamic>?;
                  if (v != null && v.length >= 3) {
                    totWGV += (v[0] as num).toDouble();
                    totGIP += (v[1] as num).toDouble();
                    totCGV += (v[2] as num).toDouble();
                    hasData = true;
                  }
                }
                if (!hasData) continue;
                rows.add(DataRow(
                  color: WidgetStateProperty.all(Colors.transparent),
                  cells: [
                    DataCell(Text(scenLabels2[i], style: const TextStyle(color: Colors.white70, fontSize: 9.5))),
                    DataCell(Text(totWGV.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 10))),
                    DataCell(Text(totCGV.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 10))),
                    DataCell(Text(totGIP.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontSize: 10))),
                  ],
                ));
              }
              return rows;
            }(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() { _step = 0; _selected.clear(); _simResult = null; _gipResult = null; _gipResultsPool = []; _ratchetResult1 = null; _ratchetResult2 = null; _ratchetResult3 = null; _showRatchet = false; _details.clear(); _seriePresReel = []; _seriePresSim = []; _serieTempReel = []; _serieTempSim = []; _serieVolume = []; _serieDebit = []; }),
            icon: const Icon(Icons.refresh, size: 16),
            label: Text(tr('Nouvelle simulation')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white54,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(dynamic v) {
    try { return double.parse(v.toString()).toStringAsFixed(2); } catch (_) { return '-'; }
  }

  Widget _gipCell(String label, String value) {
    return Expanded(child: Column(children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBleuFonce,
      appBar: AppBar(
        backgroundColor: kBleuMoyen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('OGRES',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(tr('Calculs multi-cavités'),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis)),
        ]),
        actions: [const LanguageSelectorWidget()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête site
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: kBleuMoyen, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                const Icon(Icons.location_on, color: kOrange, size: 18),
                const SizedBox(width: 8),
                Text(widget.siteName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 16),
            // Indicateur d'étapes
            _buildStepIndicator(),
            const SizedBox(height: 24),
            // Contenu selon étape
            if (_step == 0) _buildSelectionStep(),
            if (_step == 1) _buildSimulationStep(),
            if (_step == 2) _buildResultatsStep(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}