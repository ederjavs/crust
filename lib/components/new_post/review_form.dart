import 'dart:typed_data';

import 'package:crust/components/new_post/photo_selector.dart';
import 'package:crust/components/new_post/upload_overlay.dart';
import 'package:crust/models/post.dart';
import 'package:crust/models/store.dart' as MyStore;
import 'package:crust/models/user.dart';
import 'package:crust/presentation/components.dart';
import 'package:crust/presentation/theme.dart';
import 'package:crust/state/app/app_state.dart';
import 'package:crust/state/store/store_actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:multi_image_picker/asset.dart';
import 'package:redux/redux.dart';

class ReviewForm extends StatelessWidget {
  final MyStore.Store store;

  ReviewForm({Key key, this.store}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _Props>(
        converter: (Store<AppState> store) => _Props.fromStore(store),
        builder: (BuildContext context, _Props props) => _Presenter(
              isLoggedIn: props.isLoggedIn,
              me: props.me,
              store: store,
              fetchPostsByStoreId: props.fetchPostsByStoreId,
            ));
  }
}

class _Presenter extends StatefulWidget {
  final bool isLoggedIn;
  final MyStore.Store store;
  final User me;
  final Function fetchPostsByStoreId;

  _Presenter({Key key, this.isLoggedIn, this.store, this.me, this.fetchPostsByStoreId}) : super(key: key);

  @override
  _PresenterState createState() => _PresenterState(store: store, me: me, fetchPostsByStoreId: fetchPostsByStoreId);
}

class _PresenterState extends State<_Presenter> {
  final MyStore.Store store;
  final User me;
  final Function fetchPostsByStoreId;
  Post post;
  Score overallScore;
  Score tasteScore;
  Score serviceScore;
  Score valueScore;
  Score ambienceScore;
  String reviewBody;
  List<Asset> images = List<Asset>();
  List<Uint8List> imageData = List<Uint8List>();
  bool showOverlay = false;

