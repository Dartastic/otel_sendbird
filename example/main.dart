// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_sendbird/otel_sendbird.dart';

/// Traces Sendbird Chat calls with OpenTelemetry.
///
/// `otel_sendbird` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Sendbird Chat call in
/// [tracedSendbird]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'sendbird-example');

  // Wraps a Sendbird Chat call in a CLIENT span.
  final sendbirdId = await tracedSendbird<String>(
    operation: 'create',
    invoke: () async {
      // Make the Sendbird Chat call here, then report what it returned.
      const id = 'sendbird_8f3a2c';
      return const SendbirdCallResult(
          value: id,
          result: SendbirdResult(
              appId: 'app_8f3a2c',
              userId: 'user_8f3a2c',
              channelUrl: 'sendbird_open_channel_*',
              channelType: 'open',
              messageId: 'message_8f3a2c',
              messageType: 'MESG',
              customType: 'standard',
              fileSizeBytes: 512,
              mentionedUserCount: 3,
              threadParentId: 'threadparent_8f3a2c',
              deliveryStatus: 'pending',
              connectionState: 'connected',
              unreadCount: 3,
              errorCode: 1,
              statusCode: 201));
    },
  );
  OTelLog.info('tracedSendbird create returned $sendbirdId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutSendbirdInstrumentationAsync.
  await runWithoutSendbirdInstrumentationAsync(
    () => tracedSendbird<String>(
      operation: 'create',
      invoke: () async {
        const id = 'sendbird_8f3a2c';
        return const SendbirdCallResult(
            value: id,
            result: SendbirdResult(
                appId: 'app_8f3a2c',
                userId: 'user_8f3a2c',
                channelUrl: 'sendbird_open_channel_*',
                channelType: 'open',
                messageId: 'message_8f3a2c',
                messageType: 'MESG',
                customType: 'standard',
                fileSizeBytes: 512,
                mentionedUserCount: 3,
                threadParentId: 'threadparent_8f3a2c',
                deliveryStatus: 'pending',
                connectionState: 'connected',
                unreadCount: 3,
                errorCode: 1,
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
