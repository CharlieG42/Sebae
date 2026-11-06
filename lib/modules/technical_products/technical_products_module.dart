import 'package:flutter/material.dart';

import '../../core/module.dart';
import 'views/technical_products_home.dart';

const SebaeModule technicalProductsModule = SebaeModule(
  id: 'technical_products',
  name: 'Produits techniques',
  description:
      'Centraliser les fiches techniques importées depuis PowerPoint et organiser les informations produit.',
  icon: Icons.precision_manufacturing_outlined,
  builder: _buildTechnicalProductsHome,
);

Widget _buildTechnicalProductsHome(BuildContext context) =>
    const TechnicalProductsHome();
