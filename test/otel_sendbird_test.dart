// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_sendbird/otel_sendbird.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_sendbird-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('sendUserMessage records channel + mentions + delivery', () async {
    await tracedSendbird<String>(
      operation: 'sendUserMessage',
      invoke: () async => const SendbirdCallResult(
        value: 'ok',
        result: SendbirdResult(
          appId: 'app_1',
          userId: 'u_1',
          channelUrl: 'sendbird_group_channel_42',
          channelType: 'group',
          messageId: 'm_1',
          messageType: 'MESG',
          mentionedUserCount: 2,
          deliveryStatus: 'sent',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('sendbird sendUserMessage')!);
    expect(a['sendbird.channel.type'], 'group');
    expect(a['sendbird.message.mentioned_user.count'], 2);
    expect(a['sendbird.message.delivery_status'], 'sent');
  });

  test('failed delivery sets span error', () async {
    await tracedSendbird<String>(
      operation: 'sendUserMessage',
      invoke: () async => const SendbirdCallResult(
        value: 'ok',
        result: SendbirdResult(
          deliveryStatus: 'failed',
          errorCode: 800101,
        ),
      ),
    );
    expect(
      spans.findSpanByName('sendbird sendUserMessage')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutSendbirdInstrumentationAsync(() async {
      await tracedSendbird<String>(
        operation: 'connect',
        invoke: () async => const SendbirdCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('sendbird '), isEmpty);
  });
}
