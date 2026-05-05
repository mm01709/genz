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


/** This is an auto generated class representing the UserProfile type in your schema. */
class UserProfile extends amplify_core.Model {
  static const classType = const _UserProfileModelType();
  final String id;
  final String? _email;
  final String? _name;
  final String? _image;
  final String? _type;
  final bool? _chatEnabled;
  final amplify_core.TemporalDateTime? _lastUpdated;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  UserProfileModelIdentifier get modelIdentifier {
      return UserProfileModelIdentifier(
        id: id
      );
  }
  
  String get email {
    try {
      return _email!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get name {
    return _name;
  }
  
  String? get image {
    return _image;
  }
  
  String? get type {
    return _type;
  }
  
  bool? get chatEnabled {
    return _chatEnabled;
  }
  
  amplify_core.TemporalDateTime? get lastUpdated {
    return _lastUpdated;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const UserProfile._internal({required this.id, required email, name, image, type, chatEnabled, lastUpdated, createdAt, updatedAt}): _email = email, _name = name, _image = image, _type = type, _chatEnabled = chatEnabled, _lastUpdated = lastUpdated, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory UserProfile({String? id, required String email, String? name, String? image, String? type, bool? chatEnabled, amplify_core.TemporalDateTime? lastUpdated}) {
    return UserProfile._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      email: email,
      name: name,
      image: image,
      type: type,
      chatEnabled: chatEnabled,
      lastUpdated: lastUpdated);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UserProfile &&
      id == other.id &&
      _email == other._email &&
      _name == other._name &&
      _image == other._image &&
      _type == other._type &&
      _chatEnabled == other._chatEnabled &&
      _lastUpdated == other._lastUpdated;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("UserProfile {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("email=" + "$_email" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("image=" + "$_image" + ", ");
    buffer.write("type=" + "$_type" + ", ");
    buffer.write("chatEnabled=" + (_chatEnabled != null ? _chatEnabled!.toString() : "null") + ", ");
    buffer.write("lastUpdated=" + (_lastUpdated != null ? _lastUpdated!.format() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  UserProfile copyWith({String? email, String? name, String? image, String? type, bool? chatEnabled, amplify_core.TemporalDateTime? lastUpdated}) {
    return UserProfile._internal(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      image: image ?? this.image,
      type: type ?? this.type,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated);
  }
  
  UserProfile copyWithModelFieldValues({
    ModelFieldValue<String>? email,
    ModelFieldValue<String?>? name,
    ModelFieldValue<String?>? image,
    ModelFieldValue<String?>? type,
    ModelFieldValue<bool?>? chatEnabled,
    ModelFieldValue<amplify_core.TemporalDateTime?>? lastUpdated
  }) {
    return UserProfile._internal(
      id: id,
      email: email == null ? this.email : email.value,
      name: name == null ? this.name : name.value,
      image: image == null ? this.image : image.value,
      type: type == null ? this.type : type.value,
      chatEnabled: chatEnabled == null ? this.chatEnabled : chatEnabled.value,
      lastUpdated: lastUpdated == null ? this.lastUpdated : lastUpdated.value
    );
  }
  
  UserProfile.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _email = json['email'],
      _name = json['name'],
      _image = json['image'],
      _type = json['type'],
      _chatEnabled = json['chatEnabled'],
      _lastUpdated = json['lastUpdated'] != null ? amplify_core.TemporalDateTime.fromString(json['lastUpdated']) : null,
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'email': _email, 'name': _name, 'image': _image, 'type': _type, 'chatEnabled': _chatEnabled, 'lastUpdated': _lastUpdated?.format(), 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'email': _email,
    'name': _name,
    'image': _image,
    'type': _type,
    'chatEnabled': _chatEnabled,
    'lastUpdated': _lastUpdated,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<UserProfileModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<UserProfileModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final EMAIL = amplify_core.QueryField(fieldName: "email");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final IMAGE = amplify_core.QueryField(fieldName: "image");
  static final TYPE = amplify_core.QueryField(fieldName: "type");
  static final CHATENABLED = amplify_core.QueryField(fieldName: "chatEnabled");
  static final LASTUPDATED = amplify_core.QueryField(fieldName: "lastUpdated");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "UserProfile";
    modelSchemaDefinition.pluralName = "UserProfiles";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE
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
      amplify_core.ModelIndex(fields: const ["email"], name: "byEmail")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserProfile.EMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserProfile.NAME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserProfile.IMAGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserProfile.TYPE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserProfile.CHATENABLED,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: UserProfile.LASTUPDATED,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)
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

class _UserProfileModelType extends amplify_core.ModelType<UserProfile> {
  const _UserProfileModelType();
  
  @override
  UserProfile fromJson(Map<String, dynamic> jsonData) {
    return UserProfile.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'UserProfile';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [UserProfile] in your schema.
 */
class UserProfileModelIdentifier implements amplify_core.ModelIdentifier<UserProfile> {
  final String id;

  /** Create an instance of UserProfileModelIdentifier using [id] the primary key. */
  const UserProfileModelIdentifier({
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
  String toString() => 'UserProfileModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is UserProfileModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}