  _PresenterState({this.store, this.me, this.fetchPostsByStoreId});

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      Scaffold(
        body: ListView(
          children: <Widget>[
            _appBar(),
            _content(),
          ],
        ),
      )
    ];
    if (showOverlay) {
      children.add(
        UploadOverlay(post: post, fetchPostsByStoreId: fetchPostsByStoreId, images: images)
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: children,
    );
  }

  Widget _appBar() {
    return Container(
      padding: EdgeInsets.only(left: 15.0, right: 15.0, top: 40.0, bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text('WRITE A REVIEW', style: Burnt.appBarTitleStyle.copyWith(fontSize: 22.0)),
              Container(height: 50, width: 50),
            ],
          ),
          Text('for', style: TextStyle(fontSize: 20.0)),
          Container(height: 15.0),
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                  width: 60.0,
                  height: 50.0,
                  decoration: BoxDecoration(
                    color: Burnt.imgPlaceholderColor,
                    image: DecorationImage(
                      image: NetworkImage(store.coverImage),
                      fit: BoxFit.cover,
                    ),
                  )),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(store.name, style: TextStyle(fontSize: 18.0, fontWeight: Burnt.fontBold)),
                    Text(store.location != null ? store.location : store.suburb, style: TextStyle(fontSize: 14.0)),
                    Text(store.cuisines.join(', '), style: TextStyle(fontSize: 14.0)),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _content() {
    Function(List<Asset>) onSelectImages = (photos) {
      setState(() {
        images = photos;
        imageData = List.generate(photos.length, (i) => null, growable: false);
      });
      _loadImages(photos);
    };
    return Builder(
      builder: (context) => Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(children: <Widget>[
                  _overallQuestion(),
                  _tasteQuestion(),
                  _serviceQuestion(),
                  _valueQuestion(),
                  _ambienceQuestion(),
                  Padding(
                    padding: EdgeInsets.only(top: 20.0, bottom: 30.0),
                    child: PhotoSelector(images: imageData, onSelectImages: onSelectImages),
                  ),
                  Container(
                    width: 300.0,
                    padding: EdgeInsets.only(bottom: 30.0),
                    child: TextField(
                      onChanged: (text) {
                        setState(() {
                          reviewBody = text;
                        });
                      },
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Add your thoughts here',
                        hintStyle: TextStyle(color: Burnt.hintTextColor),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Burnt.lightGrey)),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Burnt.primaryLight, width: 1.0)),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
              ),
              _submitButton(context),
            ],
          ),
    );
  }

  Widget _toastQuestion(
    String question,
    Function onTap,
    Score currentScore,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(question, style: TextStyle(fontSize: 18.0)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _toastButton(Score.bad, onTap, currentScore == Score.bad),
              _toastButton(Score.okay, onTap, currentScore == Score.okay),
              _toastButton(Score.good, onTap, currentScore == Score.good),
            ],
          )
        ],
      ),
    );
  }

  Widget _overallQuestion() {
    Function onTap = (Score score) {
      setState(() {
        overallScore = score;
      });
    };
    return _toastQuestion('How was it overall?', onTap, overallScore);
  }

  Widget _tasteQuestion() {
    Function onTap = (Score score) {
      setState(() {
        tasteScore = score;
      });
    };
    return _toastQuestion('Was it delicious?', onTap, tasteScore);
  }

  Widget _serviceQuestion() {
    Function onTap = (Score score) {
      setState(() {
        serviceScore = score;
      });
    };
    return _toastQuestion('How was the service?', onTap, serviceScore);
  }

  Widget _valueQuestion() {
    Function onTap = (Score score) {
      setState(() {
        valueScore = score;
      });
    };
    return _toastQuestion('Was it good value?', onTap, valueScore);
  }

  Widget _ambienceQuestion() {
    Function onTap = (Score score) {
      setState(() {
        ambienceScore = score;
      });
    };
    return _toastQuestion('How was the ambience?', onTap, ambienceScore);
  }

  Widget _toastButton(Score score, Function onTap, bool isSelected) {
    var opacity = isSelected ? 1.0 : 0.6;
    return InkWell(
        onTap: () => onTap(score),
        child: Container(key: UniqueKey(), padding: EdgeInsets.all(10.0), child: ScoreIcon(opacity: opacity, score: score, size: 50.0)),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent);
  }

  bool _isValid(BuildContext context) {
    if (overallScore == null) {
      snack(context, "Select a toast for how it was all over");
      return false;
    }
    if (tasteScore == null) {
      snack(context, "Select a toast for whether it was delicious");
      return false;
    }
    if (serviceScore == null) {
      snack(context, "Select a toast for how the service was");
      return false;
    }
    if (valueScore == null) {
      snack(context, "Select a toast for whether it was good value");
      return false;
    }
    if (ambienceScore == null) {
      snack(context, "Select a toast for how the ambience was");
      return false;
    }
    if ((reviewBody == null || reviewBody.isEmpty) && images.isEmpty) {
      snack(context, "Add some photos or add some thoughts");
      return false;
    }
    return true;
  }

  Future<void> _submit(BuildContext context) async {
    if (!_isValid(context)) return false;

    var newPost = Post(
      type: PostType.review,
      store: store,
      postPhotos: [],
      postReview: PostReview(
          body: reviewBody,
          overallScore: overallScore,
          tasteScore: tasteScore,
          serviceScore: serviceScore,
          valueScore: valueScore,
          ambienceScore: ambienceScore),
      postedBy: me,
    );

    setState(() {
      post = newPost;
      showOverlay = true;
    });
  }

