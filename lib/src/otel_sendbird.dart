// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_sendbird_suppression.dart';

const _tracerName = 'dartastic_otel_libs_sendbird';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class SendbirdResult {
  /// Creates a result.
  const SendbirdResult({
    this.appId,
    this.userId,
    this.channelUrl,
    this.channelType,
    this.messageId,
    this.messageType,
    this.customType,
    this.fileSizeBytes,
    this.mentionedUserCount,
    this.threadParentId,
    this.deliveryStatus,
    this.connectionState,
    this.unreadCount,
    this.errorCode,
    this.statusCode,
  });

  /// Sendbird application id.
  final String? appId;

  final String? userId;

  /// `sendbird_open_channel_*` / `sendbird_group_channel_*` /
  /// `feed_channel_*`.
  final String? channelUrl;

  /// `open`, `group`, `feed`.
  final String? channelType;

  final String? messageId;

  /// `MESG` (user text), `FILE`, `ADMM` (admin).
  final String? messageType;

  /// Developer-defined message category.
  final String? customType;

  /// File payload size in bytes (FileMessage).
  final int? fileSizeBytes;

  final int? mentionedUserCount;
  final String? threadParentId;

  /// `pending`, `sent`, `delivered`, `read`, `failed`.
  final String? deliveryStatus;

  /// `connected`, `connecting`, `closed`, `reconnecting`.
  final String? connectionState;

  final int? unreadCount;

  /// Sendbird error code (e.g. 800101 message_text_too_long,
  /// 800220 user_blocked, 400201 not_authorized).
  final int? errorCode;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class SendbirdCallResult<T> {
  /// Creates a call result.
  const SendbirdCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final SendbirdResult? result;
}

/// Wraps a Sendbird Chat call in a CLIENT span. [operation] is one of
/// `connect`, `disconnect`, `setBackgroundState`, `setForegroundState`,
/// `createOpenChannel`, `createGroupChannel`, `enterChannel`,
/// `exitChannel`, `freezeChannel`, `unfreezeChannel`,
/// `sendUserMessage`, `sendFileMessage`, `updateMessage`,
/// `deleteMessage`, `markAsRead`, `markAsDelivered`,
/// `createThreadInfo`, `getThreadedMessages`, `inviteUsers`,
/// `acceptInvitation`, `addOperators`, `muteUser`,
/// `banUser`, `reportMessage`, `setPushTriggerOption`,
/// `registerPushToken`, `unregisterPushToken`, `getTotalUnreadMessageCount`.
Future<T> tracedSendbird<T>({
  required String operation,
  required Future<SendbirdCallResult<T>> Function() invoke,
}) async {
  if (sendbirdInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'sendbird',
    'rpc.method': operation,
    'sendbird.operation': operation,
  };

  final span = _tracer().startSpan(
    'sendbird $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.appId != null) {
        extras.add(OTelAPI.attributeString('sendbird.app.id', res.appId!));
      }
      if (res.userId != null) {
        extras.add(OTelAPI.attributeString('sendbird.user.id', res.userId!));
      }
      if (res.channelUrl != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.channel.url',
          res.channelUrl!,
        ));
      }
      if (res.channelType != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.channel.type',
          res.channelType!,
        ));
      }
      if (res.messageId != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.message.id',
          res.messageId!,
        ));
      }
      if (res.messageType != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.message.type',
          res.messageType!,
        ));
      }
      if (res.customType != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.message.custom_type',
          res.customType!,
        ));
      }
      if (res.fileSizeBytes != null) {
        extras.add(OTelAPI.attributeInt(
          'sendbird.file.size_bytes',
          res.fileSizeBytes!,
        ));
      }
      if (res.mentionedUserCount != null) {
        extras.add(OTelAPI.attributeInt(
          'sendbird.message.mentioned_user.count',
          res.mentionedUserCount!,
        ));
      }
      if (res.threadParentId != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.thread.parent_id',
          res.threadParentId!,
        ));
      }
      if (res.deliveryStatus != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.message.delivery_status',
          res.deliveryStatus!,
        ));
        if (res.deliveryStatus == 'failed') {
          span.setStatus(
            SpanStatusCode.Error,
            'Sendbird message delivery failed',
          );
        }
      }
      if (res.connectionState != null) {
        extras.add(OTelAPI.attributeString(
          'sendbird.connection.state',
          res.connectionState!,
        ));
      }
      if (res.unreadCount != null) {
        extras.add(OTelAPI.attributeInt(
          'sendbird.unread.count',
          res.unreadCount!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTelAPI.attributeInt(
          'sendbird.error.code',
          res.errorCode!,
        ));
        span.setStatus(
          SpanStatusCode.Error,
          'Sendbird error ${res.errorCode}',
        );
      }
      if (res.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Sendbird HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
