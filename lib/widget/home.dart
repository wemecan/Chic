import 'dart:ui' as ui;

import 'package:chic/bean/budget.dart';
import 'package:chic/bean/currency.dart';
import 'package:chic/util/display.dart';
import 'package:chic/widget/budgetlist.dart';
import 'package:chic/widget/radius_btn.dart';
import 'package:chic/widget/smallball.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 首页
///
///

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  Budget currentBudget;
  int surplusDay = 0;
  String currencyName = "";
  double surplusAmountToday = 100.0;

  AnimationController controller;
  final double MAXSIGMA = 5.0;
  final double MINSIGMA = 0.0;
  double sigma;
  double secondOpacity = 0.0;

  GlobalKey globalKey = new GlobalKey();
  bool _second = false;

  void _loadData() async {
    var pref = await SharedPreferences.getInstance();
    var selectID = pref.getString(Budget.SPBudgetKey);

    if (selectID == null) {
      // 跳至新建Budget页面
    }

    _refreshCurrentBudget(selectID);
  }

  void _refreshCurrentBudget(String selectID) async {
    currentBudget = await Budget.getBudgetByBudgetID(selectID);
    var now = DateTime.now();
    var nowTime = DateTime(now.year, now.month, now.day);
    var mon = now.month;
    var yea = now.year;
    var day = now.day;
    if (day >= currentBudget.whichDayStart) {
      if (mon == 12) {
        yea += 1;
        mon = 1;
      } else {
        mon += 1;
      }
    }

    var nextTime = DateTime(yea, mon, currentBudget.whichDayStart);
    surplusDay = nextTime.difference(nowTime).inDays;

    currencyName = await Currency.getCurrencyNameByID(currentBudget.currencyID);
    surplusAmountToday = currentBudget.budgetSurplus / surplusDay;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    //Data Load
    currentBudget = Budget.newBudget(
      "temp",
      " ",
      0,
      0,
      1,
      0.0,
      0.0,
      false,
    );
    _loadData();

    sigma = MINSIGMA;

    // 初始化动画
    controller = new AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    final Animation curve =
        new CurvedAnimation(parent: controller, curve: Curves.easeOut);

    final Tween doubleTween = new Tween<double>(begin: MINSIGMA, end: MAXSIGMA);
    final Tween opacityTween = new Tween<double>(begin: 0.0, end: 1.0);

    curve.addListener(() {
      setState(() {
        secondOpacity = opacityTween.evaluate(curve);
        sigma = doubleTween.evaluate(curve);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    initScreen(context);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _firstPage(),
        new IgnorePointer(
          child: _secondPage(),
        ),
      ],
    );
  }

  setSecondPage() {
    controller.reset();
    controller.forward();
    setState(() {
      _second = true;
    });
  }

  setFirstPage() {
    controller.stop();
    setState(() {
      _second = false;
    });
  }

  onTapDownEachDay(TapDownDetails details) {
    setSecondPage();
  }

  onTapDragEndEachDay(DragEndDetails details) {
    setFirstPage();
  }

  onTapUpEachDay(TapUpDetails details) {
    setFirstPage();
  }

  List<Offset> _points = <Offset>[];

  Widget _firstPage() {
    return Stack(
      children: <Widget>[
        Container(
          color: Colors.blue,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 6,
                child: _widgetMain(),
              ),
              Expanded(
                flex: 1,
                child: HomeBottomBtn(this),
              )
            ],
          ),
        ),
//        GestureDetector(
//          onPanUpdate: (DragUpdateDetails details) {
//            setState(() {
//              RenderBox referenceBox = context.findRenderObject();
//              Offset localPosition =
//                  referenceBox.globalToLocal(details.globalPosition);
//              _points = new List.from(_points)..add(localPosition);
//            });
//          },
//          onPanEnd: (DragEndDetails details) => _points.add(null),
//           CustomPaint(
//            painter: new SignaturePainter(_points),
//            size: Size.infinite,
//          ),
//        ),
      ],
    );
  }

  Widget _secondPage() {
    return Opacity(
      opacity: _second ? 1.0 : 0.0,
      child: new BackdropFilter(
        filter: new ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Opacity(
          opacity: secondOpacity,
          child: Container(
            color: Colors.black.withOpacity(0.01),
            child: new Center(
              child: new RichText(
                text: new TextSpan(
                  children: <TextSpan>[
                    new TextSpan(
                        text: "\n${surplusAmountToday.toStringAsFixed(2)}",
                        style: new TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          fontSize: 48.0,
                        )),
                    new TextSpan(
                        text: "\n今日剩余",
                        style: new TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                        )),
                  ],
                  text: currencyName,
                  style: new TextStyle(
                      fontSize: 18.0,
                      decoration: TextDecoration.none,
                      color: Colors.orange),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _widgetMain() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.ltr,
      children: <Widget>[
        SmallBall(
          amount: currentBudget.budgetSurplus,
          currencyID: currentBudget.currencyID,
        ),
        Padding(
          padding: EdgeInsets.only(top: 24.0),
          child: Text(
            "本月还有",
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            "$surplusDay天",
            style: TextStyle(
              fontSize: 26.0,
              color: Colors.white,
              decoration: TextDecoration.none,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: GestureDetector(
            onTapDown: onTapDownEachDay,
            onPanEnd: onTapDragEndEachDay,
            onTapUp: onTapUpEachDay,
            child: RadiusButton(
              "查看每日预算",
              24.0,
              20.0,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToBudgetListPage(BuildContext context) async {
    var result = await Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => new BudgetList()),
    );

    _loadData();
  }
}

@immutable
class HomeBottomBtn extends StatelessWidget {
  final _HomePageState state;

  HomeBottomBtn(this.state);

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Stack(children: <Widget>[
      Align(
        alignment: AlignmentDirectional.bottomStart,
        child: translucentCircleBtn(
          InkWell(
            highlightColor: Colors.orange,
            onTap: () {
              state._navigateToBudgetListPage(context);
            },
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(
                Icons.assignment,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      Align(
        alignment: AlignmentDirectional.bottomEnd,
        child: translucentCircleBtn(
          InkWell(
            highlightColor: Colors.orange,
            onTap: () {
              state._navigateToBudgetListPage(context);
            },
            child: Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(
                Icons.menu,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    ]));
  }

  Widget translucentCircleBtn(Widget icon) {
    return Padding(
      padding: EdgeInsets.all(18.0),
      child: Material(
        color: Colors.black26,
        borderRadius: new BorderRadius.circular(100.0),
        child: icon,
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  SignaturePainter(this.points);

  final List<Offset> points;

  void paint(Canvas canvas, Size size) {
    var paint = new Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null)
        canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  bool shouldRepaint(SignaturePainter other) => other.points != points;
}
