import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/vita_theme.dart';

/// A premium horizontal ruler picker — the signature number input used by
/// best-in-class fitness onboarding. Drag the ruler under a fixed centre
/// marker; it snaps to whole steps and fires haptics on each tick.
class VitaRulerPicker extends StatefulWidget {
  const VitaRulerPicker({
    super.key,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.majorEvery = 5,
    this.height = 96,
  });

  final double min;
  final double max;
  final double value;
  final double step;
  final int majorEvery;
  final double height;
  final ValueChanged<double> onChanged;

  @override
  State<VitaRulerPicker> createState() => _VitaRulerPickerState();
}

class _VitaRulerPickerState extends State<VitaRulerPicker> {
  static const double _spacing = 13;
  late ScrollController _controller;
  int _index = 0;
  bool _snapping = false;

  int get _count => ((widget.max - widget.min) / widget.step).round() + 1;
  int _indexFor(double v) => ((v - widget.min) / widget.step).round().clamp(0, _count - 1);

  @override
  void initState() {
    super.initState();
    _index = _indexFor(widget.value);
    _controller = ScrollController(initialScrollOffset: _index * _spacing);
  }

  @override
  void didUpdateWidget(VitaRulerPicker old) {
    super.didUpdateWidget(old);
    // Reflect external value changes (e.g. unit toggle) without a scroll fight.
    final target = _indexFor(widget.value);
    if (target != _index && !_controller.position.isScrollingNotifier.value) {
      _index = target;
      if (_controller.hasClients) {
        _controller.jumpTo(target * _spacing);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll(double offset) {
    final i = (offset / _spacing).round().clamp(0, _count - 1);
    if (i != _index) {
      setState(() => _index = i);
      HapticFeedback.selectionClick();
      widget.onChanged(widget.min + i * widget.step);
    }
  }

  void _snap() {
    if (_snapping) return;
    _snapping = true;
    final target = (_controller.offset / _spacing).round().clamp(0, _count - 1) * _spacing.toDouble();
    _controller
        .animateTo(target, duration: const Duration(milliseconds: 180), curve: Curves.easeOut)
        .whenComplete(() => _snapping = false);
  }

  @override
  Widget build(BuildContext context) {
    final v = context.vita;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final pad = (c.maxWidth - _spacing) / 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n is ScrollUpdateNotification) _onScroll(_controller.offset);
                  if (n is ScrollEndNotification) _snap();
                  return false;
                },
                child: ListView.builder(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  itemExtent: _spacing,
                  itemCount: _count,
                  itemBuilder: (context, i) {
                    final major = i % widget.majorEvery == 0;
                    final val = (widget.min + i * widget.step);
                    return CustomPaint(
                      painter: _TickPainter(
                        major: major,
                        color: major ? v.inkSoft : v.line,
                        label: major ? val.toStringAsFixed(0) : null,
                        labelColor: v.muted,
                      ),
                    );
                  },
                ),
              ),
              // Fade edges
              Positioned.fill(child: IgnorePointer(child: _EdgeFade(color: v.card))),
              // Centre marker
              IgnorePointer(
                child: Container(
                  width: 4,
                  height: widget.height * 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [v.brand, v.accent],
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({required this.major, required this.color, this.label, required this.labelColor});
  final bool major;
  final Color color;
  final String? label;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = major ? 2 : 1.2
      ..strokeCap = StrokeCap.round;
    final tickH = major ? size.height * 0.34 : size.height * 0.18;
    final top = size.height * 0.30;
    canvas.drawLine(Offset(cx, top), Offset(cx, top + tickH), paint);

    if (label != null) {
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, top + tickH + 6));
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.major != major || old.color != color || old.label != label;
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color,
            color.withOpacity(0),
            color.withOpacity(0),
            color,
          ],
          stops: const [0.0, 0.14, 0.86, 1.0],
        ),
      ),
    );
  }
}
