import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import 'package:hive/hive.dart';

import '../../../core/storage/box_names.dart';
import '../models/product_family.dart';
import '../models/technical_product.dart';
import '../models/validation_status.dart';

class TechnicalProductService extends ChangeNotifier {
  Box<TechnicalProduct> get _box => Hive.box<TechnicalProduct>(BoxNames.technicalProducts);

  List<TechnicalProduct> get products => _box.values.toList().reversed.toList();

  /// Register all adapters for Hive
  static void registerAdapters() {
    Hive.registerAdapter(ProductFamilyAdapter());
    Hive.registerAdapter(ValidationStatusAdapter());
    Hive.registerAdapter(ConfidenceLevelAdapter());
  }

  Future<void> importFromPowerPoint({
    required String sourceName,
    required Uint8List bytes,
    String? validatorName,
  }) async {
    final product = _parsePowerPoint(sourceName: sourceName, bytes: bytes);
    
    // Set validator if provided
    if (validatorName != null && validatorName.isNotEmpty) {
      product.validatorName = validatorName;
    }
    
    await _box.put(product.id, product);
    notifyListeners();
  }

  Future<void> updateProduct(TechnicalProduct product) async {
    // Update last modified timestamp
    product.lastModified = DateTime.now();
    
    // If product was auto-extracted and is being modified, update status
    if (product.validationStatus == ValidationStatus.autoExtracted && 
        product.validatorName != null && 
        product.validatorName!.isNotEmpty) {
      product.validationStatus = ValidationStatus.manuallyModified;
    }
    
    await _box.put(product.id, product);
    notifyListeners();
  }

  Future<void> validateProduct(String productId, String validatorName, ValidationStatus status) async {
    final product = _box.get(productId);
    if (product == null) return;
    
    product.validationStatus = status;
    product.validatorName = validatorName;
    product.lastModified = DateTime.now();
    
    await _box.put(productId, product);
    notifyListeners();
  }

  Future<void> markForReview(String productId, String? reviewerName) async {
    final product = _box.get(productId);
    if (product == null) return;
    
    product.validationStatus = ValidationStatus.toReview;
    product.validatorName = reviewerName;
    product.lastModified = DateTime.now();
    
    await _box.put(productId, product);
    notifyListeners();
  }

  Future<void> setNotes(String productId, String notes) async {
    final product = _box.get(productId);
    if (product == null) return;
    
    product.notes = notes;
    product.lastModified = DateTime.now();
    
    await _box.put(productId, product);
    notifyListeners();
  }

  Future<void> deleteProduct(String productId) async {
    await _box.delete(productId);
    notifyListeners();
  }

  /// Get products that need review
  List<TechnicalProduct> get productsToReview {
    return products.where((p) => p.validationStatus == ValidationStatus.toReview).toList();
  }

  /// Get validated products
  List<TechnicalProduct> get validatedProducts {
    return products.where((p) => p.validationStatus == ValidationStatus.validated).toList();
  }

  /// Get auto-extracted products
  List<TechnicalProduct> get autoExtractedProducts {
    return products.where((p) => p.validationStatus == ValidationStatus.autoExtracted).toList();
  }

  /// Get manually modified products
  List<TechnicalProduct> get manuallyModifiedProducts {
    return products.where((p) => p.validationStatus == ValidationStatus.manuallyModified).toList();
  }

  /// Get products by confidence level
  List<TechnicalProduct> getProductsByConfidence(ConfidenceLevel level) {
    return products.where((p) => p.confidenceLevel == level).toList();
  }

  /// Get products by family
  List<TechnicalProduct> getProductsByFamily(ProductFamily family) {
    return products.where((p) => p.productFamily == family).toList();
  }

  List<TechnicalProduct> search(String query) {
    return searchAdvanced(query: query);
  }

