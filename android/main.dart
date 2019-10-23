import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vector;
import 'package:firebase_database/firebase_database.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IOT CAR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'IOT CAR'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class Signature extends CustomPainter {
  List<Offset> points;

  Signature({this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = new Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(Signature oldDelegate) => oldDelegate.points != points;
}

class _HomePageState extends State<HomePage> {
  TextEditingController _textEditingController = TextEditingController();
  int _samplingRate = 5;
  final _DBRef = FirebaseDatabase.instance.reference();

  List<Offset> _points = <Offset>[];

  List<double> _xPoints = [];
  List<double> _yPoints = [];

  List<vector.Vector2> _vectors = [];

  List<double> _distances = [];
  List<double> _angles = [];
  List<int> _directions = [];

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
        width: 300,
        height: 300,
        color: Colors.blue,
        child: new GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            setState(() {
              RenderBox object = context.findRenderObject();
              Offset _localPosition =
                  object.globalToLocal(details.globalPosition);
              if (_localPosition.dx <= 300.0 && _localPosition.dy <= 300.0)
                _points = new List.from(_points)..add(_localPosition);
            });
          },
          onPanEnd: (DragEndDetails details) => _points.add(null),
          child: new CustomPaint(
            painter: new Signature(points: _points),
            size: Size.infinite,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _textEditingController,
            maxLines: 1,
            decoration: InputDecoration(labelText: 'Enter a Sampling Rate'),
            onChanged: (String text) => this._samplingRate = int.parse(text),
          ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FloatingActionButton(
                  child: Text('clear'),
                  onPressed: () {
                    this._points.clear();
                    this._xPoints.clear();
                    this._yPoints.clear();
                    this._vectors.clear();
                    this._angles.clear();
                    this._distances.clear();
                    this._directions.clear();
                  }),
              FloatingActionButton(
                  child: Text('Upload'),
                  onPressed: () {
                    int jump =
                        (this._points.length / this._samplingRate).ceil();

                    for (int i = 0; i < this._points.length; i = i + jump) {
                      if (this._points[i] != null) {
                        this._xPoints.add((this._points[i].dx) / 300.0);
                        this._yPoints.add(1 - (this._points[i].dy / 300.0));
                      }
                    }

                    for (int i = 0; i < this._xPoints.length - 1; i++) {
                      this._vectors.add(vector.Vector2(
                          this._xPoints[i + 1] - this._xPoints[i],
                          this._yPoints[i + 1] - this._yPoints[i]));
                    }

                    for (int i = 0; i < this._vectors.length - 1; i++) {
                      this
                          ._angles
                          .add(this._vectors[i].angleTo(this._vectors[i + 1]));
                      this._directions.add(
                          this._vectors[i].cross(this._vectors[i + 1]) > 0
                              ? 1
                              : 0);
                    }

                    for (int i = 0; i < this._xPoints.length - 1; i++) {
                      this._distances.add(
                          vector.Vector2(this._xPoints[i], this._yPoints[i])
                              .distanceTo(vector.Vector2(
                                  this._xPoints[i + 1], this._yPoints[i + 1])));
                    }
                    for (int i = 0; i < this._angles.length; i++) {
                      if (this._directions[i] == 0)
                        this._angles[i] = this._angles[i] * -1;
                    }

                    _DBRef.child("/distances").set(this._distances);
                    _DBRef.child("/moveAngles").set(this._angles);
                    _DBRef.child("/length").set(this._angles.length);
                    _DBRef.child("/allow").set(0);
                  }),
              FloatingActionButton(
                child: Text('Allow'),
                onPressed: () {
                  _DBRef.child("/allow").set(1);
                },
              )
            ],
          ),
        ],
      ),
    );
  }
}
