import 'package:flutter/material.dart';

import '../../core/module.dart';
import 'views/one2one_home.dart';

const SebaeModule one2OneModule = SebaeModule(
  id: 'one2one',
  name: 'One2One',
  description:
      'Préparer et conduire les réunions One2One, suivre les tâches et mesurer leur avancement.',
  icon: Icons.groups_2_outlined,
  builder: _buildOne2OneHome,
);

Widget _buildOne2OneHome(BuildContext context) => const One2OneHome();
