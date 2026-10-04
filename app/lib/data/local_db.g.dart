// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_db.dart';

// ignore_for_file: type=lint
class $LocalTracksTable extends LocalTracks
    with TableInfo<$LocalTracksTable, LocalTrack> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumIdMeta = const VerificationMeta(
    'albumId',
  );
  @override
  late final GeneratedColumn<String> albumId = GeneratedColumn<String>(
    'album_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchMeta = const VerificationMeta('search');
  @override
  late final GeneratedColumn<String> search = GeneratedColumn<String>(
    'search',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, albumId, json, search, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrack> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('album_id')) {
      context.handle(
        _albumIdMeta,
        albumId.isAcceptableOrUnknown(data['album_id']!, _albumIdMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('search')) {
      context.handle(
        _searchMeta,
        search.isAcceptableOrUnknown(data['search']!, _searchMeta),
      );
    } else if (isInserting) {
      context.missing(_searchMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrack map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrack(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      albumId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_id'],
      ),
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      search: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalTracksTable createAlias(String alias) {
    return $LocalTracksTable(attachedDatabase, alias);
  }
}

class LocalTrack extends DataClass implements Insertable<LocalTrack> {
  final String id;
  final String? albumId;
  final String json;
  final String search;
  final int updatedAt;
  const LocalTrack({
    required this.id,
    this.albumId,
    required this.json,
    required this.search,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || albumId != null) {
      map['album_id'] = Variable<String>(albumId);
    }
    map['json'] = Variable<String>(json);
    map['search'] = Variable<String>(search);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LocalTracksCompanion toCompanion(bool nullToAbsent) {
    return LocalTracksCompanion(
      id: Value(id),
      albumId: albumId == null && nullToAbsent
          ? const Value.absent()
          : Value(albumId),
      json: Value(json),
      search: Value(search),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalTrack.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrack(
      id: serializer.fromJson<String>(json['id']),
      albumId: serializer.fromJson<String?>(json['albumId']),
      json: serializer.fromJson<String>(json['json']),
      search: serializer.fromJson<String>(json['search']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'albumId': serializer.toJson<String?>(albumId),
      'json': serializer.toJson<String>(json),
      'search': serializer.toJson<String>(search),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LocalTrack copyWith({
    String? id,
    Value<String?> albumId = const Value.absent(),
    String? json,
    String? search,
    int? updatedAt,
  }) => LocalTrack(
    id: id ?? this.id,
    albumId: albumId.present ? albumId.value : this.albumId,
    json: json ?? this.json,
    search: search ?? this.search,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalTrack copyWithCompanion(LocalTracksCompanion data) {
    return LocalTrack(
      id: data.id.present ? data.id.value : this.id,
      albumId: data.albumId.present ? data.albumId.value : this.albumId,
      json: data.json.present ? data.json.value : this.json,
      search: data.search.present ? data.search.value : this.search,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrack(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('json: $json, ')
          ..write('search: $search, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, albumId, json, search, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrack &&
          other.id == this.id &&
          other.albumId == this.albumId &&
          other.json == this.json &&
          other.search == this.search &&
          other.updatedAt == this.updatedAt);
}

class LocalTracksCompanion extends UpdateCompanion<LocalTrack> {
  final Value<String> id;
  final Value<String?> albumId;
  final Value<String> json;
  final Value<String> search;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const LocalTracksCompanion({
    this.id = const Value.absent(),
    this.albumId = const Value.absent(),
    this.json = const Value.absent(),
    this.search = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTracksCompanion.insert({
    required String id,
    this.albumId = const Value.absent(),
    required String json,
    required String search,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       search = Value(search),
       updatedAt = Value(updatedAt);
  static Insertable<LocalTrack> custom({
    Expression<String>? id,
    Expression<String>? albumId,
    Expression<String>? json,
    Expression<String>? search,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (albumId != null) 'album_id': albumId,
      if (json != null) 'json': json,
      if (search != null) 'search': search,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTracksCompanion copyWith({
    Value<String>? id,
    Value<String?>? albumId,
    Value<String>? json,
    Value<String>? search,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalTracksCompanion(
      id: id ?? this.id,
      albumId: albumId ?? this.albumId,
      json: json ?? this.json,
      search: search ?? this.search,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (albumId.present) {
      map['album_id'] = Variable<String>(albumId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (search.present) {
      map['search'] = Variable<String>(search.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTracksCompanion(')
          ..write('id: $id, ')
          ..write('albumId: $albumId, ')
          ..write('json: $json, ')
          ..write('search: $search, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAlbumsTable extends LocalAlbums
    with TableInfo<$LocalAlbumsTable, LocalAlbum> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAlbumsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchMeta = const VerificationMeta('search');
  @override
  late final GeneratedColumn<String> search = GeneratedColumn<String>(
    'search',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, search];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'albums';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAlbum> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('search')) {
      context.handle(
        _searchMeta,
        search.isAcceptableOrUnknown(data['search']!, _searchMeta),
      );
    } else if (isInserting) {
      context.missing(_searchMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalAlbum map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAlbum(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      search: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search'],
      )!,
    );
  }

  @override
  $LocalAlbumsTable createAlias(String alias) {
    return $LocalAlbumsTable(attachedDatabase, alias);
  }
}

class LocalAlbum extends DataClass implements Insertable<LocalAlbum> {
  final String id;
  final String json;
  final String search;
  const LocalAlbum({
    required this.id,
    required this.json,
    required this.search,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['search'] = Variable<String>(search);
    return map;
  }

  LocalAlbumsCompanion toCompanion(bool nullToAbsent) {
    return LocalAlbumsCompanion(
      id: Value(id),
      json: Value(json),
      search: Value(search),
    );
  }

  factory LocalAlbum.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAlbum(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      search: serializer.fromJson<String>(json['search']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'search': serializer.toJson<String>(search),
    };
  }

  LocalAlbum copyWith({String? id, String? json, String? search}) => LocalAlbum(
    id: id ?? this.id,
    json: json ?? this.json,
    search: search ?? this.search,
  );
  LocalAlbum copyWithCompanion(LocalAlbumsCompanion data) {
    return LocalAlbum(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      search: data.search.present ? data.search.value : this.search,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAlbum(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('search: $search')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, search);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAlbum &&
          other.id == this.id &&
          other.json == this.json &&
          other.search == this.search);
}

class LocalAlbumsCompanion extends UpdateCompanion<LocalAlbum> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> search;
  final Value<int> rowid;
  const LocalAlbumsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.search = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAlbumsCompanion.insert({
    required String id,
    required String json,
    required String search,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       search = Value(search);
  static Insertable<LocalAlbum> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? search,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (search != null) 'search': search,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAlbumsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? search,
    Value<int>? rowid,
  }) {
    return LocalAlbumsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      search: search ?? this.search,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (search.present) {
      map['search'] = Variable<String>(search.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAlbumsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('search: $search, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalArtistsTable extends LocalArtists
    with TableInfo<$LocalArtistsTable, LocalArtist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalArtistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchMeta = const VerificationMeta('search');
  @override
  late final GeneratedColumn<String> search = GeneratedColumn<String>(
    'search',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, search];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'artists';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalArtist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('search')) {
      context.handle(
        _searchMeta,
        search.isAcceptableOrUnknown(data['search']!, _searchMeta),
      );
    } else if (isInserting) {
      context.missing(_searchMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalArtist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalArtist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      search: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search'],
      )!,
    );
  }

  @override
  $LocalArtistsTable createAlias(String alias) {
    return $LocalArtistsTable(attachedDatabase, alias);
  }
}

class LocalArtist extends DataClass implements Insertable<LocalArtist> {
  final String id;
  final String json;
  final String search;
  const LocalArtist({
    required this.id,
    required this.json,
    required this.search,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['search'] = Variable<String>(search);
    return map;
  }

  LocalArtistsCompanion toCompanion(bool nullToAbsent) {
    return LocalArtistsCompanion(
      id: Value(id),
      json: Value(json),
      search: Value(search),
    );
  }

  factory LocalArtist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalArtist(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      search: serializer.fromJson<String>(json['search']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'search': serializer.toJson<String>(search),
    };
  }

  LocalArtist copyWith({String? id, String? json, String? search}) =>
      LocalArtist(
        id: id ?? this.id,
        json: json ?? this.json,
        search: search ?? this.search,
      );
  LocalArtist copyWithCompanion(LocalArtistsCompanion data) {
    return LocalArtist(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      search: data.search.present ? data.search.value : this.search,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalArtist(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('search: $search')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, search);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalArtist &&
          other.id == this.id &&
          other.json == this.json &&
          other.search == this.search);
}

class LocalArtistsCompanion extends UpdateCompanion<LocalArtist> {
  final Value<String> id;
  final Value<String> json;
  final Value<String> search;
  final Value<int> rowid;
  const LocalArtistsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.search = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalArtistsCompanion.insert({
    required String id,
    required String json,
    required String search,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       search = Value(search);
  static Insertable<LocalArtist> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<String>? search,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (search != null) 'search': search,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalArtistsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<String>? search,
    Value<int>? rowid,
  }) {
    return LocalArtistsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      search: search ?? this.search,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (search.present) {
      map['search'] = Variable<String>(search.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalArtistsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('search: $search, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistsTable extends LocalPlaylists
    with TableInfo<$LocalPlaylistsTable, LocalPlaylist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _searchMeta = const VerificationMeta('search');
  @override
  late final GeneratedColumn<String> search = GeneratedColumn<String>(
    'search',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, version, search];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlaylist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('search')) {
      context.handle(
        _searchMeta,
        search.isAcceptableOrUnknown(data['search']!, _searchMeta),
      );
    } else if (isInserting) {
      context.missing(_searchMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalPlaylist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      search: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}search'],
      )!,
    );
  }

  @override
  $LocalPlaylistsTable createAlias(String alias) {
    return $LocalPlaylistsTable(attachedDatabase, alias);
  }
}

class LocalPlaylist extends DataClass implements Insertable<LocalPlaylist> {
  final String id;
  final String json;
  final int version;
  final String search;
  const LocalPlaylist({
    required this.id,
    required this.json,
    required this.version,
    required this.search,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['json'] = Variable<String>(json);
    map['version'] = Variable<int>(version);
    map['search'] = Variable<String>(search);
    return map;
  }

  LocalPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistsCompanion(
      id: Value(id),
      json: Value(json),
      version: Value(version),
      search: Value(search),
    );
  }

  factory LocalPlaylist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylist(
      id: serializer.fromJson<String>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      version: serializer.fromJson<int>(json['version']),
      search: serializer.fromJson<String>(json['search']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'json': serializer.toJson<String>(json),
      'version': serializer.toJson<int>(version),
      'search': serializer.toJson<String>(search),
    };
  }

  LocalPlaylist copyWith({
    String? id,
    String? json,
    int? version,
    String? search,
  }) => LocalPlaylist(
    id: id ?? this.id,
    json: json ?? this.json,
    version: version ?? this.version,
    search: search ?? this.search,
  );
  LocalPlaylist copyWithCompanion(LocalPlaylistsCompanion data) {
    return LocalPlaylist(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      version: data.version.present ? data.version.value : this.version,
      search: data.search.present ? data.search.value : this.search,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylist(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('search: $search')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, version, search);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylist &&
          other.id == this.id &&
          other.json == this.json &&
          other.version == this.version &&
          other.search == this.search);
}

class LocalPlaylistsCompanion extends UpdateCompanion<LocalPlaylist> {
  final Value<String> id;
  final Value<String> json;
  final Value<int> version;
  final Value<String> search;
  final Value<int> rowid;
  const LocalPlaylistsCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.version = const Value.absent(),
    this.search = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlaylistsCompanion.insert({
    required String id,
    required String json,
    required int version,
    required String search,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       json = Value(json),
       version = Value(version),
       search = Value(search);
  static Insertable<LocalPlaylist> custom({
    Expression<String>? id,
    Expression<String>? json,
    Expression<int>? version,
    Expression<String>? search,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (version != null) 'version': version,
      if (search != null) 'search': search,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? json,
    Value<int>? version,
    Value<String>? search,
    Value<int>? rowid,
  }) {
    return LocalPlaylistsCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      version: version ?? this.version,
      search: search ?? this.search,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (search.present) {
      map['search'] = Variable<String>(search.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('version: $version, ')
          ..write('search: $search, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlaylistItemsTable extends LocalPlaylistItems
    with TableInfo<$LocalPlaylistItemsTable, LocalPlaylistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlaylistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [playlistId, itemId, position, trackId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlaylistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {playlistId, itemId};
  @override
  LocalPlaylistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaylistItem(
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
    );
  }

  @override
  $LocalPlaylistItemsTable createAlias(String alias) {
    return $LocalPlaylistItemsTable(attachedDatabase, alias);
  }
}

class LocalPlaylistItem extends DataClass
    implements Insertable<LocalPlaylistItem> {
  final String playlistId;
  final String itemId;
  final int position;
  final String trackId;
  const LocalPlaylistItem({
    required this.playlistId,
    required this.itemId,
    required this.position,
    required this.trackId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['playlist_id'] = Variable<String>(playlistId);
    map['item_id'] = Variable<String>(itemId);
    map['position'] = Variable<int>(position);
    map['track_id'] = Variable<String>(trackId);
    return map;
  }

  LocalPlaylistItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalPlaylistItemsCompanion(
      playlistId: Value(playlistId),
      itemId: Value(itemId),
      position: Value(position),
      trackId: Value(trackId),
    );
  }

  factory LocalPlaylistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaylistItem(
      playlistId: serializer.fromJson<String>(json['playlistId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      position: serializer.fromJson<int>(json['position']),
      trackId: serializer.fromJson<String>(json['trackId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'playlistId': serializer.toJson<String>(playlistId),
      'itemId': serializer.toJson<String>(itemId),
      'position': serializer.toJson<int>(position),
      'trackId': serializer.toJson<String>(trackId),
    };
  }

  LocalPlaylistItem copyWith({
    String? playlistId,
    String? itemId,
    int? position,
    String? trackId,
  }) => LocalPlaylistItem(
    playlistId: playlistId ?? this.playlistId,
    itemId: itemId ?? this.itemId,
    position: position ?? this.position,
    trackId: trackId ?? this.trackId,
  );
  LocalPlaylistItem copyWithCompanion(LocalPlaylistItemsCompanion data) {
    return LocalPlaylistItem(
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      position: data.position.present ? data.position.value : this.position,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistItem(')
          ..write('playlistId: $playlistId, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position, ')
          ..write('trackId: $trackId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(playlistId, itemId, position, trackId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaylistItem &&
          other.playlistId == this.playlistId &&
          other.itemId == this.itemId &&
          other.position == this.position &&
          other.trackId == this.trackId);
}

class LocalPlaylistItemsCompanion extends UpdateCompanion<LocalPlaylistItem> {
  final Value<String> playlistId;
  final Value<String> itemId;
  final Value<int> position;
  final Value<String> trackId;
  final Value<int> rowid;
  const LocalPlaylistItemsCompanion({
    this.playlistId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.position = const Value.absent(),
    this.trackId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlaylistItemsCompanion.insert({
    required String playlistId,
    required String itemId,
    required int position,
    required String trackId,
    this.rowid = const Value.absent(),
  }) : playlistId = Value(playlistId),
       itemId = Value(itemId),
       position = Value(position),
       trackId = Value(trackId);
  static Insertable<LocalPlaylistItem> custom({
    Expression<String>? playlistId,
    Expression<String>? itemId,
    Expression<int>? position,
    Expression<String>? trackId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (playlistId != null) 'playlist_id': playlistId,
      if (itemId != null) 'item_id': itemId,
      if (position != null) 'position': position,
      if (trackId != null) 'track_id': trackId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlaylistItemsCompanion copyWith({
    Value<String>? playlistId,
    Value<String>? itemId,
    Value<int>? position,
    Value<String>? trackId,
    Value<int>? rowid,
  }) {
    return LocalPlaylistItemsCompanion(
      playlistId: playlistId ?? this.playlistId,
      itemId: itemId ?? this.itemId,
      position: position ?? this.position,
      trackId: trackId ?? this.trackId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaylistItemsCompanion(')
          ..write('playlistId: $playlistId, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position, ')
          ..write('trackId: $trackId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalLyricsTable extends LocalLyrics
    with TableInfo<$LocalLyricsTable, LocalLyric> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalLyricsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [trackId, json, etag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lyrics';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalLyric> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  LocalLyric map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalLyric(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
    );
  }

  @override
  $LocalLyricsTable createAlias(String alias) {
    return $LocalLyricsTable(attachedDatabase, alias);
  }
}

class LocalLyric extends DataClass implements Insertable<LocalLyric> {
  final String trackId;
  final String json;
  final String? etag;
  const LocalLyric({required this.trackId, required this.json, this.etag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    return map;
  }

  LocalLyricsCompanion toCompanion(bool nullToAbsent) {
    return LocalLyricsCompanion(
      trackId: Value(trackId),
      json: Value(json),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
    );
  }

  factory LocalLyric.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalLyric(
      trackId: serializer.fromJson<String>(json['trackId']),
      json: serializer.fromJson<String>(json['json']),
      etag: serializer.fromJson<String?>(json['etag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'json': serializer.toJson<String>(json),
      'etag': serializer.toJson<String?>(etag),
    };
  }

  LocalLyric copyWith({
    String? trackId,
    String? json,
    Value<String?> etag = const Value.absent(),
  }) => LocalLyric(
    trackId: trackId ?? this.trackId,
    json: json ?? this.json,
    etag: etag.present ? etag.value : this.etag,
  );
  LocalLyric copyWithCompanion(LocalLyricsCompanion data) {
    return LocalLyric(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      json: data.json.present ? data.json.value : this.json,
      etag: data.etag.present ? data.etag.value : this.etag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalLyric(')
          ..write('trackId: $trackId, ')
          ..write('json: $json, ')
          ..write('etag: $etag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(trackId, json, etag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalLyric &&
          other.trackId == this.trackId &&
          other.json == this.json &&
          other.etag == this.etag);
}

class LocalLyricsCompanion extends UpdateCompanion<LocalLyric> {
  final Value<String> trackId;
  final Value<String> json;
  final Value<String?> etag;
  final Value<int> rowid;
  const LocalLyricsCompanion({
    this.trackId = const Value.absent(),
    this.json = const Value.absent(),
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalLyricsCompanion.insert({
    required String trackId,
    required String json,
    this.etag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       json = Value(json);
  static Insertable<LocalLyric> custom({
    Expression<String>? trackId,
    Expression<String>? json,
    Expression<String>? etag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (json != null) 'json': json,
      if (etag != null) 'etag': etag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalLyricsCompanion copyWith({
    Value<String>? trackId,
    Value<String>? json,
    Value<String?>? etag,
    Value<int>? rowid,
  }) {
    return LocalLyricsCompanion(
      trackId: trackId ?? this.trackId,
      json: json ?? this.json,
      etag: etag ?? this.etag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalLyricsCompanion(')
          ..write('trackId: $trackId, ')
          ..write('json: $json, ')
          ..write('etag: $etag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadsTable extends Downloads
    with TableInfo<$DownloadsTable, DownloadRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _renditionIdMeta = const VerificationMeta(
    'renditionId',
  );
  @override
  late final GeneratedColumn<String> renditionId = GeneratedColumn<String>(
    'rendition_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaVersionMeta = const VerificationMeta(
    'mediaVersion',
  );
  @override
  late final GeneratedColumn<String> mediaVersion = GeneratedColumn<String>(
    'media_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesTotalMeta = const VerificationMeta(
    'bytesTotal',
  );
  @override
  late final GeneratedColumn<int> bytesTotal = GeneratedColumn<int>(
    'bytes_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesDoneMeta = const VerificationMeta(
    'bytesDone',
  );
  @override
  late final GeneratedColumn<int> bytesDone = GeneratedColumn<int>(
    'bytes_done',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _etagMeta = const VerificationMeta('etag');
  @override
  late final GeneratedColumn<String> etag = GeneratedColumn<String>(
    'etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _extMeta = const VerificationMeta('ext');
  @override
  late final GeneratedColumn<String> ext = GeneratedColumn<String>(
    'ext',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorCodeMeta = const VerificationMeta(
    'errorCode',
  );
  @override
  late final GeneratedColumn<String> errorCode = GeneratedColumn<String>(
    'error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _integrityRetriedMeta = const VerificationMeta(
    'integrityRetried',
  );
  @override
  late final GeneratedColumn<bool> integrityRetried = GeneratedColumn<bool>(
    'integrity_retried',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("integrity_retried" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notBeforeMeta = const VerificationMeta(
    'notBefore',
  );
  @override
  late final GeneratedColumn<int> notBefore = GeneratedColumn<int>(
    'not_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _staleMeta = const VerificationMeta('stale');
  @override
  late final GeneratedColumn<bool> stale = GeneratedColumn<bool>(
    'stale',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("stale" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lockedMeta = const VerificationMeta('locked');
  @override
  late final GeneratedColumn<bool> locked = GeneratedColumn<bool>(
    'locked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("locked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _verifiedMeta = const VerificationMeta(
    'verified',
  );
  @override
  late final GeneratedColumn<String> verified = GeneratedColumn<String>(
    'verified',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    quality,
    state,
    renditionId,
    mediaVersion,
    bytesTotal,
    bytesDone,
    sha256,
    etag,
    ext,
    errorCode,
    attempts,
    integrityRetried,
    notBefore,
    stale,
    locked,
    verified,
    fileName,
    createdAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('rendition_id')) {
      context.handle(
        _renditionIdMeta,
        renditionId.isAcceptableOrUnknown(
          data['rendition_id']!,
          _renditionIdMeta,
        ),
      );
    }
    if (data.containsKey('media_version')) {
      context.handle(
        _mediaVersionMeta,
        mediaVersion.isAcceptableOrUnknown(
          data['media_version']!,
          _mediaVersionMeta,
        ),
      );
    }
    if (data.containsKey('bytes_total')) {
      context.handle(
        _bytesTotalMeta,
        bytesTotal.isAcceptableOrUnknown(data['bytes_total']!, _bytesTotalMeta),
      );
    }
    if (data.containsKey('bytes_done')) {
      context.handle(
        _bytesDoneMeta,
        bytesDone.isAcceptableOrUnknown(data['bytes_done']!, _bytesDoneMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('etag')) {
      context.handle(
        _etagMeta,
        etag.isAcceptableOrUnknown(data['etag']!, _etagMeta),
      );
    }
    if (data.containsKey('ext')) {
      context.handle(
        _extMeta,
        ext.isAcceptableOrUnknown(data['ext']!, _extMeta),
      );
    }
    if (data.containsKey('error_code')) {
      context.handle(
        _errorCodeMeta,
        errorCode.isAcceptableOrUnknown(data['error_code']!, _errorCodeMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('integrity_retried')) {
      context.handle(
        _integrityRetriedMeta,
        integrityRetried.isAcceptableOrUnknown(
          data['integrity_retried']!,
          _integrityRetriedMeta,
        ),
      );
    }
    if (data.containsKey('not_before')) {
      context.handle(
        _notBeforeMeta,
        notBefore.isAcceptableOrUnknown(data['not_before']!, _notBeforeMeta),
      );
    }
    if (data.containsKey('stale')) {
      context.handle(
        _staleMeta,
        stale.isAcceptableOrUnknown(data['stale']!, _staleMeta),
      );
    }
    if (data.containsKey('locked')) {
      context.handle(
        _lockedMeta,
        locked.isAcceptableOrUnknown(data['locked']!, _lockedMeta),
      );
    }
    if (data.containsKey('verified')) {
      context.handle(
        _verifiedMeta,
        verified.isAcceptableOrUnknown(data['verified']!, _verifiedMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DownloadRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      renditionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rendition_id'],
      ),
      mediaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_version'],
      ),
      bytesTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_total'],
      ),
      bytesDone: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_done'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      etag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etag'],
      ),
      ext: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ext'],
      ),
      errorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_code'],
      ),
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      integrityRetried: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}integrity_retried'],
      )!,
      notBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}not_before'],
      ),
      stale: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}stale'],
      )!,
      locked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}locked'],
      )!,
      verified: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verified'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $DownloadsTable createAlias(String alias) {
    return $DownloadsTable(attachedDatabase, alias);
  }
}

class DownloadRow extends DataClass implements Insertable<DownloadRow> {
  final String id;
  final String trackId;
  final String quality;
  final String state;
  final String? renditionId;
  final String? mediaVersion;
  final int? bytesTotal;
  final int bytesDone;
  final String? sha256;
  final String? etag;
  final String? ext;
  final String? errorCode;
  final int attempts;
  final bool integrityRetried;
  final int? notBefore;
  final bool stale;
  final bool locked;
  final String? verified;
  final String? fileName;
  final int createdAt;
  final int? completedAt;
  const DownloadRow({
    required this.id,
    required this.trackId,
    required this.quality,
    required this.state,
    this.renditionId,
    this.mediaVersion,
    this.bytesTotal,
    required this.bytesDone,
    this.sha256,
    this.etag,
    this.ext,
    this.errorCode,
    required this.attempts,
    required this.integrityRetried,
    this.notBefore,
    required this.stale,
    required this.locked,
    this.verified,
    this.fileName,
    required this.createdAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['track_id'] = Variable<String>(trackId);
    map['quality'] = Variable<String>(quality);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || renditionId != null) {
      map['rendition_id'] = Variable<String>(renditionId);
    }
    if (!nullToAbsent || mediaVersion != null) {
      map['media_version'] = Variable<String>(mediaVersion);
    }
    if (!nullToAbsent || bytesTotal != null) {
      map['bytes_total'] = Variable<int>(bytesTotal);
    }
    map['bytes_done'] = Variable<int>(bytesDone);
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    if (!nullToAbsent || etag != null) {
      map['etag'] = Variable<String>(etag);
    }
    if (!nullToAbsent || ext != null) {
      map['ext'] = Variable<String>(ext);
    }
    if (!nullToAbsent || errorCode != null) {
      map['error_code'] = Variable<String>(errorCode);
    }
    map['attempts'] = Variable<int>(attempts);
    map['integrity_retried'] = Variable<bool>(integrityRetried);
    if (!nullToAbsent || notBefore != null) {
      map['not_before'] = Variable<int>(notBefore);
    }
    map['stale'] = Variable<bool>(stale);
    map['locked'] = Variable<bool>(locked);
    if (!nullToAbsent || verified != null) {
      map['verified'] = Variable<String>(verified);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    return map;
  }

  DownloadsCompanion toCompanion(bool nullToAbsent) {
    return DownloadsCompanion(
      id: Value(id),
      trackId: Value(trackId),
      quality: Value(quality),
      state: Value(state),
      renditionId: renditionId == null && nullToAbsent
          ? const Value.absent()
          : Value(renditionId),
      mediaVersion: mediaVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaVersion),
      bytesTotal: bytesTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(bytesTotal),
      bytesDone: Value(bytesDone),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      etag: etag == null && nullToAbsent ? const Value.absent() : Value(etag),
      ext: ext == null && nullToAbsent ? const Value.absent() : Value(ext),
      errorCode: errorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(errorCode),
      attempts: Value(attempts),
      integrityRetried: Value(integrityRetried),
      notBefore: notBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(notBefore),
      stale: Value(stale),
      locked: Value(locked),
      verified: verified == null && nullToAbsent
          ? const Value.absent()
          : Value(verified),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory DownloadRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRow(
      id: serializer.fromJson<String>(json['id']),
      trackId: serializer.fromJson<String>(json['trackId']),
      quality: serializer.fromJson<String>(json['quality']),
      state: serializer.fromJson<String>(json['state']),
      renditionId: serializer.fromJson<String?>(json['renditionId']),
      mediaVersion: serializer.fromJson<String?>(json['mediaVersion']),
      bytesTotal: serializer.fromJson<int?>(json['bytesTotal']),
      bytesDone: serializer.fromJson<int>(json['bytesDone']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      etag: serializer.fromJson<String?>(json['etag']),
      ext: serializer.fromJson<String?>(json['ext']),
      errorCode: serializer.fromJson<String?>(json['errorCode']),
      attempts: serializer.fromJson<int>(json['attempts']),
      integrityRetried: serializer.fromJson<bool>(json['integrityRetried']),
      notBefore: serializer.fromJson<int?>(json['notBefore']),
      stale: serializer.fromJson<bool>(json['stale']),
      locked: serializer.fromJson<bool>(json['locked']),
      verified: serializer.fromJson<String?>(json['verified']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'trackId': serializer.toJson<String>(trackId),
      'quality': serializer.toJson<String>(quality),
      'state': serializer.toJson<String>(state),
      'renditionId': serializer.toJson<String?>(renditionId),
      'mediaVersion': serializer.toJson<String?>(mediaVersion),
      'bytesTotal': serializer.toJson<int?>(bytesTotal),
      'bytesDone': serializer.toJson<int>(bytesDone),
      'sha256': serializer.toJson<String?>(sha256),
      'etag': serializer.toJson<String?>(etag),
      'ext': serializer.toJson<String?>(ext),
      'errorCode': serializer.toJson<String?>(errorCode),
      'attempts': serializer.toJson<int>(attempts),
      'integrityRetried': serializer.toJson<bool>(integrityRetried),
      'notBefore': serializer.toJson<int?>(notBefore),
      'stale': serializer.toJson<bool>(stale),
      'locked': serializer.toJson<bool>(locked),
      'verified': serializer.toJson<String?>(verified),
      'fileName': serializer.toJson<String?>(fileName),
      'createdAt': serializer.toJson<int>(createdAt),
      'completedAt': serializer.toJson<int?>(completedAt),
    };
  }

  DownloadRow copyWith({
    String? id,
    String? trackId,
    String? quality,
    String? state,
    Value<String?> renditionId = const Value.absent(),
    Value<String?> mediaVersion = const Value.absent(),
    Value<int?> bytesTotal = const Value.absent(),
    int? bytesDone,
    Value<String?> sha256 = const Value.absent(),
    Value<String?> etag = const Value.absent(),
    Value<String?> ext = const Value.absent(),
    Value<String?> errorCode = const Value.absent(),
    int? attempts,
    bool? integrityRetried,
    Value<int?> notBefore = const Value.absent(),
    bool? stale,
    bool? locked,
    Value<String?> verified = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    int? createdAt,
    Value<int?> completedAt = const Value.absent(),
  }) => DownloadRow(
    id: id ?? this.id,
    trackId: trackId ?? this.trackId,
    quality: quality ?? this.quality,
    state: state ?? this.state,
    renditionId: renditionId.present ? renditionId.value : this.renditionId,
    mediaVersion: mediaVersion.present ? mediaVersion.value : this.mediaVersion,
    bytesTotal: bytesTotal.present ? bytesTotal.value : this.bytesTotal,
    bytesDone: bytesDone ?? this.bytesDone,
    sha256: sha256.present ? sha256.value : this.sha256,
    etag: etag.present ? etag.value : this.etag,
    ext: ext.present ? ext.value : this.ext,
    errorCode: errorCode.present ? errorCode.value : this.errorCode,
    attempts: attempts ?? this.attempts,
    integrityRetried: integrityRetried ?? this.integrityRetried,
    notBefore: notBefore.present ? notBefore.value : this.notBefore,
    stale: stale ?? this.stale,
    locked: locked ?? this.locked,
    verified: verified.present ? verified.value : this.verified,
    fileName: fileName.present ? fileName.value : this.fileName,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  DownloadRow copyWithCompanion(DownloadsCompanion data) {
    return DownloadRow(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      quality: data.quality.present ? data.quality.value : this.quality,
      state: data.state.present ? data.state.value : this.state,
      renditionId: data.renditionId.present
          ? data.renditionId.value
          : this.renditionId,
      mediaVersion: data.mediaVersion.present
          ? data.mediaVersion.value
          : this.mediaVersion,
      bytesTotal: data.bytesTotal.present
          ? data.bytesTotal.value
          : this.bytesTotal,
      bytesDone: data.bytesDone.present ? data.bytesDone.value : this.bytesDone,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      etag: data.etag.present ? data.etag.value : this.etag,
      ext: data.ext.present ? data.ext.value : this.ext,
      errorCode: data.errorCode.present ? data.errorCode.value : this.errorCode,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      integrityRetried: data.integrityRetried.present
          ? data.integrityRetried.value
          : this.integrityRetried,
      notBefore: data.notBefore.present ? data.notBefore.value : this.notBefore,
      stale: data.stale.present ? data.stale.value : this.stale,
      locked: data.locked.present ? data.locked.value : this.locked,
      verified: data.verified.present ? data.verified.value : this.verified,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRow(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('quality: $quality, ')
          ..write('state: $state, ')
          ..write('renditionId: $renditionId, ')
          ..write('mediaVersion: $mediaVersion, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('sha256: $sha256, ')
          ..write('etag: $etag, ')
          ..write('ext: $ext, ')
          ..write('errorCode: $errorCode, ')
          ..write('attempts: $attempts, ')
          ..write('integrityRetried: $integrityRetried, ')
          ..write('notBefore: $notBefore, ')
          ..write('stale: $stale, ')
          ..write('locked: $locked, ')
          ..write('verified: $verified, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    trackId,
    quality,
    state,
    renditionId,
    mediaVersion,
    bytesTotal,
    bytesDone,
    sha256,
    etag,
    ext,
    errorCode,
    attempts,
    integrityRetried,
    notBefore,
    stale,
    locked,
    verified,
    fileName,
    createdAt,
    completedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRow &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.quality == this.quality &&
          other.state == this.state &&
          other.renditionId == this.renditionId &&
          other.mediaVersion == this.mediaVersion &&
          other.bytesTotal == this.bytesTotal &&
          other.bytesDone == this.bytesDone &&
          other.sha256 == this.sha256 &&
          other.etag == this.etag &&
          other.ext == this.ext &&
          other.errorCode == this.errorCode &&
          other.attempts == this.attempts &&
          other.integrityRetried == this.integrityRetried &&
          other.notBefore == this.notBefore &&
          other.stale == this.stale &&
          other.locked == this.locked &&
          other.verified == this.verified &&
          other.fileName == this.fileName &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt);
}

class DownloadsCompanion extends UpdateCompanion<DownloadRow> {
  final Value<String> id;
  final Value<String> trackId;
  final Value<String> quality;
  final Value<String> state;
  final Value<String?> renditionId;
  final Value<String?> mediaVersion;
  final Value<int?> bytesTotal;
  final Value<int> bytesDone;
  final Value<String?> sha256;
  final Value<String?> etag;
  final Value<String?> ext;
  final Value<String?> errorCode;
  final Value<int> attempts;
  final Value<bool> integrityRetried;
  final Value<int?> notBefore;
  final Value<bool> stale;
  final Value<bool> locked;
  final Value<String?> verified;
  final Value<String?> fileName;
  final Value<int> createdAt;
  final Value<int?> completedAt;
  final Value<int> rowid;
  const DownloadsCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.quality = const Value.absent(),
    this.state = const Value.absent(),
    this.renditionId = const Value.absent(),
    this.mediaVersion = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.etag = const Value.absent(),
    this.ext = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.integrityRetried = const Value.absent(),
    this.notBefore = const Value.absent(),
    this.stale = const Value.absent(),
    this.locked = const Value.absent(),
    this.verified = const Value.absent(),
    this.fileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadsCompanion.insert({
    required String id,
    required String trackId,
    required String quality,
    required String state,
    this.renditionId = const Value.absent(),
    this.mediaVersion = const Value.absent(),
    this.bytesTotal = const Value.absent(),
    this.bytesDone = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.etag = const Value.absent(),
    this.ext = const Value.absent(),
    this.errorCode = const Value.absent(),
    this.attempts = const Value.absent(),
    this.integrityRetried = const Value.absent(),
    this.notBefore = const Value.absent(),
    this.stale = const Value.absent(),
    this.locked = const Value.absent(),
    this.verified = const Value.absent(),
    this.fileName = const Value.absent(),
    required int createdAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       trackId = Value(trackId),
       quality = Value(quality),
       state = Value(state),
       createdAt = Value(createdAt);
  static Insertable<DownloadRow> custom({
    Expression<String>? id,
    Expression<String>? trackId,
    Expression<String>? quality,
    Expression<String>? state,
    Expression<String>? renditionId,
    Expression<String>? mediaVersion,
    Expression<int>? bytesTotal,
    Expression<int>? bytesDone,
    Expression<String>? sha256,
    Expression<String>? etag,
    Expression<String>? ext,
    Expression<String>? errorCode,
    Expression<int>? attempts,
    Expression<bool>? integrityRetried,
    Expression<int>? notBefore,
    Expression<bool>? stale,
    Expression<bool>? locked,
    Expression<String>? verified,
    Expression<String>? fileName,
    Expression<int>? createdAt,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (quality != null) 'quality': quality,
      if (state != null) 'state': state,
      if (renditionId != null) 'rendition_id': renditionId,
      if (mediaVersion != null) 'media_version': mediaVersion,
      if (bytesTotal != null) 'bytes_total': bytesTotal,
      if (bytesDone != null) 'bytes_done': bytesDone,
      if (sha256 != null) 'sha256': sha256,
      if (etag != null) 'etag': etag,
      if (ext != null) 'ext': ext,
      if (errorCode != null) 'error_code': errorCode,
      if (attempts != null) 'attempts': attempts,
      if (integrityRetried != null) 'integrity_retried': integrityRetried,
      if (notBefore != null) 'not_before': notBefore,
      if (stale != null) 'stale': stale,
      if (locked != null) 'locked': locked,
      if (verified != null) 'verified': verified,
      if (fileName != null) 'file_name': fileName,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadsCompanion copyWith({
    Value<String>? id,
    Value<String>? trackId,
    Value<String>? quality,
    Value<String>? state,
    Value<String?>? renditionId,
    Value<String?>? mediaVersion,
    Value<int?>? bytesTotal,
    Value<int>? bytesDone,
    Value<String?>? sha256,
    Value<String?>? etag,
    Value<String?>? ext,
    Value<String?>? errorCode,
    Value<int>? attempts,
    Value<bool>? integrityRetried,
    Value<int?>? notBefore,
    Value<bool>? stale,
    Value<bool>? locked,
    Value<String?>? verified,
    Value<String?>? fileName,
    Value<int>? createdAt,
    Value<int?>? completedAt,
    Value<int>? rowid,
  }) {
    return DownloadsCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      quality: quality ?? this.quality,
      state: state ?? this.state,
      renditionId: renditionId ?? this.renditionId,
      mediaVersion: mediaVersion ?? this.mediaVersion,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      bytesDone: bytesDone ?? this.bytesDone,
      sha256: sha256 ?? this.sha256,
      etag: etag ?? this.etag,
      ext: ext ?? this.ext,
      errorCode: errorCode ?? this.errorCode,
      attempts: attempts ?? this.attempts,
      integrityRetried: integrityRetried ?? this.integrityRetried,
      notBefore: notBefore ?? this.notBefore,
      stale: stale ?? this.stale,
      locked: locked ?? this.locked,
      verified: verified ?? this.verified,
      fileName: fileName ?? this.fileName,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (renditionId.present) {
      map['rendition_id'] = Variable<String>(renditionId.value);
    }
    if (mediaVersion.present) {
      map['media_version'] = Variable<String>(mediaVersion.value);
    }
    if (bytesTotal.present) {
      map['bytes_total'] = Variable<int>(bytesTotal.value);
    }
    if (bytesDone.present) {
      map['bytes_done'] = Variable<int>(bytesDone.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (etag.present) {
      map['etag'] = Variable<String>(etag.value);
    }
    if (ext.present) {
      map['ext'] = Variable<String>(ext.value);
    }
    if (errorCode.present) {
      map['error_code'] = Variable<String>(errorCode.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (integrityRetried.present) {
      map['integrity_retried'] = Variable<bool>(integrityRetried.value);
    }
    if (notBefore.present) {
      map['not_before'] = Variable<int>(notBefore.value);
    }
    if (stale.present) {
      map['stale'] = Variable<bool>(stale.value);
    }
    if (locked.present) {
      map['locked'] = Variable<bool>(locked.value);
    }
    if (verified.present) {
      map['verified'] = Variable<String>(verified.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadsCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('quality: $quality, ')
          ..write('state: $state, ')
          ..write('renditionId: $renditionId, ')
          ..write('mediaVersion: $mediaVersion, ')
          ..write('bytesTotal: $bytesTotal, ')
          ..write('bytesDone: $bytesDone, ')
          ..write('sha256: $sha256, ')
          ..write('etag: $etag, ')
          ..write('ext: $ext, ')
          ..write('errorCode: $errorCode, ')
          ..write('attempts: $attempts, ')
          ..write('integrityRetried: $integrityRetried, ')
          ..write('notBefore: $notBefore, ')
          ..write('stale: $stale, ')
          ..write('locked: $locked, ')
          ..write('verified: $verified, ')
          ..write('fileName: $fileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadRequestsTable extends DownloadRequests
    with TableInfo<$DownloadRequestsTable, DownloadRequest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadRequestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _downloadIdMeta = const VerificationMeta(
    'downloadId',
  );
  @override
  late final GeneratedColumn<String> downloadId = GeneratedColumn<String>(
    'download_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [downloadId, kind, refId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_requests';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadRequest> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('download_id')) {
      context.handle(
        _downloadIdMeta,
        downloadId.isAcceptableOrUnknown(data['download_id']!, _downloadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_downloadIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {downloadId, kind, refId};
  @override
  DownloadRequest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadRequest(
      downloadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}download_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
    );
  }

  @override
  $DownloadRequestsTable createAlias(String alias) {
    return $DownloadRequestsTable(attachedDatabase, alias);
  }
}

class DownloadRequest extends DataClass implements Insertable<DownloadRequest> {
  final String downloadId;
  final String kind;
  final String refId;
  const DownloadRequest({
    required this.downloadId,
    required this.kind,
    required this.refId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['download_id'] = Variable<String>(downloadId);
    map['kind'] = Variable<String>(kind);
    map['ref_id'] = Variable<String>(refId);
    return map;
  }

  DownloadRequestsCompanion toCompanion(bool nullToAbsent) {
    return DownloadRequestsCompanion(
      downloadId: Value(downloadId),
      kind: Value(kind),
      refId: Value(refId),
    );
  }

  factory DownloadRequest.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadRequest(
      downloadId: serializer.fromJson<String>(json['downloadId']),
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<String>(json['refId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'downloadId': serializer.toJson<String>(downloadId),
      'kind': serializer.toJson<String>(kind),
      'refId': serializer.toJson<String>(refId),
    };
  }

  DownloadRequest copyWith({String? downloadId, String? kind, String? refId}) =>
      DownloadRequest(
        downloadId: downloadId ?? this.downloadId,
        kind: kind ?? this.kind,
        refId: refId ?? this.refId,
      );
  DownloadRequest copyWithCompanion(DownloadRequestsCompanion data) {
    return DownloadRequest(
      downloadId: data.downloadId.present
          ? data.downloadId.value
          : this.downloadId,
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRequest(')
          ..write('downloadId: $downloadId, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(downloadId, kind, refId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadRequest &&
          other.downloadId == this.downloadId &&
          other.kind == this.kind &&
          other.refId == this.refId);
}

class DownloadRequestsCompanion extends UpdateCompanion<DownloadRequest> {
  final Value<String> downloadId;
  final Value<String> kind;
  final Value<String> refId;
  final Value<int> rowid;
  const DownloadRequestsCompanion({
    this.downloadId = const Value.absent(),
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadRequestsCompanion.insert({
    required String downloadId,
    required String kind,
    required String refId,
    this.rowid = const Value.absent(),
  }) : downloadId = Value(downloadId),
       kind = Value(kind),
       refId = Value(refId);
  static Insertable<DownloadRequest> custom({
    Expression<String>? downloadId,
    Expression<String>? kind,
    Expression<String>? refId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (downloadId != null) 'download_id': downloadId,
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadRequestsCompanion copyWith({
    Value<String>? downloadId,
    Value<String>? kind,
    Value<String>? refId,
    Value<int>? rowid,
  }) {
    return DownloadRequestsCompanion(
      downloadId: downloadId ?? this.downloadId,
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (downloadId.present) {
      map['download_id'] = Variable<String>(downloadId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadRequestsCompanion(')
          ..write('downloadId: $downloadId, ')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DownloadGroupsTable extends DownloadGroups
    with TableInfo<$DownloadGroupsTable, DownloadGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DownloadGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refIdMeta = const VerificationMeta('refId');
  @override
  late final GeneratedColumn<String> refId = GeneratedColumn<String>(
    'ref_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, refId, quality, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'download_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<DownloadGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('ref_id')) {
      context.handle(
        _refIdMeta,
        refId.isAcceptableOrUnknown(data['ref_id']!, _refIdMeta),
      );
    } else if (isInserting) {
      context.missing(_refIdMeta);
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    } else if (isInserting) {
      context.missing(_qualityMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind, refId};
  @override
  DownloadGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DownloadGroup(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      refId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ref_id'],
      )!,
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DownloadGroupsTable createAlias(String alias) {
    return $DownloadGroupsTable(attachedDatabase, alias);
  }
}

class DownloadGroup extends DataClass implements Insertable<DownloadGroup> {
  final String kind;
  final String refId;
  final String quality;
  final int createdAt;
  const DownloadGroup({
    required this.kind,
    required this.refId,
    required this.quality,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['ref_id'] = Variable<String>(refId);
    map['quality'] = Variable<String>(quality);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  DownloadGroupsCompanion toCompanion(bool nullToAbsent) {
    return DownloadGroupsCompanion(
      kind: Value(kind),
      refId: Value(refId),
      quality: Value(quality),
      createdAt: Value(createdAt),
    );
  }

  factory DownloadGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DownloadGroup(
      kind: serializer.fromJson<String>(json['kind']),
      refId: serializer.fromJson<String>(json['refId']),
      quality: serializer.fromJson<String>(json['quality']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'refId': serializer.toJson<String>(refId),
      'quality': serializer.toJson<String>(quality),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  DownloadGroup copyWith({
    String? kind,
    String? refId,
    String? quality,
    int? createdAt,
  }) => DownloadGroup(
    kind: kind ?? this.kind,
    refId: refId ?? this.refId,
    quality: quality ?? this.quality,
    createdAt: createdAt ?? this.createdAt,
  );
  DownloadGroup copyWithCompanion(DownloadGroupsCompanion data) {
    return DownloadGroup(
      kind: data.kind.present ? data.kind.value : this.kind,
      refId: data.refId.present ? data.refId.value : this.refId,
      quality: data.quality.present ? data.quality.value : this.quality,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DownloadGroup(')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('quality: $quality, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, refId, quality, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DownloadGroup &&
          other.kind == this.kind &&
          other.refId == this.refId &&
          other.quality == this.quality &&
          other.createdAt == this.createdAt);
}

class DownloadGroupsCompanion extends UpdateCompanion<DownloadGroup> {
  final Value<String> kind;
  final Value<String> refId;
  final Value<String> quality;
  final Value<int> createdAt;
  final Value<int> rowid;
  const DownloadGroupsCompanion({
    this.kind = const Value.absent(),
    this.refId = const Value.absent(),
    this.quality = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DownloadGroupsCompanion.insert({
    required String kind,
    required String refId,
    required String quality,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       refId = Value(refId),
       quality = Value(quality),
       createdAt = Value(createdAt);
  static Insertable<DownloadGroup> custom({
    Expression<String>? kind,
    Expression<String>? refId,
    Expression<String>? quality,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (refId != null) 'ref_id': refId,
      if (quality != null) 'quality': quality,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DownloadGroupsCompanion copyWith({
    Value<String>? kind,
    Value<String>? refId,
    Value<String>? quality,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return DownloadGroupsCompanion(
      kind: kind ?? this.kind,
      refId: refId ?? this.refId,
      quality: quality ?? this.quality,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (refId.present) {
      map['ref_id'] = Variable<String>(refId.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DownloadGroupsCompanion(')
          ..write('kind: $kind, ')
          ..write('refId: $refId, ')
          ..write('quality: $quality, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingOpsTable extends PendingOps
    with TableInfo<$PendingOpsTable, PendingOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opsJsonMeta = const VerificationMeta(
    'opsJson',
  );
  @override
  late final GeneratedColumn<String> opsJson = GeneratedColumn<String>(
    'ops_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    playlistId,
    opsJson,
    idempotencyKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_ops';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('ops_json')) {
      context.handle(
        _opsJsonMeta,
        opsJson.isAcceptableOrUnknown(data['ops_json']!, _opsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_opsJsonMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  PendingOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOp(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      opsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ops_json'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingOpsTable createAlias(String alias) {
    return $PendingOpsTable(attachedDatabase, alias);
  }
}

class PendingOp extends DataClass implements Insertable<PendingOp> {
  final int seq;
  final String playlistId;
  final String opsJson;
  final String idempotencyKey;
  final int createdAt;
  const PendingOp({
    required this.seq,
    required this.playlistId,
    required this.opsJson,
    required this.idempotencyKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['playlist_id'] = Variable<String>(playlistId);
    map['ops_json'] = Variable<String>(opsJson);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PendingOpsCompanion toCompanion(bool nullToAbsent) {
    return PendingOpsCompanion(
      seq: Value(seq),
      playlistId: Value(playlistId),
      opsJson: Value(opsJson),
      idempotencyKey: Value(idempotencyKey),
      createdAt: Value(createdAt),
    );
  }

  factory PendingOp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOp(
      seq: serializer.fromJson<int>(json['seq']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      opsJson: serializer.fromJson<String>(json['opsJson']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'playlistId': serializer.toJson<String>(playlistId),
      'opsJson': serializer.toJson<String>(opsJson),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PendingOp copyWith({
    int? seq,
    String? playlistId,
    String? opsJson,
    String? idempotencyKey,
    int? createdAt,
  }) => PendingOp(
    seq: seq ?? this.seq,
    playlistId: playlistId ?? this.playlistId,
    opsJson: opsJson ?? this.opsJson,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    createdAt: createdAt ?? this.createdAt,
  );
  PendingOp copyWithCompanion(PendingOpsCompanion data) {
    return PendingOp(
      seq: data.seq.present ? data.seq.value : this.seq,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      opsJson: data.opsJson.present ? data.opsJson.value : this.opsJson,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOp(')
          ..write('seq: $seq, ')
          ..write('playlistId: $playlistId, ')
          ..write('opsJson: $opsJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(seq, playlistId, opsJson, idempotencyKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOp &&
          other.seq == this.seq &&
          other.playlistId == this.playlistId &&
          other.opsJson == this.opsJson &&
          other.idempotencyKey == this.idempotencyKey &&
          other.createdAt == this.createdAt);
}

class PendingOpsCompanion extends UpdateCompanion<PendingOp> {
  final Value<int> seq;
  final Value<String> playlistId;
  final Value<String> opsJson;
  final Value<String> idempotencyKey;
  final Value<int> createdAt;
  const PendingOpsCompanion({
    this.seq = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.opsJson = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingOpsCompanion.insert({
    this.seq = const Value.absent(),
    required String playlistId,
    required String opsJson,
    required String idempotencyKey,
    required int createdAt,
  }) : playlistId = Value(playlistId),
       opsJson = Value(opsJson),
       idempotencyKey = Value(idempotencyKey),
       createdAt = Value(createdAt);
  static Insertable<PendingOp> custom({
    Expression<int>? seq,
    Expression<String>? playlistId,
    Expression<String>? opsJson,
    Expression<String>? idempotencyKey,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (playlistId != null) 'playlist_id': playlistId,
      if (opsJson != null) 'ops_json': opsJson,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingOpsCompanion copyWith({
    Value<int>? seq,
    Value<String>? playlistId,
    Value<String>? opsJson,
    Value<String>? idempotencyKey,
    Value<int>? createdAt,
  }) {
    return PendingOpsCompanion(
      seq: seq ?? this.seq,
      playlistId: playlistId ?? this.playlistId,
      opsJson: opsJson ?? this.opsJson,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (opsJson.present) {
      map['ops_json'] = Variable<String>(opsJson.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOpsCompanion(')
          ..write('seq: $seq, ')
          ..write('playlistId: $playlistId, ')
          ..write('opsJson: $opsJson, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PendingPlayEventsTable extends PendingPlayEvents
    with TableInfo<$PendingPlayEventsTable, PendingPlayEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingPlayEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [eventId, json, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_play_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingPlayEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  PendingPlayEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingPlayEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PendingPlayEventsTable createAlias(String alias) {
    return $PendingPlayEventsTable(attachedDatabase, alias);
  }
}

class PendingPlayEvent extends DataClass
    implements Insertable<PendingPlayEvent> {
  final String eventId;
  final String json;
  final int createdAt;
  const PendingPlayEvent({
    required this.eventId,
    required this.json,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['json'] = Variable<String>(json);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PendingPlayEventsCompanion toCompanion(bool nullToAbsent) {
    return PendingPlayEventsCompanion(
      eventId: Value(eventId),
      json: Value(json),
      createdAt: Value(createdAt),
    );
  }

  factory PendingPlayEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingPlayEvent(
      eventId: serializer.fromJson<String>(json['eventId']),
      json: serializer.fromJson<String>(json['json']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'json': serializer.toJson<String>(json),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PendingPlayEvent copyWith({String? eventId, String? json, int? createdAt}) =>
      PendingPlayEvent(
        eventId: eventId ?? this.eventId,
        json: json ?? this.json,
        createdAt: createdAt ?? this.createdAt,
      );
  PendingPlayEvent copyWithCompanion(PendingPlayEventsCompanion data) {
    return PendingPlayEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      json: data.json.present ? data.json.value : this.json,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingPlayEvent(')
          ..write('eventId: $eventId, ')
          ..write('json: $json, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(eventId, json, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingPlayEvent &&
          other.eventId == this.eventId &&
          other.json == this.json &&
          other.createdAt == this.createdAt);
}

class PendingPlayEventsCompanion extends UpdateCompanion<PendingPlayEvent> {
  final Value<String> eventId;
  final Value<String> json;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PendingPlayEventsCompanion({
    this.eventId = const Value.absent(),
    this.json = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingPlayEventsCompanion.insert({
    required String eventId,
    required String json,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       json = Value(json),
       createdAt = Value(createdAt);
  static Insertable<PendingPlayEvent> custom({
    Expression<String>? eventId,
    Expression<String>? json,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (json != null) 'json': json,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingPlayEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? json,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PendingPlayEventsCompanion(
      eventId: eventId ?? this.eventId,
      json: json ?? this.json,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingPlayEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('json: $json, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String value;
  const SyncStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateData copyWith({String? key, String? value}) =>
      SyncStateData(key: key ?? this.key, value: value ?? this.value);
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDb extends GeneratedDatabase {
  _$LibraryDb(QueryExecutor e) : super(e);
  $LibraryDbManager get managers => $LibraryDbManager(this);
  late final $LocalTracksTable localTracks = $LocalTracksTable(this);
  late final $LocalAlbumsTable localAlbums = $LocalAlbumsTable(this);
  late final $LocalArtistsTable localArtists = $LocalArtistsTable(this);
  late final $LocalPlaylistsTable localPlaylists = $LocalPlaylistsTable(this);
  late final $LocalPlaylistItemsTable localPlaylistItems =
      $LocalPlaylistItemsTable(this);
  late final $LocalLyricsTable localLyrics = $LocalLyricsTable(this);
  late final $DownloadsTable downloads = $DownloadsTable(this);
  late final $DownloadRequestsTable downloadRequests = $DownloadRequestsTable(
    this,
  );
  late final $DownloadGroupsTable downloadGroups = $DownloadGroupsTable(this);
  late final $PendingOpsTable pendingOps = $PendingOpsTable(this);
  late final $PendingPlayEventsTable pendingPlayEvents =
      $PendingPlayEventsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTracks,
    localAlbums,
    localArtists,
    localPlaylists,
    localPlaylistItems,
    localLyrics,
    downloads,
    downloadRequests,
    downloadGroups,
    pendingOps,
    pendingPlayEvents,
    syncState,
  ];
}

typedef $$LocalTracksTableCreateCompanionBuilder =
    LocalTracksCompanion Function({
      required String id,
      Value<String?> albumId,
      required String json,
      required String search,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$LocalTracksTableUpdateCompanionBuilder =
    LocalTracksCompanion Function({
      Value<String> id,
      Value<String?> albumId,
      Value<String> json,
      Value<String> search,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$LocalTracksTableFilterComposer
    extends Composer<_$LibraryDb, $LocalTracksTable> {
  $$LocalTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalTracksTableOrderingComposer
    extends Composer<_$LibraryDb, $LocalTracksTable> {
  $$LocalTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumId => $composableBuilder(
    column: $table.albumId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTracksTableAnnotationComposer
    extends Composer<_$LibraryDb, $LocalTracksTable> {
  $$LocalTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get albumId =>
      $composableBuilder(column: $table.albumId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get search =>
      $composableBuilder(column: $table.search, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalTracksTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $LocalTracksTable,
          LocalTrack,
          $$LocalTracksTableFilterComposer,
          $$LocalTracksTableOrderingComposer,
          $$LocalTracksTableAnnotationComposer,
          $$LocalTracksTableCreateCompanionBuilder,
          $$LocalTracksTableUpdateCompanionBuilder,
          (
            LocalTrack,
            BaseReferences<_$LibraryDb, $LocalTracksTable, LocalTrack>,
          ),
          LocalTrack,
          PrefetchHooks Function()
        > {
  $$LocalTracksTableTableManager(_$LibraryDb db, $LocalTracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> albumId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> search = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTracksCompanion(
                id: id,
                albumId: albumId,
                json: json,
                search: search,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> albumId = const Value.absent(),
                required String json,
                required String search,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalTracksCompanion.insert(
                id: id,
                albumId: albumId,
                json: json,
                search: search,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalTracksTable, LocalTrack>(table),
                  BaseReferences<_$LibraryDb, $LocalTracksTable, LocalTrack>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $LocalTracksTable,
      LocalTrack,
      $$LocalTracksTableFilterComposer,
      $$LocalTracksTableOrderingComposer,
      $$LocalTracksTableAnnotationComposer,
      $$LocalTracksTableCreateCompanionBuilder,
      $$LocalTracksTableUpdateCompanionBuilder,
      (LocalTrack, BaseReferences<_$LibraryDb, $LocalTracksTable, LocalTrack>),
      LocalTrack,
      PrefetchHooks Function()
    >;
typedef $$LocalAlbumsTableCreateCompanionBuilder =
    LocalAlbumsCompanion Function({
      required String id,
      required String json,
      required String search,
      Value<int> rowid,
    });
typedef $$LocalAlbumsTableUpdateCompanionBuilder =
    LocalAlbumsCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<String> search,
      Value<int> rowid,
    });

class $$LocalAlbumsTableFilterComposer
    extends Composer<_$LibraryDb, $LocalAlbumsTable> {
  $$LocalAlbumsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAlbumsTableOrderingComposer
    extends Composer<_$LibraryDb, $LocalAlbumsTable> {
  $$LocalAlbumsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAlbumsTableAnnotationComposer
    extends Composer<_$LibraryDb, $LocalAlbumsTable> {
  $$LocalAlbumsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get search =>
      $composableBuilder(column: $table.search, builder: (column) => column);
}

class $$LocalAlbumsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $LocalAlbumsTable,
          LocalAlbum,
          $$LocalAlbumsTableFilterComposer,
          $$LocalAlbumsTableOrderingComposer,
          $$LocalAlbumsTableAnnotationComposer,
          $$LocalAlbumsTableCreateCompanionBuilder,
          $$LocalAlbumsTableUpdateCompanionBuilder,
          (
            LocalAlbum,
            BaseReferences<_$LibraryDb, $LocalAlbumsTable, LocalAlbum>,
          ),
          LocalAlbum,
          PrefetchHooks Function()
        > {
  $$LocalAlbumsTableTableManager(_$LibraryDb db, $LocalAlbumsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAlbumsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAlbumsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAlbumsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> search = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAlbumsCompanion(
                id: id,
                json: json,
                search: search,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String search,
                Value<int> rowid = const Value.absent(),
              }) => LocalAlbumsCompanion.insert(
                id: id,
                json: json,
                search: search,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalAlbumsTable, LocalAlbum>(table),
                  BaseReferences<_$LibraryDb, $LocalAlbumsTable, LocalAlbum>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAlbumsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $LocalAlbumsTable,
      LocalAlbum,
      $$LocalAlbumsTableFilterComposer,
      $$LocalAlbumsTableOrderingComposer,
      $$LocalAlbumsTableAnnotationComposer,
      $$LocalAlbumsTableCreateCompanionBuilder,
      $$LocalAlbumsTableUpdateCompanionBuilder,
      (LocalAlbum, BaseReferences<_$LibraryDb, $LocalAlbumsTable, LocalAlbum>),
      LocalAlbum,
      PrefetchHooks Function()
    >;
typedef $$LocalArtistsTableCreateCompanionBuilder =
    LocalArtistsCompanion Function({
      required String id,
      required String json,
      required String search,
      Value<int> rowid,
    });
typedef $$LocalArtistsTableUpdateCompanionBuilder =
    LocalArtistsCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<String> search,
      Value<int> rowid,
    });

class $$LocalArtistsTableFilterComposer
    extends Composer<_$LibraryDb, $LocalArtistsTable> {
  $$LocalArtistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalArtistsTableOrderingComposer
    extends Composer<_$LibraryDb, $LocalArtistsTable> {
  $$LocalArtistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalArtistsTableAnnotationComposer
    extends Composer<_$LibraryDb, $LocalArtistsTable> {
  $$LocalArtistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get search =>
      $composableBuilder(column: $table.search, builder: (column) => column);
}

class $$LocalArtistsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $LocalArtistsTable,
          LocalArtist,
          $$LocalArtistsTableFilterComposer,
          $$LocalArtistsTableOrderingComposer,
          $$LocalArtistsTableAnnotationComposer,
          $$LocalArtistsTableCreateCompanionBuilder,
          $$LocalArtistsTableUpdateCompanionBuilder,
          (
            LocalArtist,
            BaseReferences<_$LibraryDb, $LocalArtistsTable, LocalArtist>,
          ),
          LocalArtist,
          PrefetchHooks Function()
        > {
  $$LocalArtistsTableTableManager(_$LibraryDb db, $LocalArtistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalArtistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalArtistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalArtistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String> search = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalArtistsCompanion(
                id: id,
                json: json,
                search: search,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required String search,
                Value<int> rowid = const Value.absent(),
              }) => LocalArtistsCompanion.insert(
                id: id,
                json: json,
                search: search,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalArtistsTable, LocalArtist>(table),
                  BaseReferences<_$LibraryDb, $LocalArtistsTable, LocalArtist>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalArtistsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $LocalArtistsTable,
      LocalArtist,
      $$LocalArtistsTableFilterComposer,
      $$LocalArtistsTableOrderingComposer,
      $$LocalArtistsTableAnnotationComposer,
      $$LocalArtistsTableCreateCompanionBuilder,
      $$LocalArtistsTableUpdateCompanionBuilder,
      (
        LocalArtist,
        BaseReferences<_$LibraryDb, $LocalArtistsTable, LocalArtist>,
      ),
      LocalArtist,
      PrefetchHooks Function()
    >;
typedef $$LocalPlaylistsTableCreateCompanionBuilder =
    LocalPlaylistsCompanion Function({
      required String id,
      required String json,
      required int version,
      required String search,
      Value<int> rowid,
    });
typedef $$LocalPlaylistsTableUpdateCompanionBuilder =
    LocalPlaylistsCompanion Function({
      Value<String> id,
      Value<String> json,
      Value<int> version,
      Value<String> search,
      Value<int> rowid,
    });

class $$LocalPlaylistsTableFilterComposer
    extends Composer<_$LibraryDb, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlaylistsTableOrderingComposer
    extends Composer<_$LibraryDb, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get search => $composableBuilder(
    column: $table.search,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlaylistsTableAnnotationComposer
    extends Composer<_$LibraryDb, $LocalPlaylistsTable> {
  $$LocalPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get search =>
      $composableBuilder(column: $table.search, builder: (column) => column);
}

class $$LocalPlaylistsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $LocalPlaylistsTable,
          LocalPlaylist,
          $$LocalPlaylistsTableFilterComposer,
          $$LocalPlaylistsTableOrderingComposer,
          $$LocalPlaylistsTableAnnotationComposer,
          $$LocalPlaylistsTableCreateCompanionBuilder,
          $$LocalPlaylistsTableUpdateCompanionBuilder,
          (
            LocalPlaylist,
            BaseReferences<_$LibraryDb, $LocalPlaylistsTable, LocalPlaylist>,
          ),
          LocalPlaylist,
          PrefetchHooks Function()
        > {
  $$LocalPlaylistsTableTableManager(_$LibraryDb db, $LocalPlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> search = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistsCompanion(
                id: id,
                json: json,
                version: version,
                search: search,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String json,
                required int version,
                required String search,
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistsCompanion.insert(
                id: id,
                json: json,
                version: version,
                search: search,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPlaylistsTable, LocalPlaylist>(table),
                  BaseReferences<
                    _$LibraryDb,
                    $LocalPlaylistsTable,
                    LocalPlaylist
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $LocalPlaylistsTable,
      LocalPlaylist,
      $$LocalPlaylistsTableFilterComposer,
      $$LocalPlaylistsTableOrderingComposer,
      $$LocalPlaylistsTableAnnotationComposer,
      $$LocalPlaylistsTableCreateCompanionBuilder,
      $$LocalPlaylistsTableUpdateCompanionBuilder,
      (
        LocalPlaylist,
        BaseReferences<_$LibraryDb, $LocalPlaylistsTable, LocalPlaylist>,
      ),
      LocalPlaylist,
      PrefetchHooks Function()
    >;
typedef $$LocalPlaylistItemsTableCreateCompanionBuilder =
    LocalPlaylistItemsCompanion Function({
      required String playlistId,
      required String itemId,
      required int position,
      required String trackId,
      Value<int> rowid,
    });
typedef $$LocalPlaylistItemsTableUpdateCompanionBuilder =
    LocalPlaylistItemsCompanion Function({
      Value<String> playlistId,
      Value<String> itemId,
      Value<int> position,
      Value<String> trackId,
      Value<int> rowid,
    });

class $$LocalPlaylistItemsTableFilterComposer
    extends Composer<_$LibraryDb, $LocalPlaylistItemsTable> {
  $$LocalPlaylistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlaylistItemsTableOrderingComposer
    extends Composer<_$LibraryDb, $LocalPlaylistItemsTable> {
  $$LocalPlaylistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlaylistItemsTableAnnotationComposer
    extends Composer<_$LibraryDb, $LocalPlaylistItemsTable> {
  $$LocalPlaylistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);
}

class $$LocalPlaylistItemsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $LocalPlaylistItemsTable,
          LocalPlaylistItem,
          $$LocalPlaylistItemsTableFilterComposer,
          $$LocalPlaylistItemsTableOrderingComposer,
          $$LocalPlaylistItemsTableAnnotationComposer,
          $$LocalPlaylistItemsTableCreateCompanionBuilder,
          $$LocalPlaylistItemsTableUpdateCompanionBuilder,
          (
            LocalPlaylistItem,
            BaseReferences<
              _$LibraryDb,
              $LocalPlaylistItemsTable,
              LocalPlaylistItem
            >,
          ),
          LocalPlaylistItem,
          PrefetchHooks Function()
        > {
  $$LocalPlaylistItemsTableTableManager(
    _$LibraryDb db,
    $LocalPlaylistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlaylistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlaylistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlaylistItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> playlistId = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistItemsCompanion(
                playlistId: playlistId,
                itemId: itemId,
                position: position,
                trackId: trackId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String playlistId,
                required String itemId,
                required int position,
                required String trackId,
                Value<int> rowid = const Value.absent(),
              }) => LocalPlaylistItemsCompanion.insert(
                playlistId: playlistId,
                itemId: itemId,
                position: position,
                trackId: trackId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPlaylistItemsTable, LocalPlaylistItem>(
                    table,
                  ),
                  BaseReferences<
                    _$LibraryDb,
                    $LocalPlaylistItemsTable,
                    LocalPlaylistItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlaylistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $LocalPlaylistItemsTable,
      LocalPlaylistItem,
      $$LocalPlaylistItemsTableFilterComposer,
      $$LocalPlaylistItemsTableOrderingComposer,
      $$LocalPlaylistItemsTableAnnotationComposer,
      $$LocalPlaylistItemsTableCreateCompanionBuilder,
      $$LocalPlaylistItemsTableUpdateCompanionBuilder,
      (
        LocalPlaylistItem,
        BaseReferences<
          _$LibraryDb,
          $LocalPlaylistItemsTable,
          LocalPlaylistItem
        >,
      ),
      LocalPlaylistItem,
      PrefetchHooks Function()
    >;
typedef $$LocalLyricsTableCreateCompanionBuilder =
    LocalLyricsCompanion Function({
      required String trackId,
      required String json,
      Value<String?> etag,
      Value<int> rowid,
    });
typedef $$LocalLyricsTableUpdateCompanionBuilder =
    LocalLyricsCompanion Function({
      Value<String> trackId,
      Value<String> json,
      Value<String?> etag,
      Value<int> rowid,
    });

class $$LocalLyricsTableFilterComposer
    extends Composer<_$LibraryDb, $LocalLyricsTable> {
  $$LocalLyricsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalLyricsTableOrderingComposer
    extends Composer<_$LibraryDb, $LocalLyricsTable> {
  $$LocalLyricsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalLyricsTableAnnotationComposer
    extends Composer<_$LibraryDb, $LocalLyricsTable> {
  $$LocalLyricsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);
}

class $$LocalLyricsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $LocalLyricsTable,
          LocalLyric,
          $$LocalLyricsTableFilterComposer,
          $$LocalLyricsTableOrderingComposer,
          $$LocalLyricsTableAnnotationComposer,
          $$LocalLyricsTableCreateCompanionBuilder,
          $$LocalLyricsTableUpdateCompanionBuilder,
          (
            LocalLyric,
            BaseReferences<_$LibraryDb, $LocalLyricsTable, LocalLyric>,
          ),
          LocalLyric,
          PrefetchHooks Function()
        > {
  $$LocalLyricsTableTableManager(_$LibraryDb db, $LocalLyricsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalLyricsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalLyricsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalLyricsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLyricsCompanion(
                trackId: trackId,
                json: json,
                etag: etag,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                required String json,
                Value<String?> etag = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalLyricsCompanion.insert(
                trackId: trackId,
                json: json,
                etag: etag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalLyricsTable, LocalLyric>(table),
                  BaseReferences<_$LibraryDb, $LocalLyricsTable, LocalLyric>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalLyricsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $LocalLyricsTable,
      LocalLyric,
      $$LocalLyricsTableFilterComposer,
      $$LocalLyricsTableOrderingComposer,
      $$LocalLyricsTableAnnotationComposer,
      $$LocalLyricsTableCreateCompanionBuilder,
      $$LocalLyricsTableUpdateCompanionBuilder,
      (LocalLyric, BaseReferences<_$LibraryDb, $LocalLyricsTable, LocalLyric>),
      LocalLyric,
      PrefetchHooks Function()
    >;
typedef $$DownloadsTableCreateCompanionBuilder = DownloadsCompanion Function({
  required String id,
  required String trackId,
  required String quality,
  required String state,
  Value<String?> renditionId,
  Value<String?> mediaVersion,
  Value<int?> bytesTotal,
  Value<int> bytesDone,
  Value<String?> sha256,
  Value<String?> etag,
  Value<String?> ext,
  Value<String?> errorCode,
  Value<int> attempts,
  Value<bool> integrityRetried,
  Value<int?> notBefore,
  Value<bool> stale,
  Value<bool> locked,
  Value<String?> verified,
  Value<String?> fileName,
  required int createdAt,
  Value<int?> completedAt,
  Value<int> rowid,
});
typedef $$DownloadsTableUpdateCompanionBuilder = DownloadsCompanion Function({
  Value<String> id,
  Value<String> trackId,
  Value<String> quality,
  Value<String> state,
  Value<String?> renditionId,
  Value<String?> mediaVersion,
  Value<int?> bytesTotal,
  Value<int> bytesDone,
  Value<String?> sha256,
  Value<String?> etag,
  Value<String?> ext,
  Value<String?> errorCode,
  Value<int> attempts,
  Value<bool> integrityRetried,
  Value<int?> notBefore,
  Value<bool> stale,
  Value<bool> locked,
  Value<String?> verified,
  Value<String?> fileName,
  Value<int> createdAt,
  Value<int?> completedAt,
  Value<int> rowid,
});

class $$DownloadsTableFilterComposer
    extends Composer<_$LibraryDb, $DownloadsTable> {
  $$DownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get renditionId => $composableBuilder(
    column: $table.renditionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaVersion => $composableBuilder(
    column: $table.mediaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ext => $composableBuilder(
    column: $table.ext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get integrityRetried => $composableBuilder(
    column: $table.integrityRetried,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notBefore => $composableBuilder(
    column: $table.notBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get stale => $composableBuilder(
    column: $table.stale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadsTableOrderingComposer
    extends Composer<_$LibraryDb, $DownloadsTable> {
  $$DownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackId => $composableBuilder(
    column: $table.trackId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get renditionId => $composableBuilder(
    column: $table.renditionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaVersion => $composableBuilder(
    column: $table.mediaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesDone => $composableBuilder(
    column: $table.bytesDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etag => $composableBuilder(
    column: $table.etag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ext => $composableBuilder(
    column: $table.ext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorCode => $composableBuilder(
    column: $table.errorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get integrityRetried => $composableBuilder(
    column: $table.integrityRetried,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notBefore => $composableBuilder(
    column: $table.notBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get stale => $composableBuilder(
    column: $table.stale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get locked => $composableBuilder(
    column: $table.locked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verified => $composableBuilder(
    column: $table.verified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadsTableAnnotationComposer
    extends Composer<_$LibraryDb, $DownloadsTable> {
  $$DownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trackId =>
      $composableBuilder(column: $table.trackId, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get renditionId => $composableBuilder(
    column: $table.renditionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaVersion => $composableBuilder(
    column: $table.mediaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesTotal => $composableBuilder(
    column: $table.bytesTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesDone =>
      $composableBuilder(column: $table.bytesDone, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get etag =>
      $composableBuilder(column: $table.etag, builder: (column) => column);

  GeneratedColumn<String> get ext =>
      $composableBuilder(column: $table.ext, builder: (column) => column);

  GeneratedColumn<String> get errorCode =>
      $composableBuilder(column: $table.errorCode, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<bool> get integrityRetried => $composableBuilder(
    column: $table.integrityRetried,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notBefore =>
      $composableBuilder(column: $table.notBefore, builder: (column) => column);

  GeneratedColumn<bool> get stale =>
      $composableBuilder(column: $table.stale, builder: (column) => column);

  GeneratedColumn<bool> get locked =>
      $composableBuilder(column: $table.locked, builder: (column) => column);

  GeneratedColumn<String> get verified =>
      $composableBuilder(column: $table.verified, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$DownloadsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $DownloadsTable,
          DownloadRow,
          $$DownloadsTableFilterComposer,
          $$DownloadsTableOrderingComposer,
          $$DownloadsTableAnnotationComposer,
          $$DownloadsTableCreateCompanionBuilder,
          $$DownloadsTableUpdateCompanionBuilder,
          (
            DownloadRow,
            BaseReferences<_$LibraryDb, $DownloadsTable, DownloadRow>,
          ),
          DownloadRow,
          PrefetchHooks Function()
        > {
  $$DownloadsTableTableManager(_$LibraryDb db, $DownloadsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> trackId = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> renditionId = const Value.absent(),
                Value<String?> mediaVersion = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                Value<int> bytesDone = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> ext = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> integrityRetried = const Value.absent(),
                Value<int?> notBefore = const Value.absent(),
                Value<bool> stale = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                Value<String?> verified = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion(
                id: id,
                trackId: trackId,
                quality: quality,
                state: state,
                renditionId: renditionId,
                mediaVersion: mediaVersion,
                bytesTotal: bytesTotal,
                bytesDone: bytesDone,
                sha256: sha256,
                etag: etag,
                ext: ext,
                errorCode: errorCode,
                attempts: attempts,
                integrityRetried: integrityRetried,
                notBefore: notBefore,
                stale: stale,
                locked: locked,
                verified: verified,
                fileName: fileName,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String trackId,
                required String quality,
                required String state,
                Value<String?> renditionId = const Value.absent(),
                Value<String?> mediaVersion = const Value.absent(),
                Value<int?> bytesTotal = const Value.absent(),
                Value<int> bytesDone = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<String?> etag = const Value.absent(),
                Value<String?> ext = const Value.absent(),
                Value<String?> errorCode = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> integrityRetried = const Value.absent(),
                Value<int?> notBefore = const Value.absent(),
                Value<bool> stale = const Value.absent(),
                Value<bool> locked = const Value.absent(),
                Value<String?> verified = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                required int createdAt,
                Value<int?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadsCompanion.insert(
                id: id,
                trackId: trackId,
                quality: quality,
                state: state,
                renditionId: renditionId,
                mediaVersion: mediaVersion,
                bytesTotal: bytesTotal,
                bytesDone: bytesDone,
                sha256: sha256,
                etag: etag,
                ext: ext,
                errorCode: errorCode,
                attempts: attempts,
                integrityRetried: integrityRetried,
                notBefore: notBefore,
                stale: stale,
                locked: locked,
                verified: verified,
                fileName: fileName,
                createdAt: createdAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadsTable, DownloadRow>(table),
                  BaseReferences<_$LibraryDb, $DownloadsTable, DownloadRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $DownloadsTable,
      DownloadRow,
      $$DownloadsTableFilterComposer,
      $$DownloadsTableOrderingComposer,
      $$DownloadsTableAnnotationComposer,
      $$DownloadsTableCreateCompanionBuilder,
      $$DownloadsTableUpdateCompanionBuilder,
      (DownloadRow, BaseReferences<_$LibraryDb, $DownloadsTable, DownloadRow>),
      DownloadRow,
      PrefetchHooks Function()
    >;
typedef $$DownloadRequestsTableCreateCompanionBuilder =
    DownloadRequestsCompanion Function({
      required String downloadId,
      required String kind,
      required String refId,
      Value<int> rowid,
    });
typedef $$DownloadRequestsTableUpdateCompanionBuilder =
    DownloadRequestsCompanion Function({
      Value<String> downloadId,
      Value<String> kind,
      Value<String> refId,
      Value<int> rowid,
    });

class $$DownloadRequestsTableFilterComposer
    extends Composer<_$LibraryDb, $DownloadRequestsTable> {
  $$DownloadRequestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get downloadId => $composableBuilder(
    column: $table.downloadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadRequestsTableOrderingComposer
    extends Composer<_$LibraryDb, $DownloadRequestsTable> {
  $$DownloadRequestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get downloadId => $composableBuilder(
    column: $table.downloadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadRequestsTableAnnotationComposer
    extends Composer<_$LibraryDb, $DownloadRequestsTable> {
  $$DownloadRequestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get downloadId => $composableBuilder(
    column: $table.downloadId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);
}

class $$DownloadRequestsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $DownloadRequestsTable,
          DownloadRequest,
          $$DownloadRequestsTableFilterComposer,
          $$DownloadRequestsTableOrderingComposer,
          $$DownloadRequestsTableAnnotationComposer,
          $$DownloadRequestsTableCreateCompanionBuilder,
          $$DownloadRequestsTableUpdateCompanionBuilder,
          (
            DownloadRequest,
            BaseReferences<
              _$LibraryDb,
              $DownloadRequestsTable,
              DownloadRequest
            >,
          ),
          DownloadRequest,
          PrefetchHooks Function()
        > {
  $$DownloadRequestsTableTableManager(
    _$LibraryDb db,
    $DownloadRequestsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadRequestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadRequestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadRequestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> downloadId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadRequestsCompanion(
                downloadId: downloadId,
                kind: kind,
                refId: refId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String downloadId,
                required String kind,
                required String refId,
                Value<int> rowid = const Value.absent(),
              }) => DownloadRequestsCompanion.insert(
                downloadId: downloadId,
                kind: kind,
                refId: refId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadRequestsTable, DownloadRequest>(table),
                  BaseReferences<
                    _$LibraryDb,
                    $DownloadRequestsTable,
                    DownloadRequest
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadRequestsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $DownloadRequestsTable,
      DownloadRequest,
      $$DownloadRequestsTableFilterComposer,
      $$DownloadRequestsTableOrderingComposer,
      $$DownloadRequestsTableAnnotationComposer,
      $$DownloadRequestsTableCreateCompanionBuilder,
      $$DownloadRequestsTableUpdateCompanionBuilder,
      (
        DownloadRequest,
        BaseReferences<_$LibraryDb, $DownloadRequestsTable, DownloadRequest>,
      ),
      DownloadRequest,
      PrefetchHooks Function()
    >;
typedef $$DownloadGroupsTableCreateCompanionBuilder =
    DownloadGroupsCompanion Function({
      required String kind,
      required String refId,
      required String quality,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$DownloadGroupsTableUpdateCompanionBuilder =
    DownloadGroupsCompanion Function({
      Value<String> kind,
      Value<String> refId,
      Value<String> quality,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$DownloadGroupsTableFilterComposer
    extends Composer<_$LibraryDb, $DownloadGroupsTable> {
  $$DownloadGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DownloadGroupsTableOrderingComposer
    extends Composer<_$LibraryDb, $DownloadGroupsTable> {
  $$DownloadGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refId => $composableBuilder(
    column: $table.refId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DownloadGroupsTableAnnotationComposer
    extends Composer<_$LibraryDb, $DownloadGroupsTable> {
  $$DownloadGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get refId =>
      $composableBuilder(column: $table.refId, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DownloadGroupsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $DownloadGroupsTable,
          DownloadGroup,
          $$DownloadGroupsTableFilterComposer,
          $$DownloadGroupsTableOrderingComposer,
          $$DownloadGroupsTableAnnotationComposer,
          $$DownloadGroupsTableCreateCompanionBuilder,
          $$DownloadGroupsTableUpdateCompanionBuilder,
          (
            DownloadGroup,
            BaseReferences<_$LibraryDb, $DownloadGroupsTable, DownloadGroup>,
          ),
          DownloadGroup,
          PrefetchHooks Function()
        > {
  $$DownloadGroupsTableTableManager(_$LibraryDb db, $DownloadGroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DownloadGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DownloadGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DownloadGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> refId = const Value.absent(),
                Value<String> quality = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DownloadGroupsCompanion(
                kind: kind,
                refId: refId,
                quality: quality,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String refId,
                required String quality,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => DownloadGroupsCompanion.insert(
                kind: kind,
                refId: refId,
                quality: quality,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DownloadGroupsTable, DownloadGroup>(table),
                  BaseReferences<
                    _$LibraryDb,
                    $DownloadGroupsTable,
                    DownloadGroup
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DownloadGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $DownloadGroupsTable,
      DownloadGroup,
      $$DownloadGroupsTableFilterComposer,
      $$DownloadGroupsTableOrderingComposer,
      $$DownloadGroupsTableAnnotationComposer,
      $$DownloadGroupsTableCreateCompanionBuilder,
      $$DownloadGroupsTableUpdateCompanionBuilder,
      (
        DownloadGroup,
        BaseReferences<_$LibraryDb, $DownloadGroupsTable, DownloadGroup>,
      ),
      DownloadGroup,
      PrefetchHooks Function()
    >;
typedef $$PendingOpsTableCreateCompanionBuilder = PendingOpsCompanion Function({
  Value<int> seq,
  required String playlistId,
  required String opsJson,
  required String idempotencyKey,
  required int createdAt,
});
typedef $$PendingOpsTableUpdateCompanionBuilder = PendingOpsCompanion Function({
  Value<int> seq,
  Value<String> playlistId,
  Value<String> opsJson,
  Value<String> idempotencyKey,
  Value<int> createdAt,
});

class $$PendingOpsTableFilterComposer
    extends Composer<_$LibraryDb, $PendingOpsTable> {
  $$PendingOpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opsJson => $composableBuilder(
    column: $table.opsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOpsTableOrderingComposer
    extends Composer<_$LibraryDb, $PendingOpsTable> {
  $$PendingOpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opsJson => $composableBuilder(
    column: $table.opsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOpsTableAnnotationComposer
    extends Composer<_$LibraryDb, $PendingOpsTable> {
  $$PendingOpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get opsJson =>
      $composableBuilder(column: $table.opsJson, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingOpsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $PendingOpsTable,
          PendingOp,
          $$PendingOpsTableFilterComposer,
          $$PendingOpsTableOrderingComposer,
          $$PendingOpsTableAnnotationComposer,
          $$PendingOpsTableCreateCompanionBuilder,
          $$PendingOpsTableUpdateCompanionBuilder,
          (PendingOp, BaseReferences<_$LibraryDb, $PendingOpsTable, PendingOp>),
          PendingOp,
          PrefetchHooks Function()
        > {
  $$PendingOpsTableTableManager(_$LibraryDb db, $PendingOpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<String> opsJson = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => PendingOpsCompanion(
                seq: seq,
                playlistId: playlistId,
                opsJson: opsJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String playlistId,
                required String opsJson,
                required String idempotencyKey,
                required int createdAt,
              }) => PendingOpsCompanion.insert(
                seq: seq,
                playlistId: playlistId,
                opsJson: opsJson,
                idempotencyKey: idempotencyKey,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingOpsTable, PendingOp>(table),
                  BaseReferences<_$LibraryDb, $PendingOpsTable, PendingOp>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOpsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $PendingOpsTable,
      PendingOp,
      $$PendingOpsTableFilterComposer,
      $$PendingOpsTableOrderingComposer,
      $$PendingOpsTableAnnotationComposer,
      $$PendingOpsTableCreateCompanionBuilder,
      $$PendingOpsTableUpdateCompanionBuilder,
      (PendingOp, BaseReferences<_$LibraryDb, $PendingOpsTable, PendingOp>),
      PendingOp,
      PrefetchHooks Function()
    >;
typedef $$PendingPlayEventsTableCreateCompanionBuilder =
    PendingPlayEventsCompanion Function({
      required String eventId,
      required String json,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$PendingPlayEventsTableUpdateCompanionBuilder =
    PendingPlayEventsCompanion Function({
      Value<String> eventId,
      Value<String> json,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$PendingPlayEventsTableFilterComposer
    extends Composer<_$LibraryDb, $PendingPlayEventsTable> {
  $$PendingPlayEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingPlayEventsTableOrderingComposer
    extends Composer<_$LibraryDb, $PendingPlayEventsTable> {
  $$PendingPlayEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingPlayEventsTableAnnotationComposer
    extends Composer<_$LibraryDb, $PendingPlayEventsTable> {
  $$PendingPlayEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingPlayEventsTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $PendingPlayEventsTable,
          PendingPlayEvent,
          $$PendingPlayEventsTableFilterComposer,
          $$PendingPlayEventsTableOrderingComposer,
          $$PendingPlayEventsTableAnnotationComposer,
          $$PendingPlayEventsTableCreateCompanionBuilder,
          $$PendingPlayEventsTableUpdateCompanionBuilder,
          (
            PendingPlayEvent,
            BaseReferences<
              _$LibraryDb,
              $PendingPlayEventsTable,
              PendingPlayEvent
            >,
          ),
          PendingPlayEvent,
          PrefetchHooks Function()
        > {
  $$PendingPlayEventsTableTableManager(
    _$LibraryDb db,
    $PendingPlayEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingPlayEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingPlayEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingPlayEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PendingPlayEventsCompanion(
                eventId: eventId,
                json: json,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String json,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PendingPlayEventsCompanion.insert(
                eventId: eventId,
                json: json,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PendingPlayEventsTable, PendingPlayEvent>(table),
                  BaseReferences<
                    _$LibraryDb,
                    $PendingPlayEventsTable,
                    PendingPlayEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingPlayEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $PendingPlayEventsTable,
      PendingPlayEvent,
      $$PendingPlayEventsTableFilterComposer,
      $$PendingPlayEventsTableOrderingComposer,
      $$PendingPlayEventsTableAnnotationComposer,
      $$PendingPlayEventsTableCreateCompanionBuilder,
      $$PendingPlayEventsTableUpdateCompanionBuilder,
      (
        PendingPlayEvent,
        BaseReferences<_$LibraryDb, $PendingPlayEventsTable, PendingPlayEvent>,
      ),
      PendingPlayEvent,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$LibraryDb, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$LibraryDb, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$LibraryDb, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$LibraryDb,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$LibraryDb, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$LibraryDb db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<_$LibraryDb, $SyncStateTable, SyncStateData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDb,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$LibraryDb, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;

class $LibraryDbManager {
  final _$LibraryDb _db;
  $LibraryDbManager(this._db);
  $$LocalTracksTableTableManager get localTracks =>
      $$LocalTracksTableTableManager(_db, _db.localTracks);
  $$LocalAlbumsTableTableManager get localAlbums =>
      $$LocalAlbumsTableTableManager(_db, _db.localAlbums);
  $$LocalArtistsTableTableManager get localArtists =>
      $$LocalArtistsTableTableManager(_db, _db.localArtists);
  $$LocalPlaylistsTableTableManager get localPlaylists =>
      $$LocalPlaylistsTableTableManager(_db, _db.localPlaylists);
  $$LocalPlaylistItemsTableTableManager get localPlaylistItems =>
      $$LocalPlaylistItemsTableTableManager(_db, _db.localPlaylistItems);
  $$LocalLyricsTableTableManager get localLyrics =>
      $$LocalLyricsTableTableManager(_db, _db.localLyrics);
  $$DownloadsTableTableManager get downloads =>
      $$DownloadsTableTableManager(_db, _db.downloads);
  $$DownloadRequestsTableTableManager get downloadRequests =>
      $$DownloadRequestsTableTableManager(_db, _db.downloadRequests);
  $$DownloadGroupsTableTableManager get downloadGroups =>
      $$DownloadGroupsTableTableManager(_db, _db.downloadGroups);
  $$PendingOpsTableTableManager get pendingOps =>
      $$PendingOpsTableTableManager(_db, _db.pendingOps);
  $$PendingPlayEventsTableTableManager get pendingPlayEvents =>
      $$PendingPlayEventsTableTableManager(_db, _db.pendingPlayEvents);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
