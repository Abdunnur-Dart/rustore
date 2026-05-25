import 'package:flutter/material.dart';

void main() {
  runApp(const SimplePaintApp());
}

class SimplePaintApp extends StatelessWidget {
  const SimplePaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Paint',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PaintScreen(),
    );
  }
}

class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  List<DrawingShape> shapes = [];
  DrawingMode currentMode = DrawingMode.pen;
  Color selectedColor = Colors.black;
  double strokeWidth = 4.0;
  
  Offset? currentStart;
  Offset? currentEnd;
  
  final List<Color> palette = [
    Colors.black, Colors.red, Colors.orange, Colors.yellow, 
    Colors.green, Colors.blue, Colors.indigo, Colors.purple,
    Colors.pink, Colors.brown, Colors.grey, Colors.teal,
    Colors.cyan, Colors.lime, Colors.amber, Colors.deepOrange,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Paint'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.black87),
            onPressed: () {
              setState(() {
                shapes.clear();
              });
            },
            tooltip: 'Очистить всё',
          ),
        ],
      ),
      body: Column(
        children: [
          // Панель инструментов
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: Colors.white,
            child: Column(
              children: [
                // Инструменты
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildToolButton(Icons.brush, DrawingMode.pen, 'Кисть'),
                    _buildToolButton(Icons.linear_scale, DrawingMode.line, 'Линия'),
                    _buildToolButton(Icons.crop_square, DrawingMode.rectangle, 'Прямоугольник'),
                    _buildToolButton(Icons.circle_outlined, DrawingMode.circle, 'Круг'),
                    _buildToolButton(Icons.cleaning_services, DrawingMode.eraser, 'Ластик'),
                    const SizedBox(width: 16),
                    // Толщина
                    const Icon(Icons.line_weight, size: 20),
                    SizedBox(
                      width: 120,
                      child: Slider(
                        value: strokeWidth,
                        min: 2,
                        max: 20,
                        divisions: 9,
                        onChanged: (v) => setState(() => strokeWidth = v),
                      ),
                    ),
                    Text('${strokeWidth.round()}px', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                // Палитра цветов
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: palette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final color = palette[index];
                      final isSelected = selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey.shade400,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected 
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // Холст для рисования
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(26), blurRadius: 4, offset: const Offset(2, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: CanvasPainter(
                      shapes: shapes,
                      currentMode: currentMode,
                      currentStart: currentStart,
                      currentEnd: currentEnd,
                      color: currentMode == DrawingMode.eraser ? Colors.white : selectedColor,
                      strokeWidth: strokeWidth,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, DrawingMode mode, String label) {
    final isActive = currentMode == mode;
    return Material(
      color: isActive ? Colors.blue.shade100 : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: IconButton(
        icon: Icon(icon, color: isActive ? Colors.blue.shade800 : Colors.black87),
        onPressed: () => setState(() => currentMode = mode),
        tooltip: label,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset local = box.globalToLocal(details.globalPosition);
    currentStart = local;
    currentEnd = local;
    
    if (currentMode == DrawingMode.pen || currentMode == DrawingMode.eraser) {
      setState(() {
        shapes.add(DrawingShape(
          mode: currentMode,
          points: [local],
          color: currentMode == DrawingMode.eraser ? Colors.white : selectedColor,
          strokeWidth: strokeWidth,
        ));
      });
    } else {
      setState(() {});
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset local = box.globalToLocal(details.globalPosition);
    currentEnd = local;
    
    if (currentMode == DrawingMode.pen || currentMode == DrawingMode.eraser) {
      setState(() {
        final lastShape = shapes.last;
        if (lastShape.points != null) {
          final newPoints = [...lastShape.points!, local];
          shapes.removeLast();
          shapes.add(DrawingShape(
            mode: currentMode,
            points: newPoints,
            color: currentMode == DrawingMode.eraser ? Colors.white : selectedColor,
            strokeWidth: strokeWidth,
          ));
        }
      });
    } else {
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (currentMode != DrawingMode.pen && 
        currentMode != DrawingMode.eraser && 
        currentStart != null && 
        currentEnd != null) {
      setState(() {
        shapes.add(DrawingShape(
          mode: currentMode,
          start: currentStart,
          end: currentEnd,
          color: currentMode == DrawingMode.eraser ? Colors.white : selectedColor,
          strokeWidth: strokeWidth,
        ));
      });
    }
    currentStart = null;
    currentEnd = null;
    setState(() {});
  }
}

enum DrawingMode { pen, line, rectangle, circle, eraser }

class DrawingShape {
  final DrawingMode mode;
  final List<Offset>? points;
  final Offset? start;
  final Offset? end;
  final Color color;
  final double strokeWidth;

  DrawingShape({
    required this.mode,
    this.points,
    this.start,
    this.end,
    required this.color,
    required this.strokeWidth,
  });
}

class CanvasPainter extends CustomPainter {
  final List<DrawingShape> shapes;
  final DrawingMode currentMode;
  final Offset? currentStart;
  final Offset? currentEnd;
  final Color color;
  final double strokeWidth;

  CanvasPainter({
    required this.shapes,
    required this.currentMode,
    this.currentStart,
    this.currentEnd,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Белый фон
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Рисуем все сохраненные фигуры
    for (var shape in shapes) {
      _drawShape(canvas, shape);
    }

    // Рисуем текущую фигуру (предпросмотр)
    if (currentMode != DrawingMode.pen && 
        currentMode != DrawingMode.eraser && 
        currentStart != null && 
        currentEnd != null) {
      final tempShape = DrawingShape(
        mode: currentMode,
        start: currentStart,
        end: currentEnd,
        color: color,
        strokeWidth: strokeWidth,
      );
      _drawShape(canvas, tempShape);
    }
  }

  void _drawShape(Canvas canvas, DrawingShape shape) {
    final Paint paint = Paint()
      ..color = shape.color
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (shape.mode) {
      case DrawingMode.pen:
        if (shape.points != null && shape.points!.isNotEmpty) {
          final path = Path();
          path.moveTo(shape.points!.first.dx, shape.points!.first.dy);
          for (int i = 1; i < shape.points!.length; i++) {
            path.lineTo(shape.points![i].dx, shape.points![i].dy);
          }
          canvas.drawPath(path, paint);
        }
        break;
        
      case DrawingMode.line:
        if (shape.start != null && shape.end != null) {
          canvas.drawLine(shape.start!, shape.end!, paint);
        }
        break;
        
      case DrawingMode.rectangle:
        if (shape.start != null && shape.end != null) {
          final rect = Rect.fromPoints(shape.start!, shape.end!);
          canvas.drawRect(rect, paint);
        }
        break;
        
      case DrawingMode.circle:
        if (shape.start != null && shape.end != null) {
          final rect = Rect.fromPoints(shape.start!, shape.end!);
          canvas.drawOval(rect, paint);
        }
        break;
        
      case DrawingMode.eraser:
        final eraserPaint = Paint()
          ..color = Colors.white
          ..strokeWidth = shape.strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
          
        if (shape.points != null && shape.points!.isNotEmpty) {
          final path = Path();
          path.moveTo(shape.points!.first.dx, shape.points!.first.dy);
          for (int i = 1; i < shape.points!.length; i++) {
            path.lineTo(shape.points![i].dx, shape.points![i].dy);
          }
          canvas.drawPath(path, eraserPaint);
        } else if (shape.start != null && shape.end != null) {
          if (shape.mode == DrawingMode.line) {
            canvas.drawLine(shape.start!, shape.end!, eraserPaint);
          } else if (shape.mode == DrawingMode.rectangle) {
            final rect = Rect.fromPoints(shape.start!, shape.end!);
            canvas.drawRect(rect, eraserPaint);
          } else if (shape.mode == DrawingMode.circle) {
            final rect = Rect.fromPoints(shape.start!, shape.end!);
            canvas.drawOval(rect, eraserPaint);
          }
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CanvasPainter oldDelegate) {
    return oldDelegate.shapes != shapes ||
           oldDelegate.currentStart != currentStart ||
           oldDelegate.currentEnd != currentEnd ||
           oldDelegate.currentMode != currentMode;
  }
}