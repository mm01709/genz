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


/** This is an auto generated class representing the BookingRequest type in your schema. */
class BookingRequest extends amplify_core.Model {
  static const classType = const _BookingRequestModelType();
  final String id;
  final String? _clientEmail;
  final String? _clientName;
  final String? _clientPhone;
  final String? _studio;
  final String? _date;
  final String? _hours;
  final String? _price;
  final String? _equipment;
  final String? _status;
  final String? _fullStartDateTime;
  final String? _fullEndDateTime;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;
  
  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;
  
  BookingRequestModelIdentifier get modelIdentifier {
      return BookingRequestModelIdentifier(
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
  
  String? get clientName {
    return _clientName;
  }
  
  String? get clientPhone {
    return _clientPhone;
  }
  
  String get studio {
    try {
      return _studio!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get date {
    try {
      return _date!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get hours {
    try {
      return _hours!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get price {
    try {
      return _price!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String? get equipment {
    return _equipment;
  }
  
  String? get status {
    return _status;
  }
  
  String get fullStartDateTime {
    try {
      return _fullStartDateTime!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  String get fullEndDateTime {
    try {
      return _fullEndDateTime!;
    } catch(e) {
      throw amplify_core.AmplifyCodeGenModelException(
          amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
          recoverySuggestion:
            amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
          underlyingException: e.toString()
          );
    }
  }
  
  amplify_core.TemporalDateTime? get createdAt {
    return _createdAt;
  }
  
  amplify_core.TemporalDateTime? get updatedAt {
    return _updatedAt;
  }
  
  const BookingRequest._internal({required this.id, required clientEmail, clientName, clientPhone, required studio, required date, required hours, required price, equipment, status, required fullStartDateTime, required fullEndDateTime, createdAt, updatedAt}): _clientEmail = clientEmail, _clientName = clientName, _clientPhone = clientPhone, _studio = studio, _date = date, _hours = hours, _price = price, _equipment = equipment, _status = status, _fullStartDateTime = fullStartDateTime, _fullEndDateTime = fullEndDateTime, _createdAt = createdAt, _updatedAt = updatedAt;
  
  factory BookingRequest({String? id, required String clientEmail, String? clientName, String? clientPhone, required String studio, required String date, required String hours, required String price, String? equipment, String? status, required String fullStartDateTime, required String fullEndDateTime}) {
    return BookingRequest._internal(
      id: id == null ? amplify_core.UUID.getUUID() : id,
      clientEmail: clientEmail,
      clientName: clientName,
      clientPhone: clientPhone,
      studio: studio,
      date: date,
      hours: hours,
      price: price,
      equipment: equipment,
      status: status,
      fullStartDateTime: fullStartDateTime,
      fullEndDateTime: fullEndDateTime);
  }
  
  bool equals(Object other) {
    return this == other;
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BookingRequest &&
      id == other.id &&
      _clientEmail == other._clientEmail &&
      _clientName == other._clientName &&
      _clientPhone == other._clientPhone &&
      _studio == other._studio &&
      _date == other._date &&
      _hours == other._hours &&
      _price == other._price &&
      _equipment == other._equipment &&
      _status == other._status &&
      _fullStartDateTime == other._fullStartDateTime &&
      _fullEndDateTime == other._fullEndDateTime;
  }
  
  @override
  int get hashCode => toString().hashCode;
  
  @override
  String toString() {
    var buffer = new StringBuffer();
    
    buffer.write("BookingRequest {");
    buffer.write("id=" + "$id" + ", ");
    buffer.write("clientEmail=" + "$_clientEmail" + ", ");
    buffer.write("clientName=" + "$_clientName" + ", ");
    buffer.write("clientPhone=" + "$_clientPhone" + ", ");
    buffer.write("studio=" + "$_studio" + ", ");
    buffer.write("date=" + "$_date" + ", ");
    buffer.write("hours=" + "$_hours" + ", ");
    buffer.write("price=" + "$_price" + ", ");
    buffer.write("equipment=" + "$_equipment" + ", ");
    buffer.write("status=" + "$_status" + ", ");
    buffer.write("fullStartDateTime=" + "$_fullStartDateTime" + ", ");
    buffer.write("fullEndDateTime=" + "$_fullEndDateTime" + ", ");
    buffer.write("createdAt=" + (_createdAt != null ? _createdAt!.format() : "null") + ", ");
    buffer.write("updatedAt=" + (_updatedAt != null ? _updatedAt!.format() : "null"));
    buffer.write("}");
    
    return buffer.toString();
  }
  
  BookingRequest copyWith({String? clientEmail, String? clientName, String? clientPhone, String? studio, String? date, String? hours, String? price, String? equipment, String? status, String? fullStartDateTime, String? fullEndDateTime}) {
    return BookingRequest._internal(
      id: id,
      clientEmail: clientEmail ?? this.clientEmail,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      studio: studio ?? this.studio,
      date: date ?? this.date,
      hours: hours ?? this.hours,
      price: price ?? this.price,
      equipment: equipment ?? this.equipment,
      status: status ?? this.status,
      fullStartDateTime: fullStartDateTime ?? this.fullStartDateTime,
      fullEndDateTime: fullEndDateTime ?? this.fullEndDateTime);
  }
  
  BookingRequest copyWithModelFieldValues({
    ModelFieldValue<String>? clientEmail,
    ModelFieldValue<String?>? clientName,
    ModelFieldValue<String?>? clientPhone,
    ModelFieldValue<String>? studio,
    ModelFieldValue<String>? date,
    ModelFieldValue<String>? hours,
    ModelFieldValue<String>? price,
    ModelFieldValue<String?>? equipment,
    ModelFieldValue<String?>? status,
    ModelFieldValue<String>? fullStartDateTime,
    ModelFieldValue<String>? fullEndDateTime
  }) {
    return BookingRequest._internal(
      id: id,
      clientEmail: clientEmail == null ? this.clientEmail : clientEmail.value,
      clientName: clientName == null ? this.clientName : clientName.value,
      clientPhone: clientPhone == null ? this.clientPhone : clientPhone.value,
      studio: studio == null ? this.studio : studio.value,
      date: date == null ? this.date : date.value,
      hours: hours == null ? this.hours : hours.value,
      price: price == null ? this.price : price.value,
      equipment: equipment == null ? this.equipment : equipment.value,
      status: status == null ? this.status : status.value,
      fullStartDateTime: fullStartDateTime == null ? this.fullStartDateTime : fullStartDateTime.value,
      fullEndDateTime: fullEndDateTime == null ? this.fullEndDateTime : fullEndDateTime.value
    );
  }
  
  BookingRequest.fromJson(Map<String, dynamic> json)  
    : id = json['id'],
      _clientEmail = json['clientEmail'],
      _clientName = json['clientName'],
      _clientPhone = json['clientPhone'],
      _studio = json['studio'],
      _date = json['date'],
      _hours = json['hours'],
      _price = json['price'],
      _equipment = json['equipment'],
      _status = json['status'],
      _fullStartDateTime = json['fullStartDateTime'],
      _fullEndDateTime = json['fullEndDateTime'],
      _createdAt = json['createdAt'] != null ? amplify_core.TemporalDateTime.fromString(json['createdAt']) : null,
      _updatedAt = json['updatedAt'] != null ? amplify_core.TemporalDateTime.fromString(json['updatedAt']) : null;
  
  Map<String, dynamic> toJson() => {
    'id': id, 'clientEmail': _clientEmail, 'clientName': _clientName, 'clientPhone': _clientPhone, 'studio': _studio, 'date': _date, 'hours': _hours, 'price': _price, 'equipment': _equipment, 'status': _status, 'fullStartDateTime': _fullStartDateTime, 'fullEndDateTime': _fullEndDateTime, 'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format()
  };
  
  Map<String, Object?> toMap() => {
    'id': id,
    'clientEmail': _clientEmail,
    'clientName': _clientName,
    'clientPhone': _clientPhone,
    'studio': _studio,
    'date': _date,
    'hours': _hours,
    'price': _price,
    'equipment': _equipment,
    'status': _status,
    'fullStartDateTime': _fullStartDateTime,
    'fullEndDateTime': _fullEndDateTime,
    'createdAt': _createdAt,
    'updatedAt': _updatedAt
  };

  static final amplify_core.QueryModelIdentifier<BookingRequestModelIdentifier> MODEL_IDENTIFIER = amplify_core.QueryModelIdentifier<BookingRequestModelIdentifier>();
  static final ID = amplify_core.QueryField(fieldName: "id");
  static final CLIENTEMAIL = amplify_core.QueryField(fieldName: "clientEmail");
  static final CLIENTNAME = amplify_core.QueryField(fieldName: "clientName");
  static final CLIENTPHONE = amplify_core.QueryField(fieldName: "clientPhone");
  static final STUDIO = amplify_core.QueryField(fieldName: "studio");
  static final DATE = amplify_core.QueryField(fieldName: "date");
  static final HOURS = amplify_core.QueryField(fieldName: "hours");
  static final PRICE = amplify_core.QueryField(fieldName: "price");
  static final EQUIPMENT = amplify_core.QueryField(fieldName: "equipment");
  static final STATUS = amplify_core.QueryField(fieldName: "status");
  static final FULLSTARTDATETIME = amplify_core.QueryField(fieldName: "fullStartDateTime");
  static final FULLENDDATETIME = amplify_core.QueryField(fieldName: "fullEndDateTime");
  static var schema = amplify_core.Model.defineSchema(define: (amplify_core.ModelSchemaDefinition modelSchemaDefinition) {
    modelSchemaDefinition.name = "BookingRequest";
    modelSchemaDefinition.pluralName = "BookingRequests";
    
    modelSchemaDefinition.authRules = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.OWNER,
        ownerField: "clientEmail",
        identityClaim: "email",
        provider: amplify_core.AuthRuleProvider.USERPOOLS,
        operations: const [
          amplify_core.ModelOperation.READ,
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE
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
      amplify_core.ModelIndex(fields: const ["clientEmail"], name: "byClientEmail"),
      amplify_core.ModelIndex(fields: const ["fullStartDateTime"], name: "byStartDate")
    ];
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.id());
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.CLIENTEMAIL,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.CLIENTNAME,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.CLIENTPHONE,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.STUDIO,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.DATE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.HOURS,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.PRICE,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.EQUIPMENT,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.STATUS,
      isRequired: false,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.FULLSTARTDATETIME,
      isRequired: true,
      ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)
    ));
    
    modelSchemaDefinition.addField(amplify_core.ModelFieldDefinition.field(
      key: BookingRequest.FULLENDDATETIME,
      isRequired: true,
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

class _BookingRequestModelType extends amplify_core.ModelType<BookingRequest> {
  const _BookingRequestModelType();
  
  @override
  BookingRequest fromJson(Map<String, dynamic> jsonData) {
    return BookingRequest.fromJson(jsonData);
  }
  
  @override
  String modelName() {
    return 'BookingRequest';
  }
}

/**
 * This is an auto generated class representing the model identifier
 * of [BookingRequest] in your schema.
 */
class BookingRequestModelIdentifier implements amplify_core.ModelIdentifier<BookingRequest> {
  final String id;

  /** Create an instance of BookingRequestModelIdentifier using [id] the primary key. */
  const BookingRequestModelIdentifier({
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
  String toString() => 'BookingRequestModelIdentifier(id: $id)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    
    return other is BookingRequestModelIdentifier &&
      id == other.id;
  }
  
  @override
  int get hashCode =>
    id.hashCode;
}