import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pit_scout/Widgets/numericInput.dart';
import 'ScoutingPreGameScreen.dart';
import 'package:flutter/services.dart';

class ScoutingTeamView extends StatefulWidget{
  final String qualNumber;
  final String tournament;
  final String userId;

  ScoutingTeamView({Key key, @required this.qualNumber, this.tournament, this.userId}) : super(key:key);

  @override
  Select createState() => Select();
}


class Select extends State<ScoutingTeamView> {
  String teamNumber = 'Number';
  String teamName = 'Name';
  String url;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    getTeamData();
    super.initState();
  }

  setOrientation() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  getTeamData() {
    Firestore.instance.collection('users').document(widget.userId).collection('tournaments')
        .document(widget.tournament).collection('gamesToScout').getDocuments().then((val) {
          for(int i=0; i<val.documents.length; i++){
            if (val.documents[i].documentID==widget.qualNumber){
              this.teamNumber = val.documents[i].data['teamNumber'];
              getImageURL();
              Firestore.instance.collection('tournaments').document(widget.tournament).collection('teams').document(teamNumber).get().then((res) {
                setState(() {
                  this.teamName = res.data['team_name'];
                });
              });
            }
          }
      });
    }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Qual " + widget.qualNumber.toString(),
          textAlign: TextAlign.center,
        ),
      ),
      body: ListView(
        children: <Widget>[
          Padding(padding: EdgeInsets.all(15.0),),
          Column(
            children: <Widget>[
              Text(
                teamNumber + ' - ' + teamName,
                style: TextStyle(fontSize: 30.0,),
                textAlign: TextAlign.center,
              ),
              Padding(padding: EdgeInsets.all(15.0),),
              robotImage(),
              Padding(padding: EdgeInsets.all(15.0),),
              dataOverride(context),
              Padding(padding: EdgeInsets.all(15.0),),
              Container(
                width: 200,
                height: 100,
                child: FlatButton(
                  color: Colors.blue,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) =>
                          ScoutingPreGameScreen(teamName: teamName, teamNumber: teamNumber, tournament: widget.tournament,
                            userId: widget.userId, qualNumber: widget.qualNumber,)),
                    ).then((_) {
                      setOrientation();
                    });
                  },
                  padding: EdgeInsets.all(20),
                  child: Text(
                    "המשך",
                    style: TextStyle(fontSize: 40, color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  getImageURL ()
  {
    FirebaseStorage.instance.ref().child('robots_pictures').child(widget.tournament).child(teamNumber).getDownloadURL()
    .then((res) {
      setState(() {
        url = res;
      });
    }).catchError((err) {
      print(err);
      url = null;
      }
    );
  }

  Widget dataOverride(BuildContext context) {
    return Container(
      width: 200,
      height: 75,
      child: FlatButton(
        color: Colors.blue,
        onPressed: () {
          overrideDialog(context);
        },
        child: Text(
          'מעקף',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 40, color: Colors.white),
        ),
      ),
    );
  }

  Widget robotImage() {
    return Center(
      child: GestureDetector(
        child: ClipOval(
          child: Container(
            color: Colors.blue,
            height: 250.0,
            width: 250.0,
            child:url != null
                ? RotatedBox(
                  quarterTurns: 5,
                  child: Image.network(url, fit: BoxFit.cover,),
                )
                : Container(
                child: Column(
                  children: <Widget>[
                    Padding(padding: EdgeInsets.all(23.0),),
                    Text(
                      "No\nImage",
                      style: TextStyle(fontSize: 60, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> overrideDialog(BuildContext context) {
    TextEditingController _newTeamNumber = new TextEditingController();
    TextEditingController _newTeamName = new TextEditingController();

    return showDialog<void>(
        context: context,
        builder: (BuildContext context){
          return AlertDialog(
            title: Text(
              'מעקף - הכנסת מידע חדש',
              style: TextStyle(fontSize: 25.0, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            content: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  openQuestions('מספר קבוצה', _newTeamNumber, false),
                  Padding(padding: EdgeInsets.all(10.0),),
                  openQuestions('שם הקבוצה', _newTeamName, true),
                ],
              ),
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('ביטול'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('שמור'),
                onPressed: () {
                  if (_formKey.currentState.validate()){
                    setState(() {
                      this.teamNumber = _newTeamNumber.text;
                      this.teamName = _newTeamName.text;
                    });

                    Navigator.of(context).pop();
                  }
                },
              ),

            ],
          );
        }
    );
  }

  Widget openQuestions(String measurementUnits, TextEditingController controller, bool isString){
    return TextFormField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: isString ? TextInputType.text : TextInputType.numberWithOptions(),
        decoration: InputDecoration(
          hintText: measurementUnits,
          border: new OutlineInputBorder(
              borderSide: new BorderSide(color: Colors.teal)
          ),
        ),
        validator: (value) {
          if (value.isEmpty){
            return 'Please enter value';
          }
          return null;
        }
    );
  }
}


