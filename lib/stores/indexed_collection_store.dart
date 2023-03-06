import 'dart:async';

import 'package:flutter/material.dart';
import 'package:string_similarity/string_similarity.dart';

import '../setup.dart';
import '../utils/debounce.dart';
import 'global_file_change_store.dart';

/// Defines a base/interface class for stores that works on top of a collection of items of type [T].
///
/// Current being extended by [BackgroundTaskStore] and [DeviceAppsStore].
///
/// It ensures that we have a collection of items and each item is indexed by its ID.
/// This way we can plug mixins like [SearchableStoreMixin] and [SelectableStoreMixin]
/// into the store as demand, so each key feature (e.g search, select/unselect)
/// does not know about each other thus we achieve a low-coupling class inheritance tree.
abstract class IndexedCollectionStore<T> extends ChangeNotifier {
  /// Full source, all data linked to [this] store, it does not handle any logic, it must hold all
  /// items and should not contain any other logic such as selected items or even the search results.
  ///
  /// Override [collection] to provide such features instead.
  @protected
  Map<String, T> get collectionIndexedById;

  List<T> get collection => collectionIndexedById.values.toList();

  String getItemId(T item);
}

mixin SearchableStoreMixin<T> on IndexedCollectionStore<T> {
  String? _searchText;

  void disableSearch() {
    _searchText = null;
    notifyListeners();
  }

  /// Packages to be rendered on the screen
  @override
  List<T> get collection => isSearchMode ? searchResults : super.collection;

  /// Compute the string match ranking to show best results first.
  @protected
  double computeMatch(String source, String query) {
    return query.similarityTo(source);
  }

  /// Sort the computations made by [computeMatch],
  /// the default sort behavior (and probably the only one we need) is desc (best results first).
  ///
  /// Usually subclasses don't need to override this, but if we do, here we are.
  @protected
  int sortMatch(double z, double a) {
    return z.compareTo(a);
  }

  /// Checks if [source] contains all the characters of [text] in the correct order
  ///
  /// Example:
  /// ```
  /// hasMatch('abcdef', 'adf') // true
  /// hasMatch('dbcaef', 'adf') // false
  /// ```
  bool _hasWildcardMatch(String source, String query) {
    final String matcher =
        query.substring(0, query.length - 1).split('').join('.*');
    final String ending = query[query.length - 1];

    final String rawRegex = matcher + ending;

    final RegExp regex = RegExp(rawRegex, caseSensitive: caseSensitive);

    return regex.hasMatch(source);
  }

  /// Provides a fast way to filter results, the matches that passes this filter
  /// will be called with [computeMatch] to define it's list ranking.
  bool hasMatch(String source, String query) =>
      _hasWildcardMatch(source, query);

  bool get isSearchMode => _searchText != null;

  /// Subclasses must override this method to provide a list of strings
  /// that we can use to search over when the user starts typing.
  @protected
  List<String> createSearchableStringsOf(T item);

  @protected
  bool get caseSensitive => false;

  @protected
  double computeMatches(List<String> sources, String query) {
    final List<double> matches = <double>[
      0,
      for (final String source in sources)
        computeMatch(
          caseSensitive ? source : source.toLowerCase().replaceAll(' ', ''),
          caseSensitive ? query : query.toLowerCase().replaceAll(' ', ''),
        ),
    ]..sort((double z, double a) => (z - a) ~/ 1);

    return matches.first;
  }

  int _sortItemsByBestResultsFirst(T a, T z) => sortMatch(
        computeMatches(createSearchableStringsOf(a), _searchText!),
        computeMatches(createSearchableStringsOf(z), _searchText!),
      );

  bool _itemHasMatch(T item) {
    return createSearchableStringsOf(item)
        .any((String source) => hasMatch(source, _searchText!));
  }

  List<T> get searchResults {
    if (_searchText == null) return <T>[];

    final List<T> filtered = collectionIndexedById.values
        .where(_itemHasMatch)
        .toList()
      ..sort(_sortItemsByBestResultsFirst);

    return filtered;
  }

  final void Function(void Function() p1) debounceSearch = debounceIt50ms();

  /// Add all matched apps to [results] array if any
  ///
  /// This method will disable search if [text] is empty by default
  void search(String text) {
    _searchText = text;

    if (text.isEmpty) {
      _searchText = null;
    }

    debounceSearch(() => notifyListeners());
  }
}

// mixin SelectableAndSearchableStoreMixin<T> on SelectableStoreMixin<T>, SearchableStoreMixin<T> {
//   @override
//   bool get isAllSelected => displayableCollection.length == selected.length;
// }

