import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:F4Lab/gitlab_client.dart';
import 'package:F4Lab/widget/comm_ListView.dart';

class PageProjectDetail extends StatefulWidget {
  final String projectName;
  final int projectId;

  PageProjectDetail(this.projectName, this.projectId);

  @override
  State<StatefulWidget> createState() => PageProjectState();
}

class PageProjectState extends State<PageProjectDetail> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Text(widget.projectName),
            bottom:
                TabBar(tabs: [Tab(text: 'Merge Request'), Tab(text: 'CI/CD')]),
          ),
          body: TabBarView(children: [
            _MrTab(widget.projectId),
          ]),
        ));
  }
}

class _MrTab extends CommListWidget {
  final int projectId;

  _MrTab(this.projectId);

  @override
  State<StatefulWidget> createState() => _MrState(projectId);
}

class _MrState extends CommListState {
  final int projectId;

  _MrState(this.projectId)
      : super("projects/$projectId/merge_requests?state=opened");

  @override
  Widget childBuild(BuildContext context, int index) {
    final mr = data[index];
    return _buidlItem(mr);
  }

  Widget _buidlItem(mr) {
    return Card(
        child: GestureDetector(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(mr['title'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                      Text(mr['target_branch'])
                    ],
                  ),
                ),
                mr['merge_status'] == 'can_be_merged'
                    ? Icon(Icons.done_outline, color: Colors.green)
                    : Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                mr['assignee'] != null
                    ? Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: CircleAvatar(
                          radius: 15,
                          backgroundImage: NetworkImage(
                              "${GitlabClient.globalHOST}/uploads/-/system/user/avatar/${mr['assignee']['id']}/avatar.png"),
                        ))
                    : IgnorePointer(),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

class _MrApprove extends StatefulWidget {
  final int projectId;
  final int mrIID;

  _MrApprove(this.projectId, this.mrIID);

  @override
  State<StatefulWidget> createState() => _MrApproveState();
}

class _MrApproveState extends State<_MrApprove> {
  dynamic approve;

  _loadApprove() async {
    final client = GitlabClient.newInstance();
    final data = await client
        .get(
            'projects/${widget.projectId}/merge_requests/${widget.mrIID}/approvals')
        .then((resp) => jsonDecode(utf8.decode(resp.bodyBytes)))
        .whenComplete(client.close);
    if (mounted) {
      setState(() {
        approve = data;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadApprove();
  }

  @override
  Widget build(BuildContext context) {
    return approve == null
        ? IgnorePointer(ignoring: true)
        : Row(children: [
            approve['approved_by'].isNotEmpty
                ? Row(
                    children: <Widget>[
                          const Text('Approved by '),
                        ] +
                        approve['approved_by'].map<Widget>((item) {
                          return Padding(
                              padding: EdgeInsets.all(2),
                              child: CircleAvatar(
                                radius: 10,
                                backgroundImage:
                                    NetworkImage(item['user']['avatar_url']),
                              ));
                        }).toList())
                : IgnorePointer(ignoring: true),
            approve['approvals_left'] > 0
                ? Text("Requires ${approve['approvals_left']} approvals")
                : const IgnorePointer(ignoring: true)
          ]);
  }
}
