class OdpPoint {
  final String id;
  final String code; // Contoh: ODP-MMD-KBU-01
  final String locationName;
  final double latitude;
  final double longitude;
  final int totalPorts;
  final int usedPorts;

  OdpPoint({
    required this.id,
    required this.code,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.totalPorts = 8,
    this.usedPorts = 4,
  });

  int get availablePorts => totalPorts - usedPorts;
  bool get hasCapacity => availablePorts > 0;
}
