/// Migration utilities for Technical Products module
/// This file provides functions to help migrate from old data format to new format
library;

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'models/product_family.dart';
import '../../../core/storage/box_names.dart';
import 'models/technical_product.dart';
import 'models/validation_status.dart';
import 'services/technical_product_service.dart';

class TechnicalProductsMigration {
  /// Migrate old string-based product family to ProductFamily enum
  /// This is called automatically during box initialization
  static Future<void> migrateLegacyData() async {
    try {
      // Check if migration is needed
      final box = Hive.box<TechnicalProduct>(BoxNames.technicalProducts);
      
      if (box.isEmpty) {
        // No data to migrate
        return;
      }

      final needsMigration = box.values.any((product) {
        // If any product has a string family, we need to migrate
        try {
          return product.productFamily is String;
        } catch (_) {
          return true;
        }
      });

      if (!needsMigration) {
        // All products already use ProductFamily enum
        return;
      }

      // Perform migration
      final migrationStart = DateTime.now();
      var migratedCount = 0;
      var errorCount = 0;

      for (final product in box.values) {
        try {
          // This will be handled automatically by the adapter
          // but we force a save to ensure data is properly migrated
          await box.put(product.id, product);
          migratedCount++;
        } catch (e) {
          errorCount++;
        }
      }

      final duration = DateTime.now().difference(migrationStart);
      
      // Log migration result
      debugPrint('[TechnicalProductsMigration] Migration completed in ${duration.inMilliseconds}ms');
      debugPrint('[TechnicalProductsMigration] $migratedCount products migrated');
      if (errorCount > 0) {
        debugPrint('[TechnicalProductsMigration] $errorCount errors during migration');
      }
    } catch (e) {
      debugPrint('[TechnicalProductsMigration] Migration failed: $e');
    }
  }

  /// Check if migration is needed
  static bool get needsMigration {
    try {
      final box = Hive.box<TechnicalProduct>(BoxNames.technicalProducts);
      if (box.isEmpty) return false;
      
      return box.values.any((product) {
        try {
          // If we can't access productFamily as ProductFamily, migration is needed
          final _ = product.productFamily as ProductFamily?;
          return false;
        } catch (_) {
          return true;
        }
      });
    } catch (_) {
      return false;
    }
  }

  /// Initialize migration if needed
  static Future<void> initialize() async {
    if (needsMigration) {
      await migrateLegacyData();
    }
  }

  /// Get migration status report
  static Map<String, dynamic> getMigrationReport() {
    try {
      final box = Hive.box<TechnicalProduct>(BoxNames.technicalProducts);
      final total = box.length;
      
      if (total == 0) {
        return {
          'total_products': 0,
          'migration_needed': false,
          'message': 'No products to migrate',
        };
      }

      final legacyProducts = box.values.where((product) {
        try {
          return product.productFamily is String;
        } catch (_) {
          return true;
        }
      }).length;

      return {
        'total_products': total,
        'legacy_products': legacyProducts,
        'migration_needed': legacyProducts > 0,
        'message': legacyProducts > 0 
            ? '$legacyProducts products need migration' 
            : 'All products are up to date',
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'migration_needed': false,
      };
    }
  }

  /// Force re-extraction of all products to update confidence levels and scores
  /// This can be useful after updating extraction algorithms
  static Future<Map<String, dynamic>> recalculateExtractionScores() async {
    final service = TechnicalProductService();
    final box = Hive.box<TechnicalProduct>(BoxNames.technicalProducts);
    
    final startTime = DateTime.now();
    var processed = 0;
    var updated = 0;
    
    for (final product in box.values) {
      try {
        // Recalculate confidence level and extraction score
        final newScore = service.calculateExtractionScore(
          title: product.name,
          family: product.productFamily,
          applications: product.applications,
          standards: product.standards,
          metrics: product.metrics,
          facts: product.keyFacts,
          characteristics: product.characteristics,
          tags: product.tags,
          combinedText: product.extractedText,
        );
        
        final newConfidence = ConfidenceLevel.fromScore(newScore);
        
        // Only update if values have changed
        if (product.extractionScore != newScore || 
            product.confidenceLevel != newConfidence) {
          
          product.extractionScore = newScore;
          product.confidenceLevel = newConfidence;
          product.lastModified = DateTime.now();
          
          await box.put(product.id, product);
          updated++;
        }
        
        processed++;
      } catch (e) {
        // Skip products with errors
        continue;
      }
    }
    
    final duration = DateTime.now().difference(startTime);
    
    return {
      'processed': processed,
      'updated': updated,
      'duration_ms': duration.inMilliseconds,
      'message': 'Recalculated extraction scores for $processed products, $updated updated',
    };
  }
}