/// Helpful mixin to add selection features to stores that implements [IndexedCollectionStore].
mixin SelectableStoreMixin<T> on IndexedCollectionStore<T> {
  /// Set of all selected items.
  final Set<String> _selected = <String>{};

  /// Whether or not the user has marked at least one collection item [T] as marked.
  /// Useful to enter the UI "selection mode".
  bool get inSelectionMode => selected.isNotEmpty;

  /// Public list of all selected items.
  Set<T> get selected {
    _selected.removeWhere((String id) => collectionIndexedById[id] == null);

    return Set<T>.unmodifiable(
      _selected.map((String id) => collectionIndexedById[id]!),
    );
  }

  bool get isAllSelected => collection.length == selected.length;

  /// Allow subclasses define a predicate to define whether or not a collection item of type [T]
  /// can be marked as selected or not. The current "usefulness" of this is to avoid
  /// user selecting [BackgroundTaskDisplayInfo] items that are loading/extracting.
  @protected
  bool canBeSelected(T item) {
    return true;
  }

  /// Same as [canBeSelected] but for unselect action.
  @protected
  bool canBeUnselected(T item) {
    return true;
  }

  /// Add a single [package] to the [selected] Set.
  void select({T? item, String? itemId, bool notify = true}) {
    assert(item != null || itemId != null);

    final T? e = item ?? collectionIndexedById[itemId];

    if (e == null) {
      return unselect(item: item);
    }

    if (!canBeSelected(e)) return;

    final String id = getItemId(e);

    _selected.add(id);

    if (notify) notifyListeners();
  }

  /// Set multiple [packages] state as _selected.
  void selectMany({
    List<T>? items,
    List<String>? itemIds,
    bool notify = true,
  }) {
    assert(items != null || itemIds != null);

    final Iterable<String> ids = itemIds ?? items!.map(getItemId);

    for (final String id in ids) {
      select(itemId: id, notify: false);
    }

    if (notify) notifyListeners();
  }

  /// Set multiple [packages] state as _unselected.
  void unselectMany({
    List<T>? items,
    List<String>? itemIds,
    bool notify = true,
  }) {
    assert(items != null || itemIds != null);

    final Iterable<String> ids = itemIds ?? items!.map(getItemId);

    for (final String id in ids) {
      unselect(itemId: id, notify: false);
    }

    if (notify) notifyListeners();
  }

  void unselect({T? item, String? itemId, bool notify = true}) {
    assert(item != null || itemId != null);

    final String id = itemId ?? getItemId(item as T);

    final T? e = collectionIndexedById[id];

    // If the element is null then it must be unselected to avoid ghost ids in the [_selected] array.
    if (e != null) {
      // Avoid unselect if the element cannot be unselected.
      if (!canBeUnselected(e)) return;
    }

    _selected.remove(id);

    if (notify) notifyListeners();
  }

  void toggleSelect({
    T? item,
    String? itemId,
    bool notify = true,
  }) {
    assert(item != null || itemId != null);

    final String id = itemId ?? getItemId(item as T);

    if (isSelected(itemId: id)) {
      unselect(itemId: id, notify: false);
    } else {
      select(itemId: id, notify: false);
    }

    if (notify) notifyListeners();
  }

  void unselectAll({bool notify = true}) {
    unselectMany(itemIds: _selected.toList(), notify: false);
    if (notify) notifyListeners();
  }

  void selectAll({bool notify = true}) {
    selectMany(items: collection, notify: false);
    if (notify) notifyListeners();
  }

  void invertSelection({bool notify = true}) {
    for (final T item in collection) {
      toggleSelect(item: item, notify: false);
    }

    if (notify) notifyListeners();
  }

  bool isSelected({T? item, String? itemId}) =>
      _selected.contains(itemId ?? getItemId(item as T));

  void toggleSelectAll({bool notify = false}) {
    if (isAllSelected) {
      unselectAll(notify: false);
    } else {
      selectAll(notify: false);
    }

    if (notify) notifyListeners();
  }
}

/// A simple interface/mixin on [ChangeNotifier] for defining a field that will be useful to mark
/// a store as loading or making some background task.
mixin ProgressIndicatorMixin on ChangeNotifier {
  bool inProgress = false;

  void showProgressIndicator() {
    inProgress = true;
    notifyListeners();
  }

  void hideProgressIndicator() {
    inProgress = false;
    notifyListeners();
  }
}

/// This class is still not abstract enough but I decided to keep it here anyways,
/// later on, so I'll remove all fields logic to a more abstract structure
/// that will be entirely defined using a simple [percent] field.
mixin LoadingStoreMixin<T> on IndexedCollectionStore<T> {
  bool isLoading = false;
  int? totalCount;

  bool get isDeterminatedState => totalCount != null;

  int get loadedCount => isDeterminatedState ? collectionIndexedById.length : 0;
  bool get fullyLoaded =>
      isDeterminatedState && !isLoading && loadedCount >= totalCount!;
  double get percent => isDeterminatedState ? loadedCount / totalCount! : 0;

  int defineTotalItemsCount(int totalCount) => this.totalCount = totalCount;
}

mixin FileChangeAwareMixin {
  StreamSubscription<FileCommit>? _listener;

  Future<void> startListeningToFileChanges() async {
    if (_listener != null) await stopListeningToFileChanges();

    _listener = getIt<GlobalFileChangeStore>().onFileChange.listen(
      (FileCommit commit) {
        onFileChange(commit);
      },
      onDone: stopListeningToFileChanges,
      cancelOnError: true,
      onError: (_) => stopListeningToFileChanges(),
    );
  }

  Future<void> stopListeningToFileChanges() async {
    await _listener?.cancel();
    _listener = null;
  }

  void onFileChange(FileCommit commit);
}
