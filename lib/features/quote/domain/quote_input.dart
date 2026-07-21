class QuoteInput {
  const QuoteInput({
    required this.distanceKm,
    required this.totalWeightKg,
    required this.totalVolumeM3,
    required this.invoiceValue,
    required this.marginPercent,
    this.toll = 0,
    this.loadingFee = 0,
    this.unloadingFee = 0,
    this.icmsPercent = 12,
    this.pisPercent = 1.65,
    this.cofinsPercent = 7.6,
    this.adValoremPercent = 0.25,
    this.insurancePercent = 0.35,
    this.trackingFee = 85,
    this.minimumAntt = 0,
  });

  final double distanceKm;
  final double totalWeightKg;
  final double totalVolumeM3;
  final double invoiceValue;
  final double marginPercent;
  final double toll;
  final double loadingFee;
  final double unloadingFee;
  final double icmsPercent;
  final double pisPercent;
  final double cofinsPercent;
  final double adValoremPercent;
  final double insurancePercent;
  final double trackingFee;
  final double minimumAntt;
}
