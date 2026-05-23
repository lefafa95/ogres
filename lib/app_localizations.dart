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
          for (final point in dataFull) {
            try {
              final x = DateTime.parse(point['date'].toString()).millisecondsSinceEpoch.toDouble();
              final pcs  = point['pCasingShoe']; if (pcs  != null) pCS.add(FlSpot(x, (pcs  as num).toDouble()));
              final tcs  = point['tCasingShoe']; if (tcs  != null) tCS.add(FlSpot(x, (tcs  as num).toDouble()));
              final pcav = point['pCavern'];      if (pcav != null) pCav.add(FlSpot(x, (pcav as num).toDouble()));
              final tcav = point['tCavern'];      if (tcav != null) tCav.add(FlSpot(x, (tcav as num).toDouble()));
            } catch (_) {}
          }
          setState(() {
            _pCasingShoeSpots = pCS;
            _tCasingShoeSpots = tCS;
            _pCavernSpots     = pCav;
            _tCavernSpots     = tCav;
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
    if (_cavite == null) {
      print('=== GIP: _cavite est null ===');
      return;
    }
    final cavityId = _cavite!['id'];
    print('=== GIP START cavityId=$cavityId ===');
    setState(() { _isCalculatingGip = true; _gipDone = false; });
    try {
      final uri = Uri.parse('$kBaseUrl/api/gip/$cavityId');
      print('=== GIP URI: $uri ===');
      final response = await http.get(uri).timeout(const Duration(seconds: 120));
      print('=== GIP STATUS: ${response.statusCode} length: ${response.body.length} ===');
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
      print('=== GIP ERROR: $e ===');
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
    final v = value != null ? double.parse(value.toString()).toStringAsFixed(2) : '—';
      return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
      Text('$v Mm³', style: const TextStyle(color: kOrange, fontWeight: FontWeight.bold, fontSize: 12)),
    ]);
  }

  Widget _buildGipTable() {
    final labels = [
      tr('Pmax permis / Débit souti max'),
      tr('Pmax permis / Débit souti min'),
      tr('Pmin permis / Débit souti max'),
      tr('Pmin permis / Débit souti min'),
      tr('Pmax histo / Débit souti max'),
      tr('Pmax histo / Débit souti min'),
      tr('Pmin histo / Débit souti max'),
      tr('Pmin histo / Débit souti min'),
      tr('Dernier pt → Pmin / Débit souti max'),
      tr('Dernier pt → Pmin / Débit souti min'),
      tr('MAX scénarios 1-8'),
      tr('MIN scénarios 1-8'),
      tr('Dernier pt → Pmax / Débit souti max'),
      tr('Dernier pt → Pmax / Débit souti min'),
    ];
    return Column(
      children: List.generate(14, (i) {
        final key = 'WGV_GIP_CGV_list${i + 1}';
        final vals = _gipResult![key] as List<dynamic>?;
        if (vals == null || vals.length < 3) return const SizedBox();
        final wgv = (vals[0] as num).toStringAsFixed(2);
        final gip = (vals[1] as num).toStringAsFixed(2);
        final cgv = (vals[2] as num).toStringAsFixed(2);
        final isHighlight = i == 10 || i == 11;
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isHighlight ? kOrange.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(labels[i], style: TextStyle(
                color: isHighlight ? kOrange : Colors.white54,
                fontSize: 10,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              )),
              const SizedBox(height: 2),
              Row(children: [
                _gipCell('WGV', wgv),
                const SizedBox(width: 8),
                _gipCell('GIP', gip),
                const SizedBox(width: 8),
                _gipCell('CGV', cgv),
              ]),
            ],
          ),
        );
      }),
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
  }) {
    if (spots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(tr('Pas de données'), style: const TextStyle(color: Colors.white54)),
      );
    }
    final minX = spots.map((s) => s.x).reduce((a, b) => a < b ? a : b);
    final maxX = spots.map((s) => s.x).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final paddingY = (maxY - minY) * 0.1 + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 12, height: 12, color: lineColor, margin: const EdgeInsets.only(right: 4)),
          Text(tr('Données réelles'), style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(tr('Température Casing Shoe')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _tCasingShoeSpots,
                lineColor: Colors.cyanAccent,
                unite: '°C',
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
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(tr('Température Caverne')),
              const SizedBox(height: 8),
              _buildSimpleSimChart(
                spots: _tCavernSpots,
                lineColor: Colors.purpleAccent,
                unite: '°C',
              ),
              _buildGipResults(),
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
                        ],
                      ),
                    ),
    );
  }
}