// 커서 페이지 목록. 끝 5행 전에 다음 페이지를 미리 요청한다(04장 S3). 다음 페이지 실패는 목록 끝에 다시 시도.
// columns > 1이면 격자(한 줄에 columns개, 높이는 내용에 맞춤 — 큰 글씨에서 고정 높이 금지, 04장 §5).
import 'package:flutter/material.dart';

import '../tokens.dart';
import 'common.dart';

typedef PageLoader<T> = Future<(List<T>, String?)> Function(String? cursor);

class PagedList<T> extends StatefulWidget {
  const PagedList({super.key, required this.load, required this.itemBuilder, required this.empty, this.header, this.columns = 1});
  final PageLoader<T> load;
  final Widget Function(BuildContext, T item, int index, List<T> all) itemBuilder;
  final Widget empty;
  final Widget? header;
  final int columns;

  @override
  State<PagedList<T>> createState() => _PagedListState<T>();
}

class _PagedListState<T> extends State<PagedList<T>> {
  final _items = <T>[];
  String? _cursor;
  bool _done = false;
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _more();
  }

  Future<void> _more() async {
    if (_loading || _done) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (items, next) = await widget.load(_cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(items);
        _cursor = next;
        _done = next == null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _cursor = null;
      _done = false;
    });
    await _more();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_error != null) return ErrorState(error: _error!, onRetry: _more);
      if (_loading) return const SkeletonList();
      return RefreshIndicator(onRefresh: _refresh, child: ListView(children: [if (widget.header != null) widget.header!, widget.empty]));
    }
    final extra = widget.header != null ? 1 : 0;
    final cols = widget.columns;
    final rows = (_items.length + cols - 1) ~/ cols;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        itemCount: rows + extra + 1,
        itemBuilder: (context, i) {
          if (extra == 1 && i == 0) return widget.header!;
          final row = i - extra;
          if (row == rows) {
            if (_error != null) {
              return TextButton(onPressed: _more, child: const Text('더 불러오지 못했습니다 · 다시 시도'));
            }
            if (!_done) return const Padding(padding: EdgeInsets.all(Space.lg), child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            return const SizedBox(height: Space.xl);
          }
          if (row * cols >= _items.length - 5 && !_done && !_loading && _error == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _more());
          }
          if (cols == 1) return widget.itemBuilder(context, _items[row], row, _items);
          return Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.lg),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (var c = 0; c < cols; c++) ...[
                if (c > 0) const SizedBox(width: Space.md),
                Expanded(child: row * cols + c < _items.length ? widget.itemBuilder(context, _items[row * cols + c], row * cols + c, _items) : const SizedBox.shrink()),
              ],
            ]),
          );
        },
      ),
    );
  }
}
