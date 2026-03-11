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


/** This is an auto generated class representing the AppNotification type in your schema. */
class AppNotification extends amplify_core.Model {
  static const classType = const _AppNotificationModelType();
  final String id;
  final String? _clientEmail;
  final String? _title;
  final String? _body;
  final String? _type;
  final String? _time;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  AppNotificationModelIdentifier get modelIdentifier {
      return AppNotificationModelIdentifier(
        id: id
      );
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
  
  String? get title {
    return _title;
  }
  
  String? get body {
    return _body;
  }
  
  String? get type {
    return _type;
  }
  
  String? get time {
    return _time;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const AppNotification._internal({required this.id, required clientEmail, title, body, type, time, createdAt, updatedAt}): _clientEmail = clientEmail, _title = title, _body = body, _type = type, _time = time, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory AppNotification({String? id, required String clientEmail, String? title, String? body, String? type, String? time}) {
    return AppNotification._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      clientEmail: clientEmail,
      title: title,
      body: body,
      type: type,
      time: time);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppNotification &&
      id == other.id &&
      _clientEmail == other._clientEmail &&
      _title == other._title &&
      _body == other._body &&
      _type == other._type &&
      _time == other._time;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("AppNotification {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("clientEmail=" + "$_clientEmail" + ", ");
    buffer.write("title=" + "$_title" + ", ");
    buffer.write("body=" + "$_body" + ", ");
    buffer.write("type=" + "$_type" + ", ");
    buffer.write("time=" + "$_time" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  AppNotification copyWith({String? clientEmail, String? title, String? body, String? type, String? time}) {
    return AppNotification._internal(
      id: id,
      clientEmail: clientEmail ?? this.clientEmail,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      time: time ?? this.time);
  }
  
  AppNotification copyWithModelFieldValues({
    ModelFieldValue<String>? clientEmail,
    ModelFieldValue<String?>? title,
    ModelFieldValue<String?>? body,
    ModelFieldValue<String?>? type,
    ModelFieldValue<String?>? time
  }) {
    return AppNotification._internal(
      id: id,
      clientEmail: clientEmail == null ? this.clientEmail : clientEmail.value,
      title: title == null ? this.title : title.value,
      body: body == null ? this.body : body.value,
      type: type == null ? this.type : type.value,
      time: time == null ? this.time : time.value
    );
  }
  
  AppNotification.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _clientEmail = json['clientEmail'],
      _title = json['title'],
      _body = json['body'],
      _type = json['type'],
      _time = json['time'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'clientEmail': _clientEmail, 'title': _title, 'body': _body, 'type': _type, 'time': _time, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'clientEmail': _clientEmail,
    'title': _title,
    'body': _body,
    'type': _type,
    'time': _time,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<AppNotificationModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<AppNotificationModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final CLIENTEMAIL = amplify_core.QueryField(fieldName: "clientEmail");
  static final TITLE = amplify_core.QueryField(fieldName: "title");
  static final BODY = amplify_core.QueryField(fieldName: "body");
  static final TYPE = amplify_core.QueryField(fieldName: "type");
  static final TIME = amplify_core.QueryField(fieldName: "time");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "AppNotification";
    modelSchemaDefinition.pluralName = "AppNotifications";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.CREATE
        ]),
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.GROUPS,
        groupClaim: "cognito:groups",
        groups: [ "Employee" ],
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ
        ])
    ];
    
    modelSchemaDefinition.indexes = [
      amplify_core.ModelIndex(fields: const ["clientEmail"], name: "byClientEmail")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppNotification.CLIENTEMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppNotification.TITLE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppNotification.BODY,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppNotification.TYPE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: AppNotification.TIME,
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

class _AppNotificationModelType extends amplify_core.ModelType<AppNotification> {
  const _AppNotificationModelType();
  
  @override
  AppNotification fromJson(Map<String, dynamic> jsonData) {
    return AppNotification.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'AppNotification';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [AppNotification] in your schema.
 */
class AppNotificationModelIdentifier implements amplify_core.ModelIdentifier<AppNotification> {
  final String id;

  /** Create an instance of AppNotificationModelIdentifier using [id] the primary key. */
  const AppNotificationModelIdentifier({
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
  String toString() => 'AppNotificationModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is AppNotificationModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}