//  Future<bool> _submit(BuildContext context) async {
//    if (!_isValid(context)) return false;
//
//    showDialog(
//      context: context,
//      builder: (BuildContext context) {
//        return AlertDialog(
//          content: CircularProgressIndicator(),
//        );
//      });
//
//    List<String> photoStrings = [];
//    if (images.isNotEmpty) {
//      photoStrings = await _uploadPhotos();
//    }
//
//    var post = Post(
//      type: PostType.review,
//      store: store,
//      postPhotos: photoStrings,
//      postReview: PostReview(
//        body: reviewBody,
//        overallScore: overallScore,
//        tasteScore: tasteScore,
//        serviceScore: serviceScore,
//        valueScore: valueScore,
//        ambienceScore: ambienceScore),
//      postedBy: me,
//    );
//
//    var result = await PostService.submitReviewPost(post);
//    if (result != null) {
//      fetchPostsByStoreId(store.id);
//      Navigator.popUntil(context, ModalRoute.withName(MainRoutes.root));
//      Navigator.push(context, MaterialPageRoute(builder: (_) => StoreScreen(storeId: store.id)));
//      return true;
//    } else {
//      snack(context, "Oops! Something went wrong, please try again");
//      return false;
//    }
//  }

  _submitButton(BuildContext context) {
    return InkWell(
      onTap: () {
        _submit(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(2.0)),
            gradient: LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              stops: [0, 0.6, 1.0],
              colors: [Color(0xFFFFAB40), Color(0xFFFFAB40), Color(0xFFFFC86B)],
            )),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[Text('SUBMIT', style: TextStyle(fontSize: 20.0, color: Colors.white, letterSpacing: 3.0))],
        ),
      ),
    );
  }

//  Future<List<String>> _uploadPhotos() async {
//    String timestamp = "${DateTime.now().millisecondsSinceEpoch}";
//    List<ByteData> byteData = await Future.wait(images.map((a) => _getByteData(a)));
//    List<Tuple2<StorageUploadTask, StorageReference>> tasks = byteData.map((bd) {
//      String fileName = "$timestamp-${Random().nextInt(10000)}.jpg";
//      StorageReference ref = FirebaseStorage.instance.ref().child("reviews/post-photos/$fileName");
//      return Tuple2(ref.putData(bd.buffer.asUint8List(), StorageMetadata(customMetadata: {'secret': 'firebase'})), ref);
//    }).toList(growable: false);
//
//    List<String> photoUrls = [];
//    await Future.forEach(tasks, (t) async {
//      await t.item1.onComplete;
//      if (t.item1.isSuccessful) {
//        photoUrls.add(await t.item2.getDownloadURL());
//      }
//    });
//
//    return photoUrls;
//  }

//  Future<ByteData> _getByteData(Asset asset) async {
//    int quality = 100;
//    ByteData byteData = await asset.requestOriginal();
//    int size = byteData.lengthInBytes;
//    int fileSizeKb = (size - (size % 1000)) ~/ 1000;
//    if (fileSizeKb > 20000) {
//      while (size > 500000 && quality > 0) {
//        byteData = await asset.requestOriginal(quality: quality);
//        size = byteData.lengthInBytes;
//        quality = quality - 10;
//      }
//    } else if (fileSizeKb > 6000) {
//      byteData = await asset.requestOriginal(quality: 20);
//    } else if (fileSizeKb > 4000) {
//      byteData = await asset.requestOriginal(quality: 30);
//    } else if (fileSizeKb > 2000) {
//      byteData = await asset.requestOriginal(quality: 60);
//    } else if (fileSizeKb > 500) {
//      byteData = await asset.requestOriginal(quality: 80);
//    } else {
//      byteData = await asset.requestOriginal(quality: 90);
//    }
//    return byteData;
//  }

  _loadImages(photos) async {
    images.asMap().forEach((i, image) async {
      await image.requestOriginal(quality: 80);
      imageData[i] = image.imageData.buffer.asUint8List();
      setState(() {
        imageData = imageData;
      });
    });
  }
}

class _Props {
  final bool isLoggedIn;
  final User me;
  final Function fetchPostsByStoreId;

  _Props({
    this.isLoggedIn,
    this.me,
    this.fetchPostsByStoreId,
  });

  static fromStore(Store<AppState> store) {
    return _Props(
      isLoggedIn: store.state.me.user != null,
      me: store.state.me.user,
      fetchPostsByStoreId: (storeId) => store.dispatch(FetchPostsByStoreIdRequest(storeId)),
    );
  }
}
