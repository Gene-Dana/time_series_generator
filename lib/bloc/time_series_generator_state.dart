part of 'time_series_generator_bloc.dart';

class TimeSeriesGeneratorState extends Equatable {
  final List<int> subscribers;
  final double? batchSize;
  final double? sampleRate;
  final List<ToneConfig>? toneConfigs;
  final CurrentTimeSeriesData? current;
  final bool? isGenerating;

  TimeSeriesGeneratorState({
    this.subscribers = const [],
    this.batchSize = 100,
    this.sampleRate = 0,
    this.toneConfigs = const [],
    required this.current,
    this.isGenerating = false,
  });

  TimeSeriesGeneratorState copyWith({
    List<int>? subscribers,
    double? batchSize,
    double? sampleRate,
    List<ToneConfig>? toneConfigs,
    CurrentTimeSeriesData? current,
    bool? isGenerating,
  }) {
    return TimeSeriesGeneratorState(
      subscribers: subscribers ?? this.subscribers,
      batchSize: batchSize ?? this.batchSize,
      sampleRate: sampleRate ?? this.sampleRate,
      toneConfigs: toneConfigs ?? this.toneConfigs,
      current: current ?? this.current,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }

  @override
  List<Object?> get props {
    return [
      subscribers,
      batchSize,
      sampleRate,
      toneConfigs,
      current,
      isGenerating,
    ];
  }
}
