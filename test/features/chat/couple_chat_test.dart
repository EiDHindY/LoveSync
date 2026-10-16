import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:love_app/core/providers/app_providers.dart';
import 'package:love_app/core/services/couple_repository.dart';
import 'package:love_app/core/theme/app_theme.dart';
import 'package:love_app/features/chat/domain/chat_message.dart';
import 'package:love_app/features/chat/presentation/dm_chat_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ChatMessage Domain Model Tests', () {
    test('ChatMessage json serialization and deserialization', () {
      final now = DateTime.now();
      final message = ChatMessage(
        id: 'msg-1',
        coupleId: 'couple-100',
        senderId: 'user-a',
        text: 'I love you so much!',
        imageUrl: null,
        isViewOnce: false,
        isViewed: false,
        reactions: {'user-b': '❤️'},
        readAt: null,
        createdAt: now,
      );

      final json = message.toJson();
      expect(json['id'], 'msg-1');
      expect(json['couple_id'], 'couple-100');
      expect(json['sender_id'], 'user-a');
      expect(json['text'], 'I love you so much!');
      expect(json['reactions'], {'user-b': '❤️'});

      final fromJson = ChatMessage.fromJson(json);
      expect(fromJson.id, message.id);
      expect(fromJson.text, message.text);
      expect(fromJson.isMine('user-a'), isTrue);
      expect(fromJson.isMine('user-b'), isFalse);
      expect(fromJson.isImage, isFalse);
    });

    test('ChatMessage view-once photo properties and state', () {
      final now = DateTime.now();
      final photoMsg = ChatMessage(
        id: 'photo-1',
        coupleId: 'couple-100',
        senderId: 'user-b',
        text: 'View-Once Photo',
        imageUrl: 'https://example.com/photo.jpg',
        isViewOnce: true,
        isViewed: false,
        reactions: const {},
        readAt: null,
        createdAt: now,
      );

      expect(photoMsg.isViewOnce, isTrue);
      expect(photoMsg.isViewed, isFalse);
      expect(photoMsg.isImage, isTrue);

      final viewedMsg = photoMsg.copyWith(
        isViewed: true,
        clearImage: true,
      );
      expect(viewedMsg.isViewed, isTrue);
      expect(viewedMsg.isImage, isFalse);
      expect(viewedMsg.isBurned, isTrue);
    });
  });

  group('CoupleRepository Chat State and Logic Tests', () {
    test('Calculates unreadChatCount accurately based on sender and read status', () {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('my-user-id');
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');

      final now = DateTime.now();
      final messages = [
        ChatMessage(
          id: '1',
          coupleId: 'c1',
          senderId: 'my-user-id',
          text: 'Hey there',
          readAt: null,
          createdAt: now.subtract(const Duration(minutes: 10)),
        ),
        ChatMessage(
          id: '2',
          coupleId: 'c1',
          senderId: 'partner-id',
          text: 'Hey babe!',
          readAt: null,
          createdAt: now.subtract(const Duration(minutes: 8)),
        ),
        ChatMessage(
          id: '3',
          coupleId: 'c1',
          senderId: 'partner-id',
          text: 'Can you get wine?',
          readAt: null,
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        ChatMessage(
          id: '4',
          coupleId: 'c1',
          senderId: 'partner-id',
          text: 'Already got it!',
          readAt: now.subtract(const Duration(minutes: 1)),
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
      ];

      repo.setChatMessagesForTesting(messages);

      // Only message 2 and 3 are from partner and unread
      expect(repo.unreadChatCount, 2);

      // Mark messages as read
      repo.markChatMessagesAsRead();
      expect(repo.unreadChatCount, 0);
    });

    test('sendChatMessage enforces rolling 500 messages cap', () async {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('my-user-id');
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');

      // Seed 500 messages
      final initialMessages = List.generate(
        500,
        (i) => ChatMessage(
          id: 'msg-$i',
          coupleId: 'c1',
          senderId: 'my-user-id',
          text: 'Message #$i',
          createdAt: DateTime.now().subtract(Duration(minutes: 500 - i)),
        ),
      );
      repo.setChatMessagesForTesting(initialMessages);
      expect(repo.chatMessages.length, 500);

      // Send 501st message
      await repo.sendChatMessage('Newest message');

      // Cap remains at 500 and oldest message is pruned
      expect(repo.chatMessages.length, 500);
      expect(repo.chatMessages.last.text, 'Newest message');
      expect(repo.chatMessages.first.id, 'msg-1');
    });

    test('reactToChatMessage updates reaction for message', () {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('user-me');
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');

      final msg = ChatMessage(
        id: 'msg-react',
        coupleId: 'c1',
        senderId: 'partner-id',
        text: 'Romantic dinner tonight?',
        createdAt: DateTime.now(),
      );
      repo.setChatMessagesForTesting([msg]);

      repo.reactToChatMessage('msg-react', '❤️');
      expect(repo.chatMessages.first.reactions['user-me'], '❤️');

      // Reacting again with same emoji removes it
      repo.reactToChatMessage('msg-react', '❤️');
      expect(repo.chatMessages.first.reactions.containsKey('user-me'), isFalse);
    });

    test('viewAndBurnPhoto marks photo as viewed and burned', () async {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('user-me');
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');

      final photoMsg = ChatMessage(
        id: 'photo-burn-test',
        coupleId: 'c1',
        senderId: 'partner-id',
        text: 'View-Once Photo',
        imageUrl: 'https://example.com/test.jpg',
        isViewOnce: true,
        isViewed: false,
        createdAt: DateTime.now(),
      );
      repo.setChatMessagesForTesting([photoMsg]);

      expect(repo.chatMessages.first.isViewed, isFalse);

      await repo.viewAndBurnPhoto('photo-burn-test');

      expect(repo.chatMessages.first.isViewed, isTrue);
      expect(repo.chatMessages.first.imageUrl, isNull);
    });

    test('clearChatHistory empties all messages', () async {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('user-me');
      repo.setPartnerForTesting(isPaired: true, partnerName: 'Lola');

      repo.setChatMessagesForTesting([
        ChatMessage(id: '1', coupleId: 'c1', senderId: 'u1', text: 'test', createdAt: DateTime.now()),
      ]);
      expect(repo.chatMessages.isNotEmpty, isTrue);

      await repo.clearChatHistory();
      expect(repo.chatMessages.isEmpty, isTrue);
    });
  });

  group('DmChatView Widget Tests', () {
    testWidgets('Renders chat messages, whispers, and input bar when paired', (tester) async {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('user-me');
      repo.setPartnerForTesting(
        isPaired: true,
        partnerName: 'Lola',
        partnerRole: 'Wife',
      );

      final now = DateTime.now();
      repo.setChatMessagesForTesting([
        ChatMessage(
          id: '1',
          coupleId: 'c1',
          senderId: 'partner-id',
          text: 'Hello sweetheart!',
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        ChatMessage(
          id: '2',
          coupleId: 'c1',
          senderId: 'user-me',
          text: 'Hey Lola! Thinking of you',
          readAt: now,
          createdAt: now.subtract(const Duration(minutes: 2)),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coupleRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: DmChatView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header with partner name
      expect(find.text('Lola'), findsOneWidget);
      expect(find.text('Synced in Realtime'), findsOneWidget);

      // Verify message bubbles
      expect(find.text('Hello sweetheart!'), findsOneWidget);
      expect(find.text('Hey Lola! Thinking of you'), findsOneWidget);

      // Verify input bar
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Entering text and tapping send button sends message', (tester) async {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('user-me');
      repo.setPartnerForTesting(
        isPaired: true,
        partnerName: 'Lola',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coupleRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: DmChatView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter text and tap send
      await tester.enterText(find.byType(TextField), 'I miss you!');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      // Message should now be added to repository
      expect(repo.chatMessages.any((m) => m.text == 'I miss you!'), isTrue);
    });

    testWidgets('Displays view-once photo card with burn status', (tester) async {
      final repo = CoupleRepository();
      repo.setCurrentUserIdForTesting('user-me');
      repo.setPartnerForTesting(
        isPaired: true,
        partnerName: 'Lola',
      );

      final now = DateTime.now();
      repo.setChatMessagesForTesting([
        ChatMessage(
          id: 'vo-unburned',
          coupleId: 'c1',
          senderId: 'partner-id',
          text: 'View-Once Photo',
          imageUrl: 'https://example.com/photo.jpg',
          isViewOnce: true,
          isViewed: false,
          createdAt: now.subtract(const Duration(minutes: 5)),
        ),
        ChatMessage(
          id: 'vo-burned',
          coupleId: 'c1',
          senderId: 'partner-id',
          text: 'View-Once Photo',
          imageUrl: null,
          isViewOnce: true,
          isViewed: true,
          createdAt: now.subtract(const Duration(minutes: 3)),
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coupleRepositoryProvider.overrideWith((ref) => repo),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: DmChatView(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify unburned photo shows View Once Photo prompt
      expect(find.text('View-Once Photo 📸'), findsOneWidget);
      expect(find.text('Tap to view · Burns once closed 🔥'), findsOneWidget);

      // Verify burned photo shows opened status
      expect(find.text('View-Once Photo · Opened'), findsOneWidget);
    });
  });
}
