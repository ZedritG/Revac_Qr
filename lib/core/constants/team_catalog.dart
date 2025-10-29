import 'package:revec_qr/features/visits/domain/entities/team_info.dart';

class TeamCatalog {
  const TeamCatalog._();

  static final Map<String, TeamInfo> _teamsByCode = {
    'TM-001': const TeamInfo(
      code: 'TM-001',
      name: 'Equipo de Mantenimiento Norte',
      description:
          'Cuadrilla responsable de subestaciones y climatización en la planta norte.',
      locationHint: 'Base operativa: Taller 1 - Planta Norte',
    ),
    'TM-002': const TeamInfo(
      code: 'TM-002',
      name: 'Equipo Eléctrico Turno B',
      description:
          'Equipo especializado en maniobras de media tensión y tableros principales.',
      locationHint: 'Sala eléctrica nivel -1',
    ),
    'TM-003': const TeamInfo(
      code: 'TM-003',
      name: 'Equipo de Servicios Generales',
      description:
          'Brigada encargada de utilidades, agua industrial y aire comprimido.',
      locationHint: 'Base operativa: Planta de servicios',
    ),
  };

  static TeamInfo infoFor(String code) {
    return _teamsByCode[code] ??
        TeamInfo(
          code: code,
          name: 'Equipo de trabajo no identificado',
          description: 'El código escaneado no coincide con el catálogo local.',
        );
  }

  static List<TeamInfo> get all => _teamsByCode.values.toList();
}
