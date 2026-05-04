import 'dart:async';
import 'dart:convert';

import 'package:template_app/core/services/datasource/local_storage/local_storage.dart';
import 'package:template_app/core/utilities/logger.dart';

/// A generic cache entry that holds data alongside the moment it was created.
/// Used by both the memory layer and the persistent (LocalStorage) layer.
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  const CacheEntry({required this.data, required this.timestamp});

  /// Returns `true` when the entry has lived longer than [maxAge].
  /// A `null` [maxAge] means the entry never expires.
  bool isExpired(Duration? maxAge) {
    if (maxAge == null) return false;
    return DateTime.now().difference(timestamp) > maxAge;
  }

  /// Serializes the entry to a JSON-compatible map for LocalStorage.
  /// If [toJson] is provided, it converts `T` into a JSON-safe value first.
  Map<String, dynamic> toMap(dynamic Function(T data)? toJson) => {
    'timestamp': timestamp.toIso8601String(),
    'data': toJson != null ? toJson(data) : data,
  };

  /// Reconstructs an entry from a previously serialized map.
  static CacheEntry<T> fromMap<T>(
    Map<String, dynamic> map,
    T Function(dynamic json)? fromJson,
  ) {
    final raw = map['data'];
    return CacheEntry<T>(
      data: fromJson != null ? fromJson(raw) : raw as T,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

/// A hybrid cache that combines a fast in-memory layer with a durable
/// LocalStorage layer. Supports TTL expiration, force refresh,
/// stale-while-revalidate, and concurrent request deduplication.
class CacheManager {
  CacheManager(this._storage);

  final LocalStorage _storage;

  static const String _logLabel = 'CacheManager';

  /// Prefix prepended to every storage key so we can safely
  /// enumerate and clear only the keys this manager owns.
  static const String _prefix = 'cache_manager:';

  // Fast in-memory layer. Stored as `CacheEntry<dynamic>` and re-typed on read.
  final Map<String, CacheEntry> _memory = {};

  // Tracks ongoing fetches per key so concurrent callers share one Future.
  final Map<String, Future> _inFlight = {};

  String _persistKey(String key) => '$_prefix$key';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns the value for [key] using the layered cache strategy:
  ///
  ///   1. memory layer (instant)
  ///   2. LocalStorage (sync read)
  ///   3. [fetcher] (network/IO)
  ///
  /// * [maxAge]               — TTL applied to cached entries; `null` = never expires.
  /// * [forceRefresh]         — when `true`, ignores both cache layers.
  /// * [staleWhileRevalidate] — when `true` and an expired entry exists, the
  ///                            stale value is returned immediately while a
  ///                            background refresh repopulates the cache.
  /// * [fromJson] / [toJson]  — optional hooks for non-primitive `T`. Required
  ///                            when `T` is not directly JSON-serializable.
  Future<T> get<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration? maxAge,
    bool forceRefresh = false,
    bool staleWhileRevalidate = false,
    T Function(dynamic json)? fromJson,
    dynamic Function(T data)? toJson,
  }) async {
    if (forceRefresh) {
      Log.d('force refresh → fetching', label: _logLabel);
      return _fetchAndStore<T>(key, fetcher, toJson);
    }

    // ---- Step 1: in-memory hit? ----
    final memEntry = _memory[key];
    if (memEntry is CacheEntry<T>) {
      if (!memEntry.isExpired(maxAge)) {
        Log.t('memory hit: $key', label: _logLabel);
        return memEntry.data;
      }
      if (staleWhileRevalidate) {
        Log.d(
          'memory stale, revalidating in background: $key',
          label: _logLabel,
        );
        _revalidateInBackground<T>(key, fetcher, toJson);
        return memEntry.data;
      }
    }

    // ---- Step 2: persistent hit? ----
    final persisted = _readFromStorage<T>(key, fromJson);
    if (persisted != null) {
      // Promote to memory even if expired — future SWR calls benefit.
      _memory[key] = persisted;
      if (!persisted.isExpired(maxAge)) {
        Log.t('storage hit: $key', label: _logLabel);
        return persisted.data;
      }
      if (staleWhileRevalidate) {
        Log.d(
          'storage stale, revalidating in background: $key',
          label: _logLabel,
        );
        _revalidateInBackground<T>(key, fetcher, toJson);
        return persisted.data;
      }
    }

    // ---- Step 3: nothing usable — fetch synchronously ----
    Log.d('cache miss → fetching: $key', label: _logLabel);
    return _fetchAndStore<T>(key, fetcher, toJson);
  }

  /// Removes [key] from the memory layer only.
  void invalidate(String key) {
    _memory.remove(key);
    Log.d('invalidated memory: $key', label: _logLabel);
  }

  /// Removes [key] from LocalStorage only.
  Future<void> invalidatePersistent(String key) {
    Log.d('invalidated storage: $key', label: _logLabel);
    return _storage.remove(_persistKey(key));
  }

  /// Wipes the entire in-memory cache. Persistent storage is untouched.
  void clearMemory() {
    _memory.clear();
    Log.d('memory cache cleared', label: _logLabel);
  }

  /// Wipes both layers — only keys owned by this manager (i.e. those carrying
  /// our internal prefix) are removed from storage.
  Future<void> clearAll() async {
    _memory.clear();
    final ownedKeys = _storage
        .getKeys()
        .where((k) => k.startsWith(_prefix))
        .toList();
    for (final k in ownedKeys) {
      await _storage.remove(k);
    }
    Log.d(
      'all cache cleared (${ownedKeys.length} storage keys)',
      label: _logLabel,
    );
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Coalesces concurrent fetches for the same key into a single Future.
  /// On error: the previous cache (if any) is intentionally left alone, and
  /// the error is rethrown to the caller.
  Future<T> _fetchAndStore<T>(
    String key,
    Future<T> Function() fetcher,
    dynamic Function(T data)? toJson,
  ) {
    final existing = _inFlight[key];
    if (existing is Future<T>) {
      Log.t('deduped in-flight request: $key', label: _logLabel);
      return existing;
    }

    final future = () async {
      try {
        final data = await fetcher();
        final entry = CacheEntry<T>(data: data, timestamp: DateTime.now());
        // Memory write first so a follow-up read hits without awaiting disk.
        _memory[key] = entry;
        await _writeToStorage<T>(key, entry, toJson);
        Log.d('fetched and stored: $key', label: _logLabel);
        return data;
      } catch (e, st) {
        Log.e('fetch failed: $key', label: _logLabel, error: e, stackTrace: st);
        rethrow;
      } finally {
        _inFlight.remove(key);
      }
    }();

    _inFlight[key] = future;
    return future;
  }

  /// Fires a non-blocking refresh used by stale-while-revalidate.
  /// Errors are swallowed: the caller already has stale data and shouldn't
  /// crash on a background failure.
  void _revalidateInBackground<T>(
    String key,
    Future<T> Function() fetcher,
    dynamic Function(T data)? toJson,
  ) {
    if (_inFlight.containsKey(key)) return; // Already refreshing.
    unawaited(
      _fetchAndStore<T>(key, fetcher, toJson).then(
        (_) {},
        onError: (e) => Log.w(
          'background revalidation failed: $key',
          label: _logLabel,
          error: e,
        ),
      ),
    );
  }

  CacheEntry<T>? _readFromStorage<T>(
    String key,
    T Function(dynamic json)? fromJson,
  ) {
    final raw = _storage.getString(_persistKey(key));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry.fromMap<T>(map, fromJson);
    } catch (e) {
      Log.w('corrupted entry dropped: $key', label: _logLabel, error: e);
      _storage.remove(_persistKey(key));
      return null;
    }
  }

  Future<void> _writeToStorage<T>(
    String key,
    CacheEntry<T> entry,
    dynamic Function(T data)? toJson,
  ) => _storage.setString(_persistKey(key), jsonEncode(entry.toMap(toJson)));
}