  List<TechnicalProduct> searchAdvanced({
    String query = '',
    ProductFamily? family,
    String? tag,
    String? application,
    String? standard,
    ValidationStatus? status,
    ConfidenceLevel? confidenceLevel,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    return products.where((product) {
      final matchesFamily = family == null || product.productFamily == family;
      final matchesTag = tag == null ||
          tag.isEmpty ||
          product.tags.any((entry) => entry.toLowerCase() == tag.toLowerCase());
      final matchesApplication = application == null ||
          application.isEmpty ||
          product.applications.any(
            (entry) => entry.toLowerCase().contains(application.toLowerCase()),
          );
      final matchesStandard = standard == null ||
          standard.isEmpty ||
          product.standards.any(
            (entry) => entry.toLowerCase().contains(standard.toLowerCase()),
          );
      final matchesStatus = status == null || product.validationStatus == status;
      final matchesConfidence = confidenceLevel == null || product.confidenceLevel == confidenceLevel;

      if (!matchesFamily || !matchesTag || !matchesApplication || !matchesStandard || 
          !matchesStatus || !matchesConfidence) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final haystack = [
        product.name,
        product.sourceFileName,
        product.productFamily.displayName,
        product.summary,
        product.technicalSummary,
        product.extractedText,
        ...product.keyFacts,
        ...product.tags,
        ...product.characteristics,
        ...product.applications,
        ...product.standards,
        product.notes ?? '',
        product.validatorName ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  TechnicalProduct _parsePowerPoint({
    required String sourceName,
    required Uint8List bytes,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final slideTexts = <String>[];

    for (final file in archive.files) {
      final type = file.name.toLowerCase();
      if (!type.startsWith('ppt/slides/slide') || !type.endsWith('.xml')) {
        continue;
      }

      final xml = utf8.decode(file.content as List<int>);
      final paragraphEntries = _extractSlideTextEntries(xml);

      if (paragraphEntries.isNotEmpty) {
        slideTexts.addAll(paragraphEntries);
      }
    }

    final combinedText = slideTexts.join('\n\n');
    final title = _inferTitle(sourceName, combinedText);
    final family = _inferProductFamily(title, combinedText);
    final manufacturer = _inferManufacturer(title, combinedText);
    final models = _inferModels(combinedText);
    final applications = _inferApplications(combinedText, title);
    final standards = _inferStandards(combinedText);
    final metrics = _inferMetrics(combinedText);
    final facts = _inferFacts(
      combinedText,
      applications: applications,
      metrics: metrics,
      standards: standards,
    );
    final characteristics = _inferCharacteristics(combinedText);
    final tags = _inferTags(title, combinedText, family);
    
    // Add manufacturer and models to tags if found
    if (manufacturer != null) {
      tags.add(manufacturer);
    }
    if (models.isNotEmpty) {
      tags.addAll(models);
    }
    
    final technicalSummary = _buildTechnicalSummary(
      title: title,
      family: family,
      characteristics: characteristics,
      keyFacts: facts,
      combinedText: combinedText,
      metrics: metrics,
      applications: applications,
    );

    // Calculate extraction score and confidence level
    final extractionScore = calculateExtractionScore(
      title: title,
      family: family,
      applications: applications,
      standards: standards,
      metrics: metrics,
      facts: facts,
      characteristics: characteristics,
      tags: tags,
      combinedText: combinedText,
    );
    
    final confidenceLevel = ConfidenceLevel.fromScore(extractionScore);

    return TechnicalProduct(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: title,
      sourceFileName: sourceName,
      family: family,
      summary: technicalSummary.isNotEmpty ? technicalSummary : 'Fiche technique importée',
      keyFacts: facts.isEmpty ? characteristics : facts,
      extractedText: combinedText,
      tags: tags,
      characteristics: characteristics,
      applications: applications,
      standards: standards,
      metrics: metrics,
      technicalSummary: technicalSummary,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      confidenceLevel: confidenceLevel,
      validationStatus: ValidationStatus.autoExtracted,
      extractionScore: extractionScore,
    );
  }

  int calculateExtractionScore({
    required String title,
    required ProductFamily family,
    required List<String> applications,
    required List<String> standards,
    required Map<String, String> metrics,
    required List<String> facts,
    required List<String> characteristics,
    required List<String> tags,
    required String combinedText,
  }) {
    var score = 0;
    
    // Score for having a meaningful title
    if (title.isNotEmpty && title != 'Produit technique' && title.length > 3) {
      score += 10;
    }
    
    // Score for family detection
    if (family != ProductFamily.unknown) {
      score += 15;
    }
    
    // Score for applications
    score += applications.length * 5;
    
    // Score for standards
    score += standards.length * 3;
    
    // Score for metrics
    score += metrics.length * 8;
    
    // Score for key facts
    score += facts.length * 4;
    
    // Score for characteristics
    score += characteristics.length * 3;
    
    // Score for tags
    score += tags.length * 2;
    
    // Bonus for having multiple types of information
    final infoTypes = [
      if (applications.isNotEmpty) 1,
      if (standards.isNotEmpty) 1,
      if (metrics.isNotEmpty) 1,
      if (facts.isNotEmpty) 1,
      if (characteristics.isNotEmpty) 1,
      if (tags.isNotEmpty) 1,
    ].length;
    
    score += infoTypes * 5;
    
    // Cap at 100
    return score.clamp(0, 100);
  }

  static String _inferTitle(String sourceName, String combinedText) {
    final fileName = sourceName.split(RegExp(r'[\\/]')).last;
    final baseName = fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
    final lines = combinedText
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isNotEmpty) {
      final first = lines.first;
      if (first.length <= 90 && first.isNotEmpty) {
        return first;
      }
    }

    return baseName.isNotEmpty ? baseName : 'Produit technique';
  }

  static ProductFamily _inferProductFamily(String title, String combinedText) {
    final haystack = '$title $combinedText';
    return ProductFamily.inferFromText(haystack);
  }

  static List<String> _inferFacts(
    String combinedText, {
    List<String> applications = const [],
    Map<String, String> metrics = const {},
    List<String> standards = const [],
  }) {
    final entries = <String>[];
    final seen = <String>{};

    final labelEntries = combinedText
        .split(RegExp(r'\n+'))
        .map((line) => _sanitizeSlideText(line))
        .where((line) => line.isNotEmpty)
        .where((line) => line.contains(':') || line.contains('-'))
        .where((line) => line.length <= 120)
        .toList();

    for (final entry in labelEntries) {
      if (!seen.contains(entry)) {
        seen.add(entry);
        entries.add(entry);
      }
    }

    for (final application in applications) {
      final value = 'Application : $application';
      if (!seen.contains(value)) {
        seen.add(value);
        entries.add(value);
      }
    }

    for (final entry in metrics.entries) {
      final value = '${_titleCase(entry.key)} : ${entry.value}';
      if (!seen.contains(value)) {
        seen.add(value);
        entries.add(value);
      }
    }

    for (final standard in standards) {
      final value = 'Norme : $standard';
      if (!seen.contains(value)) {
        seen.add(value);
        entries.add(value);
      }
    }

    final sentences = RegExp(r'[^.!?\n]+[.!?]')
        .allMatches(combinedText)
        .map((match) => _sanitizeSlideText(match.group(0)!))
        .where((sentence) => sentence.isNotEmpty)
        .toList();

    for (final sentence in sentences) {
      if (!seen.contains(sentence)) {
        seen.add(sentence);
        entries.add(sentence);
      }
    }

    final scored = entries.map((entry) {
      final score = _scoreTechnicalFact(entry);
      return MapEntry(entry, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    return scored
        .map((entry) => entry.key)
        .where((entry) => _scoreTechnicalFact(entry) > 0)
        .take(8)
        .toList();
  }

  static List<String> _inferCharacteristics(String combinedText) {
    final characteristics = <String>[];
    
    // Performance metrics
    final performancePatterns = [
      RegExp(r'\b(?:débit|flow|capacité|portata)\b[\s\w:]*(\d+(?:[.,]\d+)?\s*(?:m3/h|m³/h|L/s|gpm|us\s*gpm))', caseSensitive: false),
      RegExp(r'\b(?:haute pression|basse pression)\b', caseSensitive: false),
      RegExp(r'\b(?:pression|pressure|pression\s+max|pression\s+nominale|pression\s+manométrique|HMT)\b[\s\w:]*(\d+(?:[.,]\d+)?\s*(?:bar|psi|kPa|Pa|mbar|atm))', caseSensitive: false),
      RegExp(r'\b(?:température|temperature|temp)\b[\s\w:]*(\d+(?:[.,]\d+)?\s*°?[CF]|\d+(?:[.,]\d+)?\s*(?:celsius|fahrenheit|K))', caseSensitive: false),
      RegExp(r'\b(?:puissance|power|potenza|potencia)\b[\s\w:]*(\d+(?:[.,]\d+)?\s*(?:kW|W|HP|CV|ch|PS))', caseSensitive: false),
      RegExp(r'\b(?:rendement|efficiency|efficacité|ie[1-4])\b[\s\w:]*(\d+(?:[.,]\d+)?\s*%|IE[1-4])', caseSensitive: false),
      RegExp(r'\b(?:tension|voltage|alimentation|tensione)\b[\s\w:]*(\d+(?:[.,]\d+)?\s*V(?:AC|DC)?)', caseSensitive: false),
      RegExp(r'\b(?:courant|current|intensité|corrente|amp)\b[\s\w:]*(\d+(?:[.,]\d+)?\s*A(?:C)?)', caseSensitive: false),
      RegExp(r'\b(?:vitesse|speed|rpm|t/min|tr/min|tr\.min\-1|min\-1)\b[\s\w:]*(\d+(?:[.,]\d+)?\s*(?:rpm|t/min|tr/min|min\-1))', caseSensitive: false),
    ];
    
    // Connectivity and protocols
    final connectivityPatterns = [
      RegExp(r'\bmodbus\b', caseSensitive: false),
      RegExp(r'\bbacnet\b', caseSensitive: false),
      RegExp(r'\blonworks\b', caseSensitive: false),
      RegExp(r'\bprofibus\b', caseSensitive: false),
      RegExp(r'\bprofinet\b', caseSensitive: false),
      RegExp(r'\bethernet\b', caseSensitive: false),
      RegExp(r'\b4-20ma\b', caseSensitive: false),
      RegExp(r'\b0-10v\b', caseSensitive: false),
      RegExp(r'\bbluetooth\b', caseSensitive: false),
      RegExp(r'\bwifi\b', caseSensitive: false),
      RegExp(r'\bio-link\b', caseSensitive: false),
      RegExp(r'\bgateway\b', caseSensitive: false),
    ];
    
    // Material and construction
    final materialPatterns = [
      RegExp(r'\binox\b', caseSensitive: false),
      RegExp(r'\bacier\s+(?:inox|inoxydable)', caseSensitive: false),
      RegExp(r'\bacier\s+carbone', caseSensitive: false),
      RegExp(r'\bfonte\b', caseSensitive: false),
      RegExp(r'\bcuivre\b', caseSensitive: false),
      RegExp(r'\blaiton\b', caseSensitive: false),
      RegExp(r'\bplastique\b', caseSensitive: false),
      RegExp(r'\bpp\b', caseSensitive: false),
      RegExp(r'\bpvc\b', caseSensitive: false),
      RegExp(r'\bpehd\b', caseSensitive: false),
    ];
    
    // Extract performance characteristics
    for (final pattern in performancePatterns) {
      final match = pattern.firstMatch(combinedText);
      if (match != null) {
        final value = match.group(0)!;
        if (!characteristics.contains(value)) {
          characteristics.add(value.trim());
        }
      }
    }
    
    // Extract connectivity characteristics
    for (final pattern in connectivityPatterns) {
      if (pattern.hasMatch(combinedText)) {
        final match = pattern.firstMatch(combinedText)!;
        final value = match.group(0)!;
        if (!characteristics.any((c) => c.toLowerCase().contains(value.toLowerCase()))) {
          characteristics.add(value);
        }
      }
    }
    
    // Extract material characteristics
    for (final pattern in materialPatterns) {
      if (pattern.hasMatch(combinedText)) {
        final match = pattern.firstMatch(combinedText)!;
        final value = match.group(0)!;
        if (!characteristics.any((c) => c.toLowerCase().contains(value.toLowerCase()))) {
          characteristics.add(value);
        }
      }
    }
    
    // Special patterns for technical features
    final specialFeatures = [
      'IE4', 'IE3', 'IE2', 'IE1',
      'IP55', 'IP54', 'IP65', 'IP66', 'IP67', 'IP68',
      'ATM', '50Hz', '60Hz',
      'triphasé', 'monophasé',
      'variable speed', 'VFD', 'variateur',
      'soft start', 'démarrage direct',
      'couplage', 'accouplement',
    ];
    
    for (final feature in specialFeatures) {
      if (RegExp(feature, caseSensitive: false).hasMatch(combinedText)) {
        if (!characteristics.any((c) => c.toLowerCase().contains(feature.toLowerCase()))) {
          characteristics.add(feature);
        }
      }
    }
    
    // Filter out empty or duplicate characteristics
    characteristics.removeWhere((char) => char.isEmpty || char == ' ');
    
    // Deduplicate while preserving order
    final seen = <String>{};
    final uniqueCharacteristics = <String>[];
    for (final char in characteristics) {
      final lowerChar = char.toLowerCase();
      if (!seen.contains(lowerChar)) {
        seen.add(lowerChar);
        uniqueCharacteristics.add(char);
      }
    }
    
    return uniqueCharacteristics.take(15).toList();
  }

  static List<String> _inferTags(String title, String combinedText, ProductFamily family) {
    final haystack = '$title $combinedText'.toLowerCase();
    final keywords = [
      'pompe',
      'centrifuge',
      'moteur',
      'débit',
      'pression',
      'traitement',
      'filtration',
      'énergie',
      'capteur',
      'contrôle',
      'sécurité',
      'mesure',
      'arrosage',
      'irrigation',
      'circulation',
      'relevage',
      'station',
      'désinfection',
    ];

    final tags = keywords
        .where((keyword) => haystack.contains(keyword))
        .map((keyword) => keyword)
        .toList();

    // Add family display name as tag
    if (!tags.contains(family.displayName.toLowerCase())) {
      tags.add(family.displayName.toLowerCase());
    }

    if (tags.isEmpty) {
      return [family.displayName.toLowerCase()];
    }

    return tags.take(8).toList();
  }

  static List<String> _inferApplications(String combinedText, String title) {
    final haystack = '$title $combinedText'.toLowerCase();
    final applications = <String>[];
    final patterns = <String, RegExp>{
      'Irrigation': RegExp(r"\b(irrigation|arrosage|irrigation d'eau|sprinkler)\b", caseSensitive: false),
      'Traitement': RegExp(r'\b(traitement|station|filtration|désinfection|épuration)\b', caseSensitive: false),
      'Pompage': RegExp(r'\b(pompage|pompe|relevage|transfert|circulation|refoulement)\b', caseSensitive: false),
      'Mesure': RegExp(r'\b(mesure|contrôle|instrumentation|capteur|débitmètre)\b', caseSensitive: false),
      'Sécurité': RegExp(r'\b(sécurité|alarme|protection|précaution)\b', caseSensitive: false),
      'Énergie': RegExp(r'\b(énergie|consommation|alimentation|moteur)\b', caseSensitive: false),
    };

    for (final entry in patterns.entries) {
      if (entry.value.hasMatch(haystack) && !applications.contains(entry.key)) {
        applications.add(entry.key);
      }
    }

    return applications;
  }

  static List<String> _inferStandards(String combinedText) {
    final matches = <String>{};
    final patterns = [
      RegExp(r'ISO\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'EN\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'DIN\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'NF\s*[A-Za-z]\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'NF\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'API\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'CE\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'UL\s*\d+[A-Za-z0-9.-]*', caseSensitive: false),
      RegExp(r'AFNOR', caseSensitive: false),
      RegExp(r'ANSI', caseSensitive: false),
      RegExp(r'ASM[EI]', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(combinedText)) {
        final value = match.group(0)!.trim();
        if (value.isNotEmpty && !matches.contains(value)) {
          matches.add(value);
        }
      }
    }

    return matches.toList();
  }

  static Map<String, String> _inferMetrics(String combinedText) {
    final map = <String, String>{};
    final patterns = <String, RegExp>{
      'débit': RegExp(r'(?:débit|flow|capacité|capacity|portata)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:m3/h|m3/s|l/s|l/min|L/s|m³/h|m³/s|gpm|us\s*gpm)', caseSensitive: false),
      'pression': RegExp(r'(?:pression|pressure|pression\s+max|pression\s+nominale|pression\s+manométrique|HMT)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:bar|kPa|Pa|mbar|psi|atm)', caseSensitive: false),
      'puissance': RegExp(r'(?:puissance|power|potenza|potencia)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:kW|W|HP|CV|ch|PS)', caseSensitive: false),
      'vitesse': RegExp(r'(?:vitesse|speed|velocità|velocidad|rpm|t/min|tr/min|tr\.min\-1|min\-1)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:rpm|t/min|tr/min|min\-1)', caseSensitive: false),
      'tension': RegExp(r'(?:tension|voltage|tensione|alimentation)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:V|kV|MV)', caseSensitive: false),
      'courant': RegExp(r'(?:courant|current|corrente|intensité|amp)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:A|mA)', caseSensitive: false),
      'température': RegExp(r'(?:température|temperature|temperatura|temp)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:°C|°F|K|Celsius|Fahrenheit)', caseSensitive: false),
      'hauteur manométrique': RegExp(r'(?:hauteur\s+manométrique|HMT|head|altezza\s+manometrica|manometric\s+head)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:m|meters|mètres)', caseSensitive: false),
      'diamètre': RegExp(r'(?:diamètre|diameter|diametro)\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*(?:mm|cm|m|inch|pouce)', caseSensitive: false),
      'rendement': RegExp(r'(?:rendement|efficiency|efficacité|ie[1-4])\s*[:=]?\s*[\d]+(?:[.,][\d]+)?\s*%|IE[1-4]', caseSensitive: false),
    };

    for (final entry in patterns.entries) {
      final match = entry.value.firstMatch(combinedText);
      if (match != null) {
        map[entry.key] = match.group(0)!.trim();
      }
    }

    // Connectivity extraction
    final connectivityKeywords = ['modbus', 'bacnet', 'lonworks', 'profibus', 'profinet', 'ethernet', '4-20ma', '0-10v', 'fieldbus'];
    for (final keyword in connectivityKeywords) {
      final pattern = RegExp(r'\b' + keyword + r'\b', caseSensitive: false);
      if (pattern.hasMatch(combinedText)) {
        map['connectivité'] = keyword;
        break;
      }
    }
    
    return map;
  }

  static String _buildTechnicalSummary({
    required String title,
    required ProductFamily family,
    required List<String> characteristics,
    required List<String> keyFacts,
    required String combinedText,
    Map<String, String>? metrics,
    List<String>? applications,
  }) {
    final parts = <String>[];
    
    parts.add(title);
    parts.add(family.displayName);
    
    // Add applications
    if (applications != null && applications.isNotEmpty) {
      parts.add('Applications: ${applications.join(", ")}');
    }
    
    // Add metrics
    if (metrics != null && metrics.isNotEmpty) {
      final metricText = metrics.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      parts.add(metricText);
    }
    
    // Add key facts
    if (keyFacts.isNotEmpty) {
      parts.add(keyFacts.take(2).join(' • '));
    } else if (characteristics.isNotEmpty) {
      parts.add(characteristics.take(2).join(' • '));
    }

    return parts.join(' - ');
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static List<String> _extractSlideTextEntries(String xml) {
    final entries = <String>[];
    final seen = <String>{};

    for (final match in RegExp(r'<a:t[^>]*>(.*?)</a:t>', caseSensitive: false).allMatches(xml)) {
      final value = _decodeXmlText(match.group(1) ?? '');
      final clean = _sanitizeSlideText(value);
      if (clean.isEmpty || seen.contains(clean)) {
        continue;
      }
      seen.add(clean);
      entries.add(clean);
    }

    return entries;
  }

  static int _scoreTechnicalFact(String text) {
    final lower = text.toLowerCase();
    var score = 0;

    final keywords = [
      'débit',
      'pressure',
      'pression',
      'puissance',
      'moteur',
      'application',
      'irrigation',
      'norme',
      'iso',
      'en ',
      'din',
      'vitesse',
      'capacité',
      'capacity',
      'fréquence',
      'tension',
      'courant',
      'pompe',
      'traitement',
      'filtration',
      'température',
      'diamètre',
      'hauteur',
    ];

    for (final keyword in keywords) {
      if (lower.contains(keyword)) {
        score += 3;
      }
    }

    if (RegExp(r'\d').hasMatch(text)) {
      score += 2;
    }

    if (RegExp(r'[\d][.,][\d]').hasMatch(text)) {
      score += 2;
    }

    if (text.length > 200 || text.contains('<') || text.contains('>') || text.contains('&')) {
      return -999;
    }

    return score;
  }

  static String _sanitizeSlideText(String text) {
    final normalized = text
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\u00A0'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .trim();

    if (normalized.isEmpty) {
      return '';
    }

    final lower = normalized.toLowerCase();
    final xmlNoise = [
      'quick menu',
      'microsoft',
      'office drawing',
      'xmlns',
      'xlink',
      'http://schemas',
      'a:fld',
      'a:ext',
      'xml',
      'id=',
      'mergeformat',
      'r:id',
      '/a:t',
      'office:',
      'powerpoint',
      'slide layout',
      'content placeholder',
      'title placeholder',
    ];

    if (xmlNoise.any(lower.contains)) {
      return '';
    }

    if (normalized.length > 180) {
      return '';
    }

    return normalized;
  }

  static String _decodeXmlText(String raw) {
    return raw
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Migrate old products with string family to new ProductFamily enum
  Future<int> migrateLegacyProducts() async {
    var migratedCount = 0;
    final allProducts = _box.values.toList();
    
    for (final product in allProducts) {
      // This will be handled by the adapter automatically
      // But we can force a save to ensure migration
      await _box.put(product.id, product);
      migratedCount++;
    }
    
    return migratedCount;
  }

  /// Detect common manufacturers from text
  String? _inferManufacturer(String title, String combinedText) {
    final manufacturers = [
      'Grundfos', 'Sulzer', 'KSB', 'Wilo', 'Xylem',
      'Pentair', 'Ebara', 'Caprari', 'ABB', 'Siemens',
      'Schneider', 'Danfoss'
    ];
    final lowerText = '$title $combinedText'.toLowerCase();
    for (final manufacturer in manufacturers) {
      if (lowerText.contains(manufacturer.toLowerCase())) {
        return manufacturer;
      }
    }
    return null;
  }

  /// Extract product models/series from text (e.g., CR, MTR, MTS, etc.)
  List<String> _inferModels(String combinedText) {
    final modelPatterns = [
      'CR', 'MTR', 'MTS', 'BMS', 'SEG', 'TP', 'NB', 'NK', 'SP', 'SE/SL',
      'CUE', 'MGE', 'PULSE', 'SYSPro', 'OpenPump', 'Lightyear',
    ];
    
    final foundModels = <String>[];
    final lowerText = combinedText.toLowerCase();
    
    for (final pattern in modelPatterns) {
      if (lowerText.contains(pattern.toLowerCase())) {
        foundModels.add(pattern);
      }
    }
    
    return foundModels;
  }
}
