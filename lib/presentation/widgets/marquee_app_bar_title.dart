import 'package:flutter/material.dart';

class MarqueeAppBarTitle extends StatefulWidget {
  const MarqueeAppBarTitle({super.key, required this.text});

  final String text;

  @override
  State<MarqueeAppBarTitle> createState() => _MarqueeAppBarTitleState();
}

class _MarqueeAppBarTitleState extends State<MarqueeAppBarTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = DefaultTextStyle.of(context).style;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textPainter = TextPainter(
            text: TextSpan(text: widget.text, style: textStyle),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();

          final travelDistance = constraints.maxWidth + textPainter.width;

          return SizedBox(
            height: kToolbarHeight,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset =
                    constraints.maxWidth - (_controller.value * travelDistance);

                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.text,
                  maxLines: 1,
                  softWrap: false,
                  style: textStyle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
