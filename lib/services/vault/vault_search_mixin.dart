import 'vault_state.dart';

/// 全文搜索逻辑。
mixin VaultSearchMixin on VaultState {
  int _searchToken = 0;

  Future<void> updateSearchQuery(String query) async {
    searchQueryS.value = query;
    final token = ++_searchToken;
    if (query.trim().isEmpty) {
      filteredNotesS.value = List.of(notesS.value);
      return;
    }
    final ids = await Future(() => indexService.searchNoteIds(query));
    if (token != _searchToken) return;
    if (notesS.value.isEmpty) {
      filteredNotesS.value = [];
      return;
    }
    filteredNotesS.value = ids
        .map((id) => notesS.value.firstWhere(
              (note) => note.id == id,
              orElse: () => notesS.value.first,
            ))
        .toList();
  }
}
