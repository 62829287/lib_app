import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningBefore;
  final VoidCallback onWarning;
  final VoidCallback onTimeout;
  final Widget child;
  final bool enabled;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warningBefore,
    required this.onWarning,
    required this.onTimeout,
    required this.child,
    this.enabled = true,
  });

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  Timer? _warningTimer;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    if (widget.enabled) _restart();
  }

  @override
  void didUpdateWidget(covariant InactivityWatcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled ||
        widget.timeout != oldWidget.timeout ||
        widget.warningBefore != oldWidget.warningBefore) {
      if (widget.enabled) {
        _restart();
      } else {
        _cancel();
      }
    }
  }

  bool _onKey(KeyEvent event) {
    if (widget.enabled) _restart();
    return false;
  }

  void _cancel() {
    _timer?.cancel();
    _warningTimer?.cancel();
    _timer = null;
    _warningTimer = null;
  }

  void _restart() {
    _cancel();
    final warnAt = widget.timeout - widget.warningBefore;
    if (warnAt > Duration.zero) {
      _warningTimer = Timer(warnAt, widget.onWarning);
    }
    _timer = Timer(widget.timeout, widget.onTimeout);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (widget.enabled) _restart();
      },
      onPointerMove: (_) {
        if (widget.enabled) _restart();
      },
      onPointerSignal: (_) {
        if (widget.enabled) _restart();
      },
      child: widget.child,
    );
  }
}
