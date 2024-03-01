import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zotit/config.dart';
import 'package:zotit/src/providers/login_provider/login_provider.dart';
import 'package:zotit/src/screens/common/components/show_hide_eye.dart';
import 'package:zotit/src/screens/home/note_details.dart';
import 'package:zotit/src/screens/home/providers/home_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:zotit/src/screens/home/providers/note.dart';
import 'package:zotit/src/screens/home/providers/note_text_provider.dart';
import 'package:zotit/src/screens/home/side_drawer.dart';
import 'package:zotit/src/screens/tags/note_tags_s_list.dart';
import 'package:zotit/src/screens/tags/providers/note_tag.dart';
import 'package:zotit/src/utils/httpn.dart';

import '../tags/note_tags_bs.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});
  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _Home();
}

class _Home extends ConsumerState<Home> {
  bool isVisible = true;
  bool isSearching = false;
  NoteTag selectedTag = NoteTag(id: "", name: "default", color: 0xff9e9e9e);
  _submit(context, text, isVisible) async {
    try {
      final res = await httpPost(
        "api/notes",
        {},
        {"text": text, "is_obscure": isVisible},
      );

      if (res.statusCode == 200) {
      } else {
        showDialog<void>(
          context: context,
          builder: (c) {
            return ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: AlertDialog(
                title: const Text('Error'),
                content: Text(res.body),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => {
                      Navigator.pop(context, 'OK'),
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      showDialog<void>(
        context: context,
        builder: (c) {
          return ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: <Widget>[
                TextButton(
                  onPressed: () => {
                    Navigator.pop(context, 'OK'),
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  _shareNote(BuildContext? context, String note) async {
    final box = context?.findRenderObject() as RenderBox?;
    await Scrollable.ensureVisible(
      context!,
      duration: const Duration(seconds: 1), // duration for scrolling time
      alignment: .5, // 0 mean, scroll to the top, 0.5 mean, half
      curve: Curves.easeInOutCubic,
    );
    await Share.share(
      "$note \nShared from https://web.zotit.app",
      subject: "note shared from Zotit | Note anywhere",
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  _updateNote(context, id, String isObScure) async {
    try {
      final res = await httpPut(
        "api/notes",
        {},
        {"id": id, "is_obscure": isObScure},
      );
      if (res.statusCode != 200) {
        showDialog<void>(
          context: context,
          builder: (c) {
            return ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: AlertDialog(
                title: const Text('Error'),
                content: Text(res.body),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => {
                      Navigator.pop(context, 'OK'),
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      showDialog<void>(
        context: context,
        builder: (c) {
          return ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: <Widget>[
                TextButton(
                  onPressed: () => {
                    Navigator.pop(context, 'OK'),
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  _shareNoteWithUser(context, userName, noteId) async {
    if (userName == "") {
      return showDialog<void>(
        context: context,
        builder: (c) {
          return ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: AlertDialog(
              title: const Text('Error'),
              content: const Text("Please enter username of the receiver"),
              actions: <Widget>[
                TextButton(
                  onPressed: () => {
                    Navigator.pop(context, 'OK'),
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    }
    try {
      final res = await httpPost(
        "api/share-note",
        {},
        {"user_name": userName, "note_id": noteId},
      );
      if (res.statusCode == 200) {
        showDialog<void>(
          context: context,
          builder: (c) {
            return ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: AlertDialog(
                title: const Text('Success'),
                content: Text(res.body),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => {
                      rcvrUsernameC.text = "",
                      Navigator.pop(context, 'OK'),
                      Navigator.pop(context, 'OK'),
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
        return;
      } else {
        showDialog<void>(
          context: context,
          builder: (c) {
            return ProviderScope(
              parent: ProviderScope.containerOf(context),
              child: AlertDialog(
                title: const Text('Error'),
                content: Text(res.body),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => {
                      Navigator.pop(context, 'OK'),
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      showDialog<void>(
        context: context,
        builder: (c) {
          return ProviderScope(
            parent: ProviderScope.containerOf(context),
            child: AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: <Widget>[
                TextButton(
                  onPressed: () => {
                    Navigator.pop(context, 'OK'),
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  _shareNoteWithUserBS(context, globalKey, noteEntry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Wrap(
        children: [
          ListTile(
              trailing: ElevatedButton(
                onPressed: () async {
                  _shareNoteWithUser(
                      context, rcvrUsernameC.text, noteEntry.value.id);
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all(const Color(0xFF3A568E)),
                  padding: MaterialStateProperty.all(const EdgeInsets.all(16)),
                ),
                child: const Icon(Icons.share),
              ),
              title: Padding(
                padding: const EdgeInsets.all(2),
                child: TextFormField(
                  controller: rcvrUsernameC,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter zotit username of receiver',
                  ),
                ),
              )),
          ListTile(
            title: ElevatedButton(
              onPressed: () async {
                _shareNote(
                    globalKey.currentContext, noteEntry.value.text.toString());
              },
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(const Color(0xFF3A568E)),
                padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 10)),
              ),
              child: const Text("Search via other apps"),
            ),
          ),
        ],
      ),
    );
  }

  _updateTagBS(context, globalKey, Note noteEntry, int noteIndex) {
    return NoteTagsBS(
      noteTag: noteEntry.tag ?? NoteTag(id: "", name: "", color: 0xff9e9e9e),
      noteId: noteEntry.id,
      noteIndex: noteIndex,
    );
  }

  _deleteNote(context, id, int noteIndex) async {
    return showDialog<void>(
      context: context,
      builder: (c) {
        return ProviderScope(
          parent: ProviderScope.containerOf(context),
          child: AlertDialog(
            title: const Text('Delete this note'),
            content: const Text("Are you sure ?"),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  Navigator.pop(context, 'OK');
                  try {
                    final res = await httpDelete("api/notes", {}, {
                      "id": id,
                    });

                    if (res.statusCode == 200) {
                      ref
                          .watch(noteListProvider.notifier)
                          .deleteLocalNote(noteIndex);
                    } else {
                      showDialog<void>(
                        context: context,
                        builder: (c) {
                          return ProviderScope(
                            parent: ProviderScope.containerOf(context),
                            child: AlertDialog(
                              title: const Text('Error'),
                              content: Text(res.body),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () => {
                                    Navigator.pop(context, 'OK'),
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  } catch (e) {
                    showDialog<void>(
                      context: context,
                      builder: (c) {
                        return ProviderScope(
                          parent: ProviderScope.containerOf(context),
                          child: AlertDialog(
                            title: const Text('Error'),
                            content: Text(e.toString()),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () => {
                                  Navigator.pop(context, 'OK'),
                                },
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  _actionList(BuildContext context, MapEntry<int, Note> noteEntry) {
    final bool isBigScreen = MediaQuery.of(context).size.width > 400;
    if (isBigScreen) {
      return [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: noteEntry.value.text));
          },
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all<Color>(const Color(0xFF3A568E)),
          ),
          icon: const Icon(
            Icons.copy,
            size: 16,
          ),
          label: const Text("Copy"),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute<dynamic>(
              builder: (_) => NoteDetails(
                note: noteEntry.value,
                noteIndex: noteEntry.key,
              ),
            ));
          },
          style: ButtonStyle(
            foregroundColor:
                MaterialStateProperty.all<Color>(const Color(0xFF3A568E)),
          ),
          icon: const Icon(
            Icons.edit_document,
            size: 16,
          ),
          label: const Text("Edit"),
        ),
        ShowHideEye(
            isVisible: !noteEntry.value.is_obscure,
            onChange: (isTrue) async {
              ref.watch(noteListProvider.notifier).updateLocalNote(
                    noteEntry.value.text,
                    !isTrue,
                    noteEntry.key,
                    null,
                    false,
                  );
              await _updateNote(
                  context, noteEntry.value.id, !isTrue ? "true" : "false");
            })
      ];
    } else {
      return [
        IconButton(
          color: const Color(0xFF3A568E),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: noteEntry.value.text));
          },
          icon: const Icon(Icons.copy),
        ),
        IconButton(
            icon: const Icon(Icons.edit_document),
            color: const Color(0xFF3A568E),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute<dynamic>(
                builder: (_) => NoteDetails(
                  note: noteEntry.value,
                  noteIndex: noteEntry.key,
                ),
              ));
            }),
        ShowHideEye(
            isVisible: !noteEntry.value.is_obscure,
            onChange: (isTrue) async {
              ref.watch(noteListProvider.notifier).updateLocalNote(
                    noteEntry.value.text,
                    !isTrue,
                    noteEntry.key,
                    null,
                    false,
                  );
              await _updateNote(
                  context, noteEntry.value.id, !isTrue ? "true" : "false");
            })
      ];
    }
  }

  TextEditingController textC = TextEditingController(text: "");
  TextEditingController searchC = TextEditingController(text: "");
  TextEditingController rcvrUsernameC = TextEditingController(text: "");
  final ScrollController _scrollController = ScrollController();
  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        ref
            .read(noteListProvider.notifier)
            .getNotesByPage(searchC.text, selectedTag.id);
      }
    });
    textC.text = ref.read(noteTextProvider).value ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final loginData = ref.watch(loginTokenProvider.notifier);
    final notesData = ref.watch(noteListProvider);
    final textDataNotifier = ref.watch(noteTextProvider.notifier);
    final textData = ref.read(noteTextProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const SideDrawer(),
      appBar: AppBar(
        title: Row(children: [
          const Text(
            "ZotIt ",
            style: TextStyle(fontFamily: 'Satisfy', fontSize: 30),
          ),
          Gap(10),
          Flexible(
            child: Text(
              "@${loginData.getData().username}",
              style: const TextStyle(
                  fontSize: 14, overflow: TextOverflow.ellipsis),
            ),
          )
        ]),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
              });
              if (!isSearching) {
                searchC.text = "";
                selectedTag = NoteTag(id: "", name: "", color: 0xff9e9e9e);

                final _ = ref.refresh(noteListProvider);
              }
            },
            icon: isSearching
                ? const Icon(Icons.search_off_outlined)
                : const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => ref.refresh(noteListProvider.future),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // floatingActionButtonLocation: ExpandableFab.location,
      // floatingActionButton: ExpandableFab(
      //   openButtonBuilder: RotateFloatingActionButtonBuilder(
      //     child: const Icon(Icons.add),
      //     fabSize: ExpandableFabSize.regular,
      //     foregroundColor: Colors.white,
      //     backgroundColor: const Color(0xFF3A568E),
      //     shape: const CircleBorder(),
      //   ),
      //   closeButtonBuilder: DefaultFloatingActionButtonBuilder(
      //     child: const Icon(Icons.close),
      //     fabSize: ExpandableFabSize.small,
      //     foregroundColor: Colors.white,
      //     backgroundColor: const Color(0xFF3A568E),
      //     shape: const CircleBorder(),
      //   ),
      //   overlayStyle: ExpandableFabOverlayStyle(
      //     // color: Colors.black.withOpacity(0.5),
      //     blur: 5,
      //   ),
      //   onOpen: () {
      //     debugPrint('onOpen');
      //   },
      //   afterOpen: () {
      //     debugPrint('afterOpen');
      //   },
      //   onClose: () {
      //     debugPrint('onClose');
      //   },
      //   afterClose: () {
      //     debugPrint('afterClose');
      //   },
      //   children: [
      //     FloatingActionButton.small(
      //       // shape: const CircleBorder(),
      //       heroTag: null,
      //       backgroundColor: Color(0xFF3A568E),
      //       child: const Icon(Icons.lock),
      //       onPressed: () {},
      //     ),
      //     FloatingActionButton.small(
      //       // shape: const CircleBorder(),
      //       heroTag: null,
      //       backgroundColor: Color(0xFF3A568E),
      //       child: const Icon(Icons.search),
      //       onPressed: () {},
      //     ),
      //     FloatingActionButton.small(
      //       // shape: const CircleBorder(),
      //       heroTag: null,
      //       backgroundColor: Color(0xFF3A568E),
      //       child: const Icon(Icons.share),
      //       onPressed: () {},
      //     ),
      //   ],
      // ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              child: isSearching
                  ? Card(
                      elevation: 2.0,
                      shadowColor: Colors.grey,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10.0,
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              onTapOutside: (b) {
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Search here...',
                                  hintText:
                                      'At least 3 letters required to search'),
                              minLines: 1,
                              maxLines: 20,
                              onChanged: ((value) {
                                if (value.isEmpty) {
                                  selectedTag = NoteTag(
                                      id: "", name: "", color: 0xff9e9e9e);
                                  final _ = ref.refresh(noteListProvider);
                                }
                                if (value.length < 3) {
                                  return;
                                }
                                searchC.text = value;
                                ref
                                    .read(noteListProvider.notifier)
                                    .searchNotes(searchC.text, selectedTag.id);
                              }),
                            ),
                            const Divider(),
                            NoteTagSList(
                              noteTagId: "",
                              onSelected: (selectedNoteTag) {
                                if (selectedNoteTag != null) {
                                  setState(() {
                                    selectedTag = selectedNoteTag;
                                  });
                                  ref
                                      .read(noteListProvider.notifier)
                                      .searchNotes(
                                          searchC.text, selectedTag.id);
                                } else {
                                  selectedTag = NoteTag(
                                      id: "", name: "", color: 0xff9e9e9e);
                                  final _ = ref.refresh(noteListProvider);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : Card(
                      elevation: 2.0,
                      shadowColor: Colors.grey,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 6.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 10.0,
                        ),
                        child: Column(
                          children: [
                            // Row(
                            //   children: [
                            //     ShowHideEye(
                            //         isVisible: !isVisible,
                            //         onChange: (isTrue) async {
                            //           setState(() {
                            //             isVisible = !isVisible;
                            //           });
                            //         })
                            //   ],
                            // ),
                            // const Divider(),
                            Row(
                              children: [
                                Expanded(
                                  child: textData.when(
                                    data: (value) => TextFormField(
                                      onTapOutside: (b) {
                                        FocusManager.instance.primaryFocus
                                            ?.unfocus();
                                      },
                                      initialValue: value,
                                      onChanged: (value) async {
                                        textDataNotifier.setText(value);
                                      },
                                      decoration: const InputDecoration(
                                          hintStyle: TextStyle(
                                            fontFamily: 'Satisfy',
                                          ),
                                          border: OutlineInputBorder(),
                                          labelText: 'Zot it',
                                          hintText:
                                              'What needs to be zoted...'),
                                      minLines: 1,
                                      maxLines: 20,
                                    ),
                                    loading: () => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    error: (err, stack) => Text('Error: $err'),
                                  ),
                                ),
                                const Gap(10),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (textData.value != '') {
                                      await _submit(
                                          context, textData.value, !isVisible);
                                      textDataNotifier.setText('');
                                      final _ = ref.refresh(noteListProvider);
                                    }
                                  },
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all(
                                          const EdgeInsets.symmetric(
                                              vertical: 20)),
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              const Color(0xFF3A568E))),
                                  child: const Icon(Icons.done),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: notesData.when(
                data: (notes) => ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    controller: _scrollController,
                    children: notes.notes.isNotEmpty
                        ? notes.notes.asMap().entries.map((noteEntry) {
                            final globalKey = GlobalKey();
                            return Card(
                              elevation: 2.0,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 6.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 0.0),
                                dense: true,
                                title: Column(
                                  key: globalKey,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            ActionChip(
                                              padding: const EdgeInsets.all(2),
                                              shape:
                                                  const RoundedRectangleBorder(
                                                      side: BorderSide(
                                                          style:
                                                              BorderStyle.none),
                                                      borderRadius:
                                                          BorderRadius.all(
                                                              Radius.circular(
                                                                  20))),
                                              backgroundColor: Color(
                                                  noteEntry.value.tag!.color),
                                              label: Text(
                                                noteEntry.value.tag!.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: useWhiteForeground(
                                                          Color(noteEntry.value
                                                              .tag!.color))
                                                      ? Colors.white
                                                      : Colors.black,
                                                ),
                                              ),
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (context) {
                                                    return _updateTagBS(
                                                        context,
                                                        globalKey,
                                                        noteEntry.value,
                                                        noteEntry.key);
                                                  },
                                                );
                                              },
                                            ),
                                            ..._actionList(context, noteEntry)
                                          ],
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (val) async {
                                            switch (val) {
                                              case "share":
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (context) {
                                                    return _shareNoteWithUserBS(
                                                        context,
                                                        globalKey,
                                                        noteEntry);
                                                  },
                                                );
                                                // _shareNote(globalKey.currentContext, noteEntry.value.text.toString());
                                                break;
                                              case "delete":
                                                await _deleteNote(
                                                  context,
                                                  noteEntry.value.id,
                                                  noteEntry.key,
                                                );
                                                break;

                                              default:
                                            }
                                          },
                                          itemBuilder: (BuildContext context) {
                                            return [
                                              const PopupMenuItem<String>(
                                                value: "share",
                                                child: Row(children: [
                                                  Icon(
                                                    Icons.share,
                                                    color: Color(0xFF3A568E),
                                                  ),
                                                  Gap(10),
                                                  Text(
                                                    "Share",
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF3A568E)),
                                                  )
                                                ]),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: "delete",
                                                child: Row(children: [
                                                  Icon(Icons.delete,
                                                      color: Color(0xFF3A568E)),
                                                  Gap(10),
                                                  Text(
                                                    "Delete",
                                                    style: TextStyle(
                                                        color:
                                                            Color(0xFF3A568E)),
                                                  )
                                                ]),
                                              ),
                                            ];
                                          },
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                  ],
                                ),
                                subtitle: noteEntry.value.is_obscure
                                    ? ImageFiltered(
                                        imageFilter: ImageFilter.blur(
                                            sigmaX: 4, sigmaY: 4),
                                        child: Linkify(
                                          text: noteEntry.value.text,
                                          options: const LinkifyOptions(
                                              humanize: false),
                                          linkStyle:
                                              const TextStyle(fontSize: 16),
                                        ),
                                      )
                                    : Linkify(
                                        text: noteEntry.value.text,
                                        options: const LinkifyOptions(
                                            humanize: false),
                                        linkStyle:
                                            const TextStyle(fontSize: 16),
                                        onOpen: (LinkableElement link) async {
                                          if (!await launchUrl(
                                              Uri.parse(link.url))) {
                                            throw Exception(
                                                'Could not launch ${link.url}');
                                          }
                                        },
                                      ),
                              ),
                            );
                          }).toList()
                        : [
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(50),
                                child: Text(
                                  "No Notes Found",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ]),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, stack) => Text('Error: $err'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
