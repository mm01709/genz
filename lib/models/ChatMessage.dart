/*
* Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License").
* You may not use this file except in compliance with the License.
* A copy of the License is located at
*
*  http://aws.amazon.com/apache2.0
*
* or in the "license" file accompanying this file. This file is distributed
* on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
* express or implied. See the License for the specific language governing
* permissions and limitations under the License.
*/

// NOTE: This file is generated and may not follow lint rules defined in your app
// Generated files can be excluded from analysis in analysis_options.yaml
// For more info, see: https://dart.dev/guides/language/analysis-options#excluding-code-from-analysis

// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, dead_codepublic_member_api_docs, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'ModelProvider.dart';
import 'package:amplify_core/amplify_core.dart' as amplify_core;


/** This is an auto generated class representing the ChatMessage type in your schema. */
class ChatMessage extends amplify_core.Model {
  static const classType = const _ChatMessageModelType();
  final String id;
  final String? _senderName;
  final String? _senderEmail;
  final String? _clientEmail;
  final String? _text;
  final String? _time;
  final String? _messageType;
  final String? _parentId;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  ChatMessageModelIdentifier get modelIdentifier {
      return ChatMessageModelIdentifier(
        id: id
      );
  }
  
  String? get senderName {
    return _senderName;
  }
  
  String? get senderEmail {
    return _senderEmail;
  }
  
  String get clientEmail {
    try {
      return _clientEmail!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get text {
    return _text;
  }
  
  String? get time {
    return _time;
  }
  
  String? get messageType {
    return _messageType;
  }
  
  String? get parentId {
    return _parentId;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const ChatMessage._internal({required this.id, senderName, senderEmail, required clientEmail, text, time, messageType, parentId, createdAt, updatedAt}): _senderName = senderName, _senderEmail = senderEmail, _clientEmail = clientEmail, _text = text, _time = time, _messageType = messageType, _parentId = parentId, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory ChatMessage({String? id, String? senderName, String? senderEmail, required String clientEmail, String? text, String? time, String? messageType, String? parentId}) {
    return ChatMessage._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      senderName: senderName,
      senderEmail: senderEmail,
      clientEmail: clientEmail,
      text: text,
      time: time,
      messageType: messageType,
      parentId: parentId);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ChatMessage &&
      id == other.id &&
      _senderName == other._senderName &&
      _senderEmail == other._senderEmail &&
      _clientEmail == other._clientEmail &&
      _text == other._text &&
      _time == other._time &&
      _messageType == other._messageType &&
      _parentId == other._parentId;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("ChatMessage {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("senderName=" + "$_senderName" + ", ");
    buffer.write("senderEmail=" + "$_senderEmail" + ", ");
    buffer.write("clientEmail=" + "$_clientEmail" + ", ");
    buffer.write("text=" + "$_text" + ", ");
    buffer.write("time=" + "$_time" + ", ");
    buffer.write("messageType=" + "$_messageType" + ", ");
    buffer.write("parentId=" + "$_parentId" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  ChatMessage copyWith({String? senderName, String? senderEmail, String? clientEmail, String? text, String? time, String? messageType, String? parentId}) {
    return ChatMessage._internal(
      id: id,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      clientEmail: clientEmail ?? this.clientEmail,
      text: text ?? this.text,
      time: time ?? this.time,
      messageType: messageType ?? this.messageType,
      parentId: parentId ?? this.parentId);
  }
  
  ChatMessage copyWithModelFieldValues({
    ModelFieldValue<String?>? senderName,
    ModelFieldValue<String?>? senderEmail,
    ModelFieldValue<String>? clientEmail,
    ModelFieldValue<String?>? text,
    ModelFieldValue<String?>? time,
    ModelFieldValue<String?>? messageType,
    ModelFieldValue<String?>? parentId
  }) {
    return ChatMessage._internal(
      id: id,
      senderName: senderName == null ? this.senderName : senderName.value,
      senderEmail: senderEmail == null ? this.senderEmail : senderEmail.value,
      clientEmail: clientEmail == null ? this.clientEmail : clientEmail.value,
      text: text == null ? this.text : text.value,
      time: time == null ? this.time : time.value,
      messageType: messageType == null ? this.messageType : messageType.value,
      parentId: parentId == null ? this.parentId : parentId.value
    );
  }
  
  ChatMessage.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _senderName = json['senderName'],
      _senderEmail = json['senderEmail'],
      _clientEmail = json['clientEmail'],
      _text = json['text'],
      _time = json['time'],
      _messageType = json['messageType'],
      _parentId = json['parentId'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'senderName': _senderName, 'senderEmail': _senderEmail, 'clientEmail': _clientEmail, 'text': _text, 'time': _time, 'messageType': _messageType, 'parentId': _parentId, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'senderName': _senderName,
    'senderEmail': _senderEmail,
    'clientEmail': _clientEmail,
    'text': _text,
    'time': _time,
    'messageType': _messageType,
    'parentId': _parentId,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<ChatMessageModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<ChatMessageModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final SENDERNAME = amplify_core.QueryField(fieldName: "senderName");
  static final SENDEREMAIL = amplify_core.QueryField(fieldName: "senderEmail");
  static final CLIENTEMAIL = amplify_core.QueryField(fieldName: "clientEmail");
  static final TEXT = amplify_core.QueryField(fieldName: "text");
  static final TIME = amplify_core.QueryField(fieldName: "time");
  static final MESSAGETYPE = amplify_core.QueryField(fieldName: "messageType");
  static final PARENTID = amplify_core.QueryField(fieldName: "parentId");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "ChatMessage";
    modelSchemaDefinition.pluralName = "ChatMessages";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["clientEmail"], name: "byClientEmail"),
      amplify_core.ModelIndex(fields: const ["parentId"], name: "byParent")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ChatMessage.SENDERNAME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ChatMessage.SENDEREMAIL,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ChatMessage.CLIENTEMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ChatMessage.TEXT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ChatMessage.TIME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ChatMessage.MESSAGETYPE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: ChatMessage.PARENTID,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'createdAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.nonQueryField(
      fieldName: 'updatedAt',
      isRequired: false,
      isReadOnly: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
    ));
  });
}

class _ChatMessageModelType extends amplify_core.ModelType<ChatMessage> {
  const _ChatMessageModelType();
  
  @override
  ChatMessage fromJson(Map<String, dynamic> jsonData) {
    return ChatMessage.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'ChatMessage';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [ChatMessage] in your schema.
 */
class ChatMessageModelIdentifier implements amplify_core.ModelIdentifier<ChatMessage> {
  final String id;

  /** Create an instance of ChatMessageModelIdentifier using [id] the primary key. */
  const ChatMessageModelIdentifier({
    required this.id});
  
  @override
  Map<String, dynamic> serializeAsMap() => (<String, dynamic>{
    'id': id
  });
  
  @override
  List<Map<String, dynamic>> serializeAsList() => serializeAsMap()
    .entries
    .map((entry) => (<String, dynamic>{ entry.key: entry.value }))
    .toList();
  
  @override
  String serializeAsString() => serializeAsMap().values.join('#');
  
  @override
  String toString() => 'ChatMessageModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is ChatMessageModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}