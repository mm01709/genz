// ignore_for_file: public_member_api_docs, annotate_overrides, dead_code, depend_on_referenced_packages, file_names, library_private_types_in_public_api, no_leading_underscores_for_library_prefixes, no_leading_underscores_for_local_identifiers, non_constant_identifier_names, null_check_on_nullable_type_parameter, override_on_non_overriding_member, prefer_adjacent_string_concatenation, prefer_const_constructors, prefer_if_null_operators, prefer_interpolation_to_compose_strings, slash_for_doc_comments, sort_child_properties_last, unnecessary_const, unnecessary_constructor_name, unnecessary_late, unnecessary_new, unnecessary_null_aware_assignments, unnecessary_nullable_for_final_variable_declarations, unnecessary_string_interpolations, use_build_context_synchronously

import 'package:amplify_core/amplify_core.dart' as amplify_core;

class GenzService extends amplify_core.Model {
  static const classType = const _GenzServiceModelType();
  final String id;
  final String? _category;
  final String? _name;
  final String? _nameAr;
  final String? _description;
  final int? _price;
  final String? _priceLabel;
  final int? _sortOrder;
  final bool? _available;
  final amplify_core.TemporalDateTime? _createdAt;
  final amplify_core.TemporalDateTime? _updatedAt;

  @override
  getInstanceType() => classType;

  @Deprecated('[getId] is being deprecated in favor of custom primary key feature. Use getter [modelIdentifier] to get model identifier.')
  @override
  String getId() => id;

  GenzServiceModelIdentifier get modelIdentifier =>
      GenzServiceModelIdentifier(id: id);

  String get category {
    try { return _category!; }
    catch (e) {
      throw amplify_core.AmplifyCodeGenModelException(
        amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
        recoverySuggestion: amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
        underlyingException: e.toString());
    }
  }

  String get name {
    try { return _name!; }
    catch (e) {
      throw amplify_core.AmplifyCodeGenModelException(
        amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastExceptionMessage,
        recoverySuggestion: amplify_core.AmplifyExceptionMessages.codeGenRequiredFieldForceCastRecoverySuggestion,
        underlyingException: e.toString());
    }
  }

  String? get nameAr      => _nameAr;
  String? get description => _description;
  int?    get price       => _price;
  String? get priceLabel  => _priceLabel;
  int?    get sortOrder   => _sortOrder;
  bool?   get available   => _available;
  amplify_core.TemporalDateTime? get createdAt => _createdAt;
  amplify_core.TemporalDateTime? get updatedAt => _updatedAt;

  const GenzService._internal({
    required this.id,
    required category,
    required name,
    nameAr, description, price, priceLabel, sortOrder, available,
    createdAt, updatedAt,
  })  : _category    = category,
        _name        = name,
        _nameAr      = nameAr,
        _description = description,
        _price       = price,
        _priceLabel  = priceLabel,
        _sortOrder   = sortOrder,
        _available   = available,
        _createdAt   = createdAt,
        _updatedAt   = updatedAt;

