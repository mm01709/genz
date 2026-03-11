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


/** This is an auto generated class representing the Studio type in your schema. */
class Studio extends amplify_core.Model {
  static const classType = const _StudioModelType();
  final String id;
  final String? _name;
  final String? _type;
  final int? _pricePerHour;
  final String? _description;
  final String? _image;
  final bool? _available;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  StudioModelIdentifier get modelIdentifier {
      return StudioModelIdentifier(
        id: id
      );
  }
  
  String get name {
    try {
      return _name!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get type {
    try {
      return _type!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  int get pricePerHour {
    try {
      return _pricePerHour!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get description {
    return _description;
  }
  
  String? get image {
    return _image;
  }
  
  bool? get available {
    return _available;
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const Studio._internal({required this.id, required name, required type, required pricePerHour, description, image, available, createdAt, updatedAt}): _name = name, _type = type, _pricePerHour = pricePerHour, _description = description, _image = image, _available = available, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory Studio({String? id, required String name, required String type, required int pricePerHour, String? description, String? image, bool? available}) {
    return Studio._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      name: name,
      type: type,
      pricePerHour: pricePerHour,
      description: description,
      image: image,
      available: available);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Studio &&
      id == other.id &&
      _name == other._name &&
      _type == other._type &&
      _pricePerHour == other._pricePerHour &&
      _description == other._description &&
      _image == other._image &&
      _available == other._available;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("Studio {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("name=" + "$_name" + ", ");
    buffer.write("type=" + "$_type" + ", ");
    buffer.write("pricePerHour=" + (_pricePerHour != null ? _pricePerHour!.toString() : "null") + ", ");
    buffer.write("description=" + "$_description" + ", ");
    buffer.write("image=" + "$_image" + ", ");
    buffer.write("available=" + (_available != null ? _available!.toString() : "null") + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  Studio copyWith({String? name, String? type, int? pricePerHour, String? description, String? image, bool? available}) {
    return Studio._internal(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      description: description ?? this.description,
      image: image ?? this.image,
      available: available ?? this.available);
  }
  
  Studio copyWithModelFieldValues({
    ModelFieldValue<String>? name,
    ModelFieldValue<String>? type,
    ModelFieldValue<int>? pricePerHour,
    ModelFieldValue<String?>? description,
    ModelFieldValue<String?>? image,
    ModelFieldValue<bool?>? available
  }) {
    return Studio._internal(
      id: id,
      name: name == null ? this.name : name.value,
      type: type == null ? this.type : type.value,
      pricePerHour: pricePerHour == null ? this.pricePerHour : pricePerHour.value,
      description: description == null ? this.description : description.value,
      image: image == null ? this.image : image.value,
      available: available == null ? this.available : available.value
    );
  }
  
  Studio.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _name = json['name'],
      _type = json['type'],
      _pricePerHour = (json['pricePerHour'] as num?)?.toInt(),
      _description = json['description'],
      _image = json['image'],
      _available = json['available'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'name': _name, 'type': _type, 'pricePerHour': _pricePerHour, 'description': _description, 'image': _image, 'available': _available, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'name': _name,
    'type': _type,
    'pricePerHour': _pricePerHour,
    'description': _description,
    'image': _image,
    'available': _available,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<StudioModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<StudioModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final NAME = amplify_core.QueryField(fieldName: "name");
  static final TYPE = amplify_core.QueryField(fieldName: "type");
  static final PRICEPERHOUR = amplify_core.QueryField(fieldName: "pricePerHour");
  static final DESCRIPTION = amplify_core.QueryField(fieldName: "description");
  static final IMAGE = amplify_core.QueryField(fieldName: "image");
  static final AVAILABLE = amplify_core.QueryField(fieldName: "available");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "Studio";
    modelSchemaDefinition.pluralName = "Studios";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.READ
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
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Studio.NAME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Studio.TYPE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Studio.PRICEPERHOUR,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Studio.DESCRIPTION,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Studio.IMAGE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: Studio.AVAILABLE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)
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

class _StudioModelType extends amplify_core.ModelType<Studio> {
  const _StudioModelType();
  
  @override
  Studio fromJson(Map<String, dynamic> jsonData) {
    return Studio.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'Studio';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [Studio] in your schema.
 */
class StudioModelIdentifier implements amplify_core.ModelIdentifier<Studio> {
  final String id;

  /** Create an instance of StudioModelIdentifier using [id] the primary key. */
  const StudioModelIdentifier({
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
  String toString() => 'StudioModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is StudioModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}