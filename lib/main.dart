import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Social Media Feed',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: FeedScreen(),
    );
  }
}

class FeedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Social Feed',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white70,
        centerTitle: true,
        elevation: 6,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 110,
            child: CupertinoScrollbar(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                children: [
                  storyItem('https://media.giphy.com/media/3o7abKhOpu0NwenH3O/giphy.gif', 'You'),
                  storyItem('https://media.giphy.com/media/l0HlOvJ7yaacpuSas/giphy.gif', 'Alicia'),
                  storyItem('https://media.giphy.com/media/xT9IgDEI1iZyb2wqo8/giphy.gif', 'Denny'),
                  storyItem('https://media.giphy.com/media/26BRuo6sLetdllPAQ/giphy.gif', 'Smit'),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: PostList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePostScreen()),
          );
        },
        child: Icon(Icons.add, size: 32),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget storyItem(String imageUrl, String name) {
    return Container(
      width: 80,
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(imageUrl),
          ),
          SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class PostList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostItem(post: post);
          },
        );
      },
    );
  }
}

class PostItem extends StatelessWidget {
  final QueryDocumentSnapshot post;

  PostItem({required this.post});

  @override
  Widget build(BuildContext context) {
    Timestamp timestamp = post['timestamp'];
    DateTime dateTime = timestamp.toDate();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);

    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Posted on: $formattedDate',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            if (post['type'] == 'text')
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  post['content'],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ),
            if (post['type'] == 'image')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CachedNetworkImage(
                    imageUrl: post['content'],
                    placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => Icon(Icons.error, color: Colors.red),
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  if (post['description'] != null && post['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        post['description'],
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ),
                ],
              ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up_alt_outlined, color: Colors.blue),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(post.id)
                            .update({'likes': (post['likes'] ?? 0) + 1});
                      },
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(post.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('0');
                        }
                        final likes = snapshot.data?['likes'] ?? 0;
                        return Text(
                          '$likes',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.comment_outlined, color: Colors.blue),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentScreen(postId: post.id),
                          ),
                        );
                      },
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(post.id)
                          .collection('comments')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('0');
                        }
                        final commentsCount = snapshot.data?.docs.length ?? 0;
                        return Text(
                          '$commentsCount',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        );
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined, color: Colors.blue),
                  onPressed: () {
                    String content;
                    if (post['type'] == 'image') {
                      String description = post['description'] ?? 'No description';
                      content = '**$description**\n${post['content']}';
                    } else {
                      content = post['content'] ?? 'No content';
                    }
                    Share.share(content);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _postType = 'text'; // Default post type
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Post'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post Type Selector
            DropdownButton<String>(
              value: _postType,
              onChanged: (value) {
                setState(() {
                  _postType = value!;
                });
              },
              items: [
                DropdownMenuItem(value: 'text', child: Text('Text Post')),
                DropdownMenuItem(value: 'image', child: Text('Image Post')),
              ],
            ),
            if (_postType == 'text')
              TextField(
                controller: _contentController,
                decoration: InputDecoration(hintText: 'Write something...'),
                maxLines: 4,
              ),
            if (_postType == 'image') ...[
              TextField(
                controller: _contentController,
                decoration: InputDecoration(hintText: 'Image URL'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(hintText: 'Image Description'),
              ),
            ],
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _createPost,
                    child: Text('Post'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Content is required'),
      ));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'content': _contentController.text,
        'description': _descriptionController.text,
        'timestamp': Timestamp.now(),
        'type': _postType,
        'likes': 0,
      });
      Navigator.pop(context);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to create post'),
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class CommentScreen extends StatefulWidget {
  final String postId;

  CommentScreen({required this.postId});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comments'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Comments List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(widget.postId)
                    .collection('comments')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data?.docs ?? [];
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return ListTile(
                        title: Text(comment['text']),
                        subtitle: Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(
                            comment['timestamp'].toDate(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Comment Input Field
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Write a comment...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.blue),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to add a new comment
  Future<void> _addComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'text': commentText,
        'timestamp': Timestamp.now(),
      });

      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Comment added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add comment!')),
      );
    }
  }
}