  factory GenzService({
    String? id,
    required String category,
    required String name,
    String? nameAr,
    String? description,
    int? price,
    String? priceLabel,
    int? sortOrder,
    bool? available,
  }) {
    return GenzService._internal(
      id:          id ?? amplify_core.UUID.getUUID(),
      category:    category,
      name:        name,
      nameAr:      nameAr,
      description: description,
      price:       price,
      priceLabel:  priceLabel,
      sortOrder:   sortOrder,
      available:   available,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GenzService &&
        id           == other.id &&
        _category    == other._category &&
        _name        == other._name &&
        _nameAr      == other._nameAr &&
        _description == other._description &&
        _price       == other._price &&
        _priceLabel  == other._priceLabel &&
        _sortOrder   == other._sortOrder &&
        _available   == other._available;
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  String toString() {
    return 'GenzService{id=$id, category=$_category, name=$_name, price=$_price}';
  }

  GenzService copyWith({
    String? category, String? name, String? nameAr,
    String? description, int? price, String? priceLabel,
    int? sortOrder, bool? available,
  }) {
    return GenzService._internal(
      id:          id,
      category:    category    ?? this.category,
      name:        name        ?? this.name,
      nameAr:      nameAr      ?? this.nameAr,
      description: description ?? this.description,
      price:       price       ?? this.price,
      priceLabel:  priceLabel  ?? this.priceLabel,
      sortOrder:   sortOrder   ?? this.sortOrder,
      available:   available   ?? this.available,
    );
  }

  GenzService.fromJson(Map<String, dynamic> json)
      : id          = json['id'],
        _category   = json['category'],
        _name       = json['name'],
        _nameAr     = json['nameAr'],
        _description= json['description'],
        _price      = (json['price'] as num?)?.toInt(),
        _priceLabel = json['priceLabel'],
        _sortOrder  = (json['sortOrder'] as num?)?.toInt(),
        _available  = json['available'],
        _createdAt  = json['createdAt'] != null
            ? amplify_core.TemporalDateTime.fromString(json['createdAt'])
            : null,
        _updatedAt  = json['updatedAt'] != null
            ? amplify_core.TemporalDateTime.fromString(json['updatedAt'])
            : null;

  Map<String, dynamic> toJson() => {
    'id': id, 'category': _category, 'name': _name, 'nameAr': _nameAr,
    'description': _description, 'price': _price, 'priceLabel': _priceLabel,
    'sortOrder': _sortOrder, 'available': _available,
    'createdAt': _createdAt?.format(), 'updatedAt': _updatedAt?.format(),
  };

  Map<String, Object?> toMap() => {
    'id': id, 'category': _category, 'name': _name, 'nameAr': _nameAr,
    'description': _description, 'price': _price, 'priceLabel': _priceLabel,
    'sortOrder': _sortOrder, 'available': _available,
    'createdAt': _createdAt, 'updatedAt': _updatedAt,
  };

  static final amplify_core.QueryModelIdentifier<GenzServiceModelIdentifier>
      MODEL_IDENTIFIER =
      amplify_core.QueryModelIdentifier<GenzServiceModelIdentifier>();
  static final ID          = amplify_core.QueryField(fieldName: 'id');
  static final CATEGORY    = amplify_core.QueryField(fieldName: 'category');
  static final NAME        = amplify_core.QueryField(fieldName: 'name');
  static final NAMEAR      = amplify_core.QueryField(fieldName: 'nameAr');
  static final DESCRIPTION = amplify_core.QueryField(fieldName: 'description');
  static final PRICE       = amplify_core.QueryField(fieldName: 'price');
  static final PRICELABEL  = amplify_core.QueryField(fieldName: 'priceLabel');
  static final SORTORDER   = amplify_core.QueryField(fieldName: 'sortOrder');
  static final AVAILABLE   = amplify_core.QueryField(fieldName: 'available');

  static var schema = amplify_core.Model.defineSchema(
      define: (amplify_core.ModelSchemaDefinition d) {
    d.name       = 'GenzService';
    d.pluralName = 'GenzServices';
    d.authRules  = [
      amplify_core.AuthRule(
        authStrategy: amplify_core.AuthStrategy.PRIVATE,
        operations: const [
          amplify_core.ModelOperation.CREATE,
          amplify_core.ModelOperation.UPDATE,
          amplify_core.ModelOperation.DELETE,
          amplify_core.ModelOperation.READ,
        ],
      )
    ];

    d.addField(amplify_core.ModelFieldDefinition.id());
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.CATEGORY, isRequired: true,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)));
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.NAME, isRequired: true,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)));
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.NAMEAR, isRequired: false,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)));
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.DESCRIPTION, isRequired: false,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)));
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.PRICE, isRequired: false,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)));
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.PRICELABEL, isRequired: false,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.string)));
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.SORTORDER, isRequired: false,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.int)));
    d.addField(amplify_core.ModelFieldDefinition.field(
        key: GenzService.AVAILABLE, isRequired: false,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.bool)));
    d.addField(amplify_core.ModelFieldDefinition.nonQueryField(
        fieldName: 'createdAt', isRequired: false, isReadOnly: true,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)));
    d.addField(amplify_core.ModelFieldDefinition.nonQueryField(
        fieldName: 'updatedAt', isRequired: false, isReadOnly: true,
        ofType: amplify_core.ModelFieldType(amplify_core.ModelFieldTypeEnum.dateTime)));
  });
}

class _GenzServiceModelType extends amplify_core.ModelType<GenzService> {
  const _GenzServiceModelType();

  @override
  GenzService fromJson(Map<String, dynamic> jsonData) =>
      GenzService.fromJson(jsonData);

  @override
  String modelName() => 'GenzService';
}

class GenzServiceModelIdentifier
    implements amplify_core.ModelIdentifier<GenzService> {
  final String id;
  const GenzServiceModelIdentifier({required this.id});

  @override
  Map<String, dynamic> serializeAsMap() => {'id': id};
  @override
  List<Map<String, dynamic>> serializeAsList() =>
      serializeAsMap().entries.map((e) => {e.key: e.value}).toList();
  @override
  String serializeAsString() => id;
  @override
  String toString() => 'GenzServiceModelIdentifier(id: $id)';
  @override
  bool operator ==(Object other) =>
      other is GenzServiceModelIdentifier && id == other.id;
  @override
  int get hashCode => id.hashCode;
}
