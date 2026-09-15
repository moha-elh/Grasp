import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/cards_repository.dart';
import '../data/repositories/coverage_repository.dart';
import '../data/repositories/reviews_repository.dart';
import '../data/services/dropbox_service.dart';
import '../data/services/explore_service.dart';
import '../data/services/fsrs_service.dart';
import '../data/services/llm_service.dart';
import '../data/services/search_service.dart';
import 'net.dart';

/// Shared Supabase client (initialized in main before runApp).
final supabaseProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

/// Current authenticated user id, or null. Single-user, RLS-scoped (§8).
final userIdProvider = Provider<String?>(
    (ref) => ref.watch(supabaseProvider).auth.currentUser?.id);

// --- Services ---
final fsrsProvider = Provider((_) => FsrsService());
// Both use the DNS-resilient client so a flaky phone resolver can't break them.
final dropboxProvider = Provider((_) => DropboxService(resilientHttpClient()));
final llmProvider = Provider((_) => LlmService(resilientHttpClient()));
final searchProvider = Provider((_) => SearchService(resilientHttpClient()));
final exploreServiceProvider = Provider((ref) => ExploreService(
      ref.watch(cardsRepoProvider),
      ref.watch(llmProvider),
      ref.watch(searchProvider),
    ));

// --- Repositories ---
final cardsRepoProvider =
    Provider((ref) => CardsRepository(ref.watch(supabaseProvider)));
final reviewsRepoProvider =
    Provider((ref) => ReviewsRepository(ref.watch(supabaseProvider)));
final coverageRepoProvider =
    Provider((ref) => CoverageRepository(ref.watch(supabaseProvider)));
