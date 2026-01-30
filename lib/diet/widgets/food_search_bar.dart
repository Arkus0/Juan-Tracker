import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/food_search_provider.dart';

/// Barra de búsqueda de alimentos con autocompletado
///
/// Características:
/// - Debounce integrado (manejado por el provider)
/// - Sugerencias de autocompletado
/// - Indicador de carga
/// - Botón de limpiar
class FoodSearchBar extends ConsumerStatefulWidget {
  final Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final String? hintText;
  final bool autofocus;

  const FoodSearchBar({
    super.key,
    this.onSubmitted,
    this.onClear,
    this.hintText,
    this.autofocus = true,
  });

  @override
  ConsumerState<FoodSearchBar> createState() => _FoodSearchBarState();
}

class _FoodSearchBarState extends ConsumerState<FoodSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    
    // Escuchar cambios en el provider para sincronizar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(searchQueryProvider, (previous, next) {
        final nextValue = next as String?;
        if (nextValue != null && _controller.text != nextValue && nextValue.isEmpty) {
          _controller.text = nextValue;
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(foodSearchProvider);
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onChanged: _onTextChanged,
          onSubmitted: _onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Buscar alimentos...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _buildSuffixIcon(searchState, theme),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
          ),
        ),
        
        // Autocomplete Suggestions
        if (_showSuggestions && _controller.text.length >= 2)
          _buildSuggestionsList(),
      ],
    );
  }

  Widget _buildSuffixIcon(FoodSearchState state, ThemeData theme) {
    // Mostrar indicador de carga si está buscando
    if (state.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // Mostrar botón de limpiar si hay texto
    if (_controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: _clearSearch,
        tooltip: 'Limpiar',
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSuggestionsList() {
    return FutureBuilder<List<String>>(
      future: ref.read(foodSearchProvider.notifier)
          .getAutocompleteSuggestions(_controller.text),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(top: 4),
          elevation: 4,
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final suggestion = snapshot.data![index];
              return ListTile(
                dense: true,
                leading: const Icon(Icons.history, size: 18),
                title: Text(suggestion),
                onTap: () {
                  _controller.text = suggestion;
                  _onSubmitted(suggestion);
                },
              );
            },
          ),
        );
      },
    );
  }

  void _onTextChanged(String value) {
    setState(() => _showSuggestions = value.length >= 2);
    
    // Actualizar query en provider (con debounce interno)
    ref.read(searchQueryProvider.notifier).setQuery(value);
    ref.read(foodSearchProvider.notifier).search(value);
  }

  void _onSubmitted(String value) {
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
    widget.onSubmitted?.call(value);
  }

  void _clearSearch() {
    _controller.clear();
    _focusNode.requestFocus();
    ref.read(searchQueryProvider.notifier).setQuery('');
    ref.read(foodSearchProvider.notifier).clear();
    setState(() => _showSuggestions = false);
    widget.onClear?.call();
  }
}

/// Versión simplificada de la barra de búsqueda para inline usage
class FoodSearchBarInline extends ConsumerWidget {
  final String? initialValue;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? hintText;

  const FoodSearchBarInline({
    super.key,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.hintText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(foodSearchProvider);

    return TextField(
      controller: TextEditingController(text: initialValue)
        ..selection = TextSelection.collapsed(offset: initialValue?.length ?? 0),
      onChanged: (value) {
        ref.read(foodSearchProvider.notifier).search(value);
        onChanged?.call(value);
      },
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText ?? 'Buscar...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: searchState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.3 * 255).round()),
      ),
    );
  }
}
