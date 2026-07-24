import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/store.dart';
import '../../widgets/common.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.orderId}) : support = false;
  const ChatPage.support({super.key})
      : orderId = null,
        support = true;

  final String? orderId;
  final bool support;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  final store = AppStore.I;

  List<ChatMessage> get _messages =>
      widget.support ? store.support : store.chatFor(widget.orderId!);

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    if (widget.support) {
      store.sendSupport(t);
    } else {
      store.sendMessage(widget.orderId!, t);
    }
    _ctrl.clear();
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.I,
      builder: (context, _) {
        final order = widget.support ? null : store.orders.firstWhere((o) => o.id == widget.orderId);
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                widget.support
                    ? Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                        child: Icon(Icons.support_agent_rounded, color: AppColors.primaryDark, size: 22),
                      )
                    : InitialsAvatar(initials: order!.clientName[0], size: 38, color: AppColors.primary),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.support ? 'Поддержка' : order!.clientName,
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink)),
                    Text(widget.support ? 'Обычно отвечаем за пару минут' : order!.clientAddressShort,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            actions: [
              if (!widget.support)
                IconButton(onPressed: () {}, icon: const Icon(Icons.call_rounded, color: AppColors.success)),
            ],
          ),
          body: Column(
            children: [
              if (widget.support) _quickReplies(),
              Expanded(
                child: ListenableBuilder(
                  listenable: store,
                  builder: (context, _) {
                    final msgs = _messages;
                    _scrollToEnd();
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: msgs.length,
                      itemBuilder: (context, i) => _Bubble(msg: msgs[i]),
                    );
                  },
                ),
              ),
              _Composer(ctrl: _ctrl, onSend: _send),
            ],
          ),
        );
      },
    );
  }

  Widget _quickReplies() {
    final chips = ['Проблема с заказом', 'Вопрос о слоте', 'Про выплаты'];
    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: chips
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(c),
                    labelStyle: TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w700, fontSize: 13),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(color: AppColors.line),
                    onPressed: () {
                      _ctrl.text = c;
                      _send();
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg});
  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    if (msg.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Text(msg.text, style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600, fontSize: 12.5)),
        ),
      );
    }
    final me = msg.fromMe;
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: me ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(me ? 18 : 4),
            bottomRight: Radius.circular(me ? 4 : 18),
          ),
          border: me ? null : Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: TextStyle(color: me ? Colors.white : AppColors.ink, fontSize: 15, height: 1.35, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              _time(msg.time),
              style: TextStyle(color: me ? Colors.white70 : AppColors.faint, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _Composer extends StatelessWidget {
  const _Composer({required this.ctrl, required this.onSend});
  final TextEditingController ctrl;
  final VoidCallback onSend;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
              child: TextField(
                controller: ctrl,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Сообщение…',
                  hintStyle: TextStyle(color: AppColors.faint, fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
