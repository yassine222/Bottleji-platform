import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/training_content.dart';
import '../../data/datasources/training_api_client.dart';
import '../../../../core/api/api_client.dart';

final trainingApiClientProvider = Provider<TrainingApiClient>((ref) {
  final dio = ApiClientConfig.createDio();
  return TrainingApiClient(dio);
});

final trainingContentProvider = FutureProvider.autoDispose<List<TrainingContent>>((ref) async {
  final client = ref.watch(trainingApiClientProvider);
  return client.getAllContent();
});

final featuredTrainingProvider = FutureProvider.autoDispose<List<TrainingContent>>((ref) async {
  final client = ref.watch(trainingApiClientProvider);
  return client.getFeaturedContent();
});

final trainingStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.watch(trainingApiClientProvider);
  return client.getStats();
});

