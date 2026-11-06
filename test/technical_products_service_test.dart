import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sebae/core/storage/box_names.dart';
import 'package:sebae/core/storage/hive_service.dart';
import 'package:sebae/modules/technical_products/models/product_family.dart';
import 'package:sebae/modules/technical_products/models/technical_product.dart';
import 'package:sebae/modules/technical_products/services/technical_product_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(pathProviderChannel, (methodCall) async {
    switch (methodCall.method) {
      case 'getApplicationSupportDirectory':
        return '.\\test_hive';
      case 'getApplicationDocumentsDirectory':
        return '.\\test_documents';
      default:
        return null;
    }
  });

  setUp(() async {
    await HiveService.init();
    await Hive.box<TechnicalProduct>(BoxNames.technicalProducts).clear();
  });

  test('importFromPowerPoint extracts a title and key facts from a PowerPoint', () async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide1.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Pompe centrifuge</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );

    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide2.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Débit nominal 120 m3/h et moteur de 15 kW.</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );

    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final service = TechnicalProductService();

    await service.importFromPowerPoint(
      sourceName: 'pompe_centrifuge.pptx',
      bytes: bytes,
    );

    expect(service.products, isNotEmpty);
    expect(service.products.first.name, 'Pompe centrifuge');
    expect(service.products.first.productFamily, ProductFamily.pompage);
    expect(service.products.first.keyFacts, isNotEmpty);
    expect(service.products.first.characteristics, isNotEmpty);
    expect(
      service.products.first.characteristics.any(
        (value) => value.contains('120') && value.contains('m3/h'),
      ),
      isTrue,
    );
    expect(service.products.first.tags, isNotEmpty);
    expect(service.products.first.technicalSummary, isNotEmpty);
  });

  test('importFromPowerPoint preserves a structured extraction for applications and metrics', () async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide1.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Pompe d irrigation</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide2.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Application : irrigation</a:t>
          </a:r>
        </a:p>
        <a:p>
          <a:r>
            <a:t>Débit : 120 m3/h</a:t>
          </a:r>
        </a:p>
        <a:p>
          <a:r>
            <a:t>Pression : 4 bar</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );

    final service = TechnicalProductService();
    await service.importFromPowerPoint(
      sourceName: 'irrigation_structured.pptx',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
    );

    final product = service.products.first;
    expect(product.applications, contains('Irrigation'));
    expect(product.metrics, isNotEmpty);
    expect(product.metrics['débit'], contains('120'));
    expect(product.keyFacts, isNotEmpty);
    expect(product.characteristics, isNotEmpty);
  });

  test('importFromPowerPoint filters XML noise and keeps only relevant facts', () async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide1.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Pompe d irrigation</a:t>
          </a:r>
        </a:p>
        <a:p>
          <a:r>
            <a:t>Quick Menu</a:t>
          </a:r>
        </a:p>
        <a:p>
          <a:r>
            <a:t>Application : irrigation</a:t>
          </a:r>
        </a:p>
        <a:p>
          <a:r>
            <a:t>Débit : 120 m3/h</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );

    final service = TechnicalProductService();
    await service.importFromPowerPoint(
      sourceName: 'noise_filtering.pptx',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
    );

    final product = service.products.first;
    expect(product.keyFacts.any((fact) => fact.toLowerCase().contains('quick menu')), isFalse);
    expect(product.keyFacts.any((fact) => fact.toLowerCase().contains('xmlns')), isFalse);
    expect(product.keyFacts, isNotEmpty);
    expect(product.applications, contains('Irrigation'));
  });

  test('products can be filtered by family and tag', () async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide1.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Pompe d irrigation</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );
    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide2.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Débit 90 m3/h, standard ISO 2858, application irrigation.</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );

    final service = TechnicalProductService();
    await service.importFromPowerPoint(
      sourceName: 'irrigation.pptx',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
    );

    expect(service.searchAdvanced(family: ProductFamily.pompage), isNotEmpty);
    expect(service.searchAdvanced(tag: 'pompe'), isNotEmpty);
    expect(service.searchAdvanced(application: 'irrigation'), isNotEmpty);
    expect(service.searchAdvanced(family: ProductFamily.traitement), isEmpty);
  });

  test('products are persisted and searchable after import', () async {
    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide1.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Pompe de transfert</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );

    archive.addFile(
      ArchiveFile(
        'ppt/slides/slide2.xml',
        0,
        utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:spTree>
    <p:sp>
      <p:txBody>
        <a:bodyPr/>
        <a:lstStyle/>
        <a:p>
          <a:r>
            <a:t>Débit 80 m3/h avec contrôle numérique.</a:t>
          </a:r>
        </a:p>
      </p:txBody>
    </p:sp>
  </p:spTree>
</p:sld>
'''),
      ),
    );

    final service = TechnicalProductService();
    await service.importFromPowerPoint(
      sourceName: 'pompe_transfert.pptx',
      bytes: Uint8List.fromList(ZipEncoder().encode(archive)),
    );

    expect(Hive.box<TechnicalProduct>(BoxNames.technicalProducts).length, 1);
    expect(service.search('transfert'), isNotEmpty);
    expect(service.search('inconnue'), isEmpty);
  });
}
