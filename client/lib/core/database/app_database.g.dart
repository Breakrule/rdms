// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalDocumentsTable extends LocalDocuments
    with TableInfo<$LocalDocumentsTable, LocalDocument> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentNumberMeta = const VerificationMeta(
    'documentNumber',
  );
  @override
  late final GeneratedColumn<String> documentNumber = GeneratedColumn<String>(
    'document_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentDateMeta = const VerificationMeta(
    'documentDate',
  );
  @override
  late final GeneratedColumn<DateTime> documentDate = GeneratedColumn<DateTime>(
    'document_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fiscalYearMeta = const VerificationMeta(
    'fiscalYear',
  );
  @override
  late final GeneratedColumn<int> fiscalYear = GeneratedColumn<int>(
    'fiscal_year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localFilePathMeta = const VerificationMeta(
    'localFilePath',
  );
  @override
  late final GeneratedColumn<String> localFilePath = GeneratedColumn<String>(
    'local_file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256HashMeta = const VerificationMeta(
    'sha256Hash',
  );
  @override
  late final GeneratedColumn<String> sha256Hash = GeneratedColumn<String>(
    'sha256_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local_only'),
  );
  static const VerificationMeta _gdriveFileIdMeta = const VerificationMeta(
    'gdriveFileId',
  );
  @override
  late final GeneratedColumn<String> gdriveFileId = GeneratedColumn<String>(
    'gdrive_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteBackendIdMeta = const VerificationMeta(
    'remoteBackendId',
  );
  @override
  late final GeneratedColumn<String> remoteBackendId = GeneratedColumn<String>(
    'remote_backend_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trashedAtMeta = const VerificationMeta(
    'trashedAt',
  );
  @override
  late final GeneratedColumn<DateTime> trashedAt = GeneratedColumn<DateTime>(
    'trashed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _accountBindingMeta = const VerificationMeta(
    'accountBinding',
  );
  @override
  late final GeneratedColumn<String> accountBinding = GeneratedColumn<String>(
    'account_binding',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalFileNameMeta = const VerificationMeta(
    'originalFileName',
  );
  @override
  late final GeneratedColumn<String> originalFileName = GeneratedColumn<String>(
    'original_file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    documentNumber,
    category,
    documentDate,
    fiscalYear,
    localFilePath,
    fileName,
    fileSizeBytes,
    mimeType,
    sha256Hash,
    extractedText,
    syncStatus,
    gdriveFileId,
    remoteBackendId,
    trashedAt,
    baseRevision,
    accountBinding,
    isFavorite,
    notes,
    originalFileName,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDocument> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('document_number')) {
      context.handle(
        _documentNumberMeta,
        documentNumber.isAcceptableOrUnknown(
          data['document_number']!,
          _documentNumberMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('document_date')) {
      context.handle(
        _documentDateMeta,
        documentDate.isAcceptableOrUnknown(
          data['document_date']!,
          _documentDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentDateMeta);
    }
    if (data.containsKey('fiscal_year')) {
      context.handle(
        _fiscalYearMeta,
        fiscalYear.isAcceptableOrUnknown(data['fiscal_year']!, _fiscalYearMeta),
      );
    } else if (isInserting) {
      context.missing(_fiscalYearMeta);
    }
    if (data.containsKey('local_file_path')) {
      context.handle(
        _localFilePathMeta,
        localFilePath.isAcceptableOrUnknown(
          data['local_file_path']!,
          _localFilePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localFilePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('sha256_hash')) {
      context.handle(
        _sha256HashMeta,
        sha256Hash.isAcceptableOrUnknown(data['sha256_hash']!, _sha256HashMeta),
      );
    } else if (isInserting) {
      context.missing(_sha256HashMeta);
    }
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('gdrive_file_id')) {
      context.handle(
        _gdriveFileIdMeta,
        gdriveFileId.isAcceptableOrUnknown(
          data['gdrive_file_id']!,
          _gdriveFileIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_backend_id')) {
      context.handle(
        _remoteBackendIdMeta,
        remoteBackendId.isAcceptableOrUnknown(
          data['remote_backend_id']!,
          _remoteBackendIdMeta,
        ),
      );
    }
    if (data.containsKey('trashed_at')) {
      context.handle(
        _trashedAtMeta,
        trashedAt.isAcceptableOrUnknown(data['trashed_at']!, _trashedAtMeta),
      );
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('account_binding')) {
      context.handle(
        _accountBindingMeta,
        accountBinding.isAcceptableOrUnknown(
          data['account_binding']!,
          _accountBindingMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('original_file_name')) {
      context.handle(
        _originalFileNameMeta,
        originalFileName.isAcceptableOrUnknown(
          data['original_file_name']!,
          _originalFileNameMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDocument map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDocument(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      documentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_number'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      documentDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}document_date'],
      )!,
      fiscalYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fiscal_year'],
      )!,
      localFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_file_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sha256Hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256_hash'],
      )!,
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      gdriveFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}gdrive_file_id'],
      ),
      remoteBackendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_backend_id'],
      ),
      trashedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}trashed_at'],
      ),
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      )!,
      accountBinding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_binding'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      originalFileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_file_name'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalDocumentsTable createAlias(String alias) {
    return $LocalDocumentsTable(attachedDatabase, alias);
  }
}

class LocalDocument extends DataClass implements Insertable<LocalDocument> {
  final String id;
  final String title;
  final String? documentNumber;
  final String category;
  final DateTime documentDate;
  final int fiscalYear;
  final String localFilePath;
  final String fileName;
  final int fileSizeBytes;
  final String mimeType;
  final String sha256Hash;
  final String? extractedText;
  final String syncStatus;
  final String? gdriveFileId;
  final String? remoteBackendId;

  /// Soft-delete marker introduced in Phase 1.4. When non-null the row
  /// lives in the local recycle bin: watch/search/count default to
  /// excluding it, and the managed file remains on disk so [restore]
  /// can re-activate the row without touching binaries or Drive IDs.
  /// Permanent removal (purge) sets this to a real timestamp AND
  /// schedules the managed file for deletion via the operation journal.
  final DateTime? trashedAt;

  /// Monotonic local revision counter (Phase 2.6). Advanced on every
  /// metadata-only change so the server can distinguish "same content,
  /// new description" from a hash-only reconcile.
  final int baseRevision;

  /// Opaque account binding captured when the document first enters a
  /// sync destination. Phase 2.3 refuses to process queued jobs whose
  /// [accountBinding] no longer matches the signed-in user.
  final String? accountBinding;

  /// Phase 4.3 per-device favorite marker. Device-local by design:
  /// favorites are a viewing preference, not shared record data, so
  /// they never enter the sync payload or the portable manifest.
  final bool isFavorite;

  /// Phase 4.1 free-form note surfaced in details and replicated via
  /// the v2 payload. Distinct from extractedText (document body text).
  final String? notes;

  /// Phase 4.4 the file's name BEFORE it was renamed to the managed
  /// convention. fileName stays authoritative for the on-disk layout;
  /// this is user-facing provenance and belongs in the backup manifest.
  final String? originalFileName;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalDocument({
    required this.id,
    required this.title,
    this.documentNumber,
    required this.category,
    required this.documentDate,
    required this.fiscalYear,
    required this.localFilePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.mimeType,
    required this.sha256Hash,
    this.extractedText,
    required this.syncStatus,
    this.gdriveFileId,
    this.remoteBackendId,
    this.trashedAt,
    required this.baseRevision,
    this.accountBinding,
    required this.isFavorite,
    this.notes,
    this.originalFileName,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || documentNumber != null) {
      map['document_number'] = Variable<String>(documentNumber);
    }
    map['category'] = Variable<String>(category);
    map['document_date'] = Variable<DateTime>(documentDate);
    map['fiscal_year'] = Variable<int>(fiscalYear);
    map['local_file_path'] = Variable<String>(localFilePath);
    map['file_name'] = Variable<String>(fileName);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['mime_type'] = Variable<String>(mimeType);
    map['sha256_hash'] = Variable<String>(sha256Hash);
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || gdriveFileId != null) {
      map['gdrive_file_id'] = Variable<String>(gdriveFileId);
    }
    if (!nullToAbsent || remoteBackendId != null) {
      map['remote_backend_id'] = Variable<String>(remoteBackendId);
    }
    if (!nullToAbsent || trashedAt != null) {
      map['trashed_at'] = Variable<DateTime>(trashedAt);
    }
    map['base_revision'] = Variable<int>(baseRevision);
    if (!nullToAbsent || accountBinding != null) {
      map['account_binding'] = Variable<String>(accountBinding);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || originalFileName != null) {
      map['original_file_name'] = Variable<String>(originalFileName);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalDocumentsCompanion toCompanion(bool nullToAbsent) {
    return LocalDocumentsCompanion(
      id: Value(id),
      title: Value(title),
      documentNumber: documentNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(documentNumber),
      category: Value(category),
      documentDate: Value(documentDate),
      fiscalYear: Value(fiscalYear),
      localFilePath: Value(localFilePath),
      fileName: Value(fileName),
      fileSizeBytes: Value(fileSizeBytes),
      mimeType: Value(mimeType),
      sha256Hash: Value(sha256Hash),
      extractedText: extractedText == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedText),
      syncStatus: Value(syncStatus),
      gdriveFileId: gdriveFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(gdriveFileId),
      remoteBackendId: remoteBackendId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteBackendId),
      trashedAt: trashedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(trashedAt),
      baseRevision: Value(baseRevision),
      accountBinding: accountBinding == null && nullToAbsent
          ? const Value.absent()
          : Value(accountBinding),
      isFavorite: Value(isFavorite),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      originalFileName: originalFileName == null && nullToAbsent
          ? const Value.absent()
          : Value(originalFileName),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDocument.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDocument(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      documentNumber: serializer.fromJson<String?>(json['documentNumber']),
      category: serializer.fromJson<String>(json['category']),
      documentDate: serializer.fromJson<DateTime>(json['documentDate']),
      fiscalYear: serializer.fromJson<int>(json['fiscalYear']),
      localFilePath: serializer.fromJson<String>(json['localFilePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sha256Hash: serializer.fromJson<String>(json['sha256Hash']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      gdriveFileId: serializer.fromJson<String?>(json['gdriveFileId']),
      remoteBackendId: serializer.fromJson<String?>(json['remoteBackendId']),
      trashedAt: serializer.fromJson<DateTime?>(json['trashedAt']),
      baseRevision: serializer.fromJson<int>(json['baseRevision']),
      accountBinding: serializer.fromJson<String?>(json['accountBinding']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      notes: serializer.fromJson<String?>(json['notes']),
      originalFileName: serializer.fromJson<String?>(json['originalFileName']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'documentNumber': serializer.toJson<String?>(documentNumber),
      'category': serializer.toJson<String>(category),
      'documentDate': serializer.toJson<DateTime>(documentDate),
      'fiscalYear': serializer.toJson<int>(fiscalYear),
      'localFilePath': serializer.toJson<String>(localFilePath),
      'fileName': serializer.toJson<String>(fileName),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'sha256Hash': serializer.toJson<String>(sha256Hash),
      'extractedText': serializer.toJson<String?>(extractedText),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'gdriveFileId': serializer.toJson<String?>(gdriveFileId),
      'remoteBackendId': serializer.toJson<String?>(remoteBackendId),
      'trashedAt': serializer.toJson<DateTime?>(trashedAt),
      'baseRevision': serializer.toJson<int>(baseRevision),
      'accountBinding': serializer.toJson<String?>(accountBinding),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'notes': serializer.toJson<String?>(notes),
      'originalFileName': serializer.toJson<String?>(originalFileName),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDocument copyWith({
    String? id,
    String? title,
    Value<String?> documentNumber = const Value.absent(),
    String? category,
    DateTime? documentDate,
    int? fiscalYear,
    String? localFilePath,
    String? fileName,
    int? fileSizeBytes,
    String? mimeType,
    String? sha256Hash,
    Value<String?> extractedText = const Value.absent(),
    String? syncStatus,
    Value<String?> gdriveFileId = const Value.absent(),
    Value<String?> remoteBackendId = const Value.absent(),
    Value<DateTime?> trashedAt = const Value.absent(),
    int? baseRevision,
    Value<String?> accountBinding = const Value.absent(),
    bool? isFavorite,
    Value<String?> notes = const Value.absent(),
    Value<String?> originalFileName = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalDocument(
    id: id ?? this.id,
    title: title ?? this.title,
    documentNumber: documentNumber.present
        ? documentNumber.value
        : this.documentNumber,
    category: category ?? this.category,
    documentDate: documentDate ?? this.documentDate,
    fiscalYear: fiscalYear ?? this.fiscalYear,
    localFilePath: localFilePath ?? this.localFilePath,
    fileName: fileName ?? this.fileName,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    mimeType: mimeType ?? this.mimeType,
    sha256Hash: sha256Hash ?? this.sha256Hash,
    extractedText: extractedText.present
        ? extractedText.value
        : this.extractedText,
    syncStatus: syncStatus ?? this.syncStatus,
    gdriveFileId: gdriveFileId.present ? gdriveFileId.value : this.gdriveFileId,
    remoteBackendId: remoteBackendId.present
        ? remoteBackendId.value
        : this.remoteBackendId,
    trashedAt: trashedAt.present ? trashedAt.value : this.trashedAt,
    baseRevision: baseRevision ?? this.baseRevision,
    accountBinding: accountBinding.present
        ? accountBinding.value
        : this.accountBinding,
    isFavorite: isFavorite ?? this.isFavorite,
    notes: notes.present ? notes.value : this.notes,
    originalFileName: originalFileName.present
        ? originalFileName.value
        : this.originalFileName,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalDocument copyWithCompanion(LocalDocumentsCompanion data) {
    return LocalDocument(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      documentNumber: data.documentNumber.present
          ? data.documentNumber.value
          : this.documentNumber,
      category: data.category.present ? data.category.value : this.category,
      documentDate: data.documentDate.present
          ? data.documentDate.value
          : this.documentDate,
      fiscalYear: data.fiscalYear.present
          ? data.fiscalYear.value
          : this.fiscalYear,
      localFilePath: data.localFilePath.present
          ? data.localFilePath.value
          : this.localFilePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sha256Hash: data.sha256Hash.present
          ? data.sha256Hash.value
          : this.sha256Hash,
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      gdriveFileId: data.gdriveFileId.present
          ? data.gdriveFileId.value
          : this.gdriveFileId,
      remoteBackendId: data.remoteBackendId.present
          ? data.remoteBackendId.value
          : this.remoteBackendId,
      trashedAt: data.trashedAt.present ? data.trashedAt.value : this.trashedAt,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      accountBinding: data.accountBinding.present
          ? data.accountBinding.value
          : this.accountBinding,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      notes: data.notes.present ? data.notes.value : this.notes,
      originalFileName: data.originalFileName.present
          ? data.originalFileName.value
          : this.originalFileName,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDocument(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('category: $category, ')
          ..write('documentDate: $documentDate, ')
          ..write('fiscalYear: $fiscalYear, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('extractedText: $extractedText, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('gdriveFileId: $gdriveFileId, ')
          ..write('remoteBackendId: $remoteBackendId, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('accountBinding: $accountBinding, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('notes: $notes, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    documentNumber,
    category,
    documentDate,
    fiscalYear,
    localFilePath,
    fileName,
    fileSizeBytes,
    mimeType,
    sha256Hash,
    extractedText,
    syncStatus,
    gdriveFileId,
    remoteBackendId,
    trashedAt,
    baseRevision,
    accountBinding,
    isFavorite,
    notes,
    originalFileName,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDocument &&
          other.id == this.id &&
          other.title == this.title &&
          other.documentNumber == this.documentNumber &&
          other.category == this.category &&
          other.documentDate == this.documentDate &&
          other.fiscalYear == this.fiscalYear &&
          other.localFilePath == this.localFilePath &&
          other.fileName == this.fileName &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.sha256Hash == this.sha256Hash &&
          other.extractedText == this.extractedText &&
          other.syncStatus == this.syncStatus &&
          other.gdriveFileId == this.gdriveFileId &&
          other.remoteBackendId == this.remoteBackendId &&
          other.trashedAt == this.trashedAt &&
          other.baseRevision == this.baseRevision &&
          other.accountBinding == this.accountBinding &&
          other.isFavorite == this.isFavorite &&
          other.notes == this.notes &&
          other.originalFileName == this.originalFileName &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalDocumentsCompanion extends UpdateCompanion<LocalDocument> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> documentNumber;
  final Value<String> category;
  final Value<DateTime> documentDate;
  final Value<int> fiscalYear;
  final Value<String> localFilePath;
  final Value<String> fileName;
  final Value<int> fileSizeBytes;
  final Value<String> mimeType;
  final Value<String> sha256Hash;
  final Value<String?> extractedText;
  final Value<String> syncStatus;
  final Value<String?> gdriveFileId;
  final Value<String?> remoteBackendId;
  final Value<DateTime?> trashedAt;
  final Value<int> baseRevision;
  final Value<String?> accountBinding;
  final Value<bool> isFavorite;
  final Value<String?> notes;
  final Value<String?> originalFileName;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalDocumentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.category = const Value.absent(),
    this.documentDate = const Value.absent(),
    this.fiscalYear = const Value.absent(),
    this.localFilePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sha256Hash = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.gdriveFileId = const Value.absent(),
    this.remoteBackendId = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.accountBinding = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.notes = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDocumentsCompanion.insert({
    required String id,
    required String title,
    this.documentNumber = const Value.absent(),
    required String category,
    required DateTime documentDate,
    required int fiscalYear,
    required String localFilePath,
    required String fileName,
    required int fileSizeBytes,
    required String mimeType,
    required String sha256Hash,
    this.extractedText = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.gdriveFileId = const Value.absent(),
    this.remoteBackendId = const Value.absent(),
    this.trashedAt = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.accountBinding = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.notes = const Value.absent(),
    this.originalFileName = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       category = Value(category),
       documentDate = Value(documentDate),
       fiscalYear = Value(fiscalYear),
       localFilePath = Value(localFilePath),
       fileName = Value(fileName),
       fileSizeBytes = Value(fileSizeBytes),
       mimeType = Value(mimeType),
       sha256Hash = Value(sha256Hash);
  static Insertable<LocalDocument> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? documentNumber,
    Expression<String>? category,
    Expression<DateTime>? documentDate,
    Expression<int>? fiscalYear,
    Expression<String>? localFilePath,
    Expression<String>? fileName,
    Expression<int>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<String>? sha256Hash,
    Expression<String>? extractedText,
    Expression<String>? syncStatus,
    Expression<String>? gdriveFileId,
    Expression<String>? remoteBackendId,
    Expression<DateTime>? trashedAt,
    Expression<int>? baseRevision,
    Expression<String>? accountBinding,
    Expression<bool>? isFavorite,
    Expression<String>? notes,
    Expression<String>? originalFileName,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (documentNumber != null) 'document_number': documentNumber,
      if (category != null) 'category': category,
      if (documentDate != null) 'document_date': documentDate,
      if (fiscalYear != null) 'fiscal_year': fiscalYear,
      if (localFilePath != null) 'local_file_path': localFilePath,
      if (fileName != null) 'file_name': fileName,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (extractedText != null) 'extracted_text': extractedText,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (gdriveFileId != null) 'gdrive_file_id': gdriveFileId,
      if (remoteBackendId != null) 'remote_backend_id': remoteBackendId,
      if (trashedAt != null) 'trashed_at': trashedAt,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (accountBinding != null) 'account_binding': accountBinding,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (notes != null) 'notes': notes,
      if (originalFileName != null) 'original_file_name': originalFileName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? documentNumber,
    Value<String>? category,
    Value<DateTime>? documentDate,
    Value<int>? fiscalYear,
    Value<String>? localFilePath,
    Value<String>? fileName,
    Value<int>? fileSizeBytes,
    Value<String>? mimeType,
    Value<String>? sha256Hash,
    Value<String?>? extractedText,
    Value<String>? syncStatus,
    Value<String?>? gdriveFileId,
    Value<String?>? remoteBackendId,
    Value<DateTime?>? trashedAt,
    Value<int>? baseRevision,
    Value<String?>? accountBinding,
    Value<bool>? isFavorite,
    Value<String?>? notes,
    Value<String?>? originalFileName,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalDocumentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      documentNumber: documentNumber ?? this.documentNumber,
      category: category ?? this.category,
      documentDate: documentDate ?? this.documentDate,
      fiscalYear: fiscalYear ?? this.fiscalYear,
      localFilePath: localFilePath ?? this.localFilePath,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      extractedText: extractedText ?? this.extractedText,
      syncStatus: syncStatus ?? this.syncStatus,
      gdriveFileId: gdriveFileId ?? this.gdriveFileId,
      remoteBackendId: remoteBackendId ?? this.remoteBackendId,
      trashedAt: trashedAt ?? this.trashedAt,
      baseRevision: baseRevision ?? this.baseRevision,
      accountBinding: accountBinding ?? this.accountBinding,
      isFavorite: isFavorite ?? this.isFavorite,
      notes: notes ?? this.notes,
      originalFileName: originalFileName ?? this.originalFileName,
      createdAt: createdAt ?? this.createdAt,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (documentNumber.present) {
      map['document_number'] = Variable<String>(documentNumber.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (documentDate.present) {
      map['document_date'] = Variable<DateTime>(documentDate.value);
    }
    if (fiscalYear.present) {
      map['fiscal_year'] = Variable<int>(fiscalYear.value);
    }
    if (localFilePath.present) {
      map['local_file_path'] = Variable<String>(localFilePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sha256Hash.present) {
      map['sha256_hash'] = Variable<String>(sha256Hash.value);
    }
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (gdriveFileId.present) {
      map['gdrive_file_id'] = Variable<String>(gdriveFileId.value);
    }
    if (remoteBackendId.present) {
      map['remote_backend_id'] = Variable<String>(remoteBackendId.value);
    }
    if (trashedAt.present) {
      map['trashed_at'] = Variable<DateTime>(trashedAt.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (accountBinding.present) {
      map['account_binding'] = Variable<String>(accountBinding.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (originalFileName.present) {
      map['original_file_name'] = Variable<String>(originalFileName.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('category: $category, ')
          ..write('documentDate: $documentDate, ')
          ..write('fiscalYear: $fiscalYear, ')
          ..write('localFilePath: $localFilePath, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('extractedText: $extractedText, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('gdriveFileId: $gdriveFileId, ')
          ..write('remoteBackendId: $remoteBackendId, ')
          ..write('trashedAt: $trashedAt, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('accountBinding: $accountBinding, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('notes: $notes, ')
          ..write('originalFileName: $originalFileName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StorageRootsTable extends StorageRoots
    with TableInfo<$StorageRootsTable, StorageRoot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StorageRootsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, path, label, isActive, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'storage_roots';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorageRoot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StorageRoot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorageRoot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $StorageRootsTable createAlias(String alias) {
    return $StorageRootsTable(attachedDatabase, alias);
  }
}

class StorageRoot extends DataClass implements Insertable<StorageRoot> {
  final String id;
  final String path;
  final String? label;
  final bool isActive;
  final DateTime createdAt;
  const StorageRoot({
    required this.id,
    required this.path,
    this.label,
    required this.isActive,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  StorageRootsCompanion toCompanion(bool nullToAbsent) {
    return StorageRootsCompanion(
      id: Value(id),
      path: Value(path),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
    );
  }

  factory StorageRoot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorageRoot(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      label: serializer.fromJson<String?>(json['label']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'label': serializer.toJson<String?>(label),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  StorageRoot copyWith({
    String? id,
    String? path,
    Value<String?> label = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
  }) => StorageRoot(
    id: id ?? this.id,
    path: path ?? this.path,
    label: label.present ? label.value : this.label,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
  StorageRoot copyWithCompanion(StorageRootsCompanion data) {
    return StorageRoot(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      label: data.label.present ? data.label.value : this.label,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorageRoot(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, path, label, isActive, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorageRoot &&
          other.id == this.id &&
          other.path == this.path &&
          other.label == this.label &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt);
}

class StorageRootsCompanion extends UpdateCompanion<StorageRoot> {
  final Value<String> id;
  final Value<String> path;
  final Value<String?> label;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const StorageRootsCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.label = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorageRootsCompanion.insert({
    required String id,
    required String path,
    this.label = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path);
  static Insertable<StorageRoot> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<String>? label,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (label != null) 'label': label,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorageRootsCompanion copyWith({
    Value<String>? id,
    Value<String>? path,
    Value<String?>? label,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return StorageRootsCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorageRootsCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('label: $label, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOperationsTable extends LocalOperations
    with TableInfo<$LocalOperationsTable, LocalOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcePathMeta = const VerificationMeta(
    'sourcePath',
  );
  @override
  late final GeneratedColumn<String> sourcePath = GeneratedColumn<String>(
    'source_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stagedPathMeta = const VerificationMeta(
    'stagedPath',
  );
  @override
  late final GeneratedColumn<String> stagedPath = GeneratedColumn<String>(
    'staged_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPathMeta = const VerificationMeta(
    'targetPath',
  );
  @override
  late final GeneratedColumn<String> targetPath = GeneratedColumn<String>(
    'target_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checksumMeta = const VerificationMeta(
    'checksum',
  );
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
    'checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    status,
    documentId,
    sourcePath,
    stagedPath,
    targetPath,
    checksum,
    errorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    }
    if (data.containsKey('source_path')) {
      context.handle(
        _sourcePathMeta,
        sourcePath.isAcceptableOrUnknown(data['source_path']!, _sourcePathMeta),
      );
    }
    if (data.containsKey('staged_path')) {
      context.handle(
        _stagedPathMeta,
        stagedPath.isAcceptableOrUnknown(data['staged_path']!, _stagedPathMeta),
      );
    }
    if (data.containsKey('target_path')) {
      context.handle(
        _targetPathMeta,
        targetPath.isAcceptableOrUnknown(data['target_path']!, _targetPathMeta),
      );
    }
    if (data.containsKey('checksum')) {
      context.handle(
        _checksumMeta,
        checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      ),
      sourcePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_path'],
      ),
      stagedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}staged_path'],
      ),
      targetPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_path'],
      ),
      checksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checksum'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalOperationsTable createAlias(String alias) {
    return $LocalOperationsTable(attachedDatabase, alias);
  }
}

class LocalOperation extends DataClass implements Insertable<LocalOperation> {
  final String id;
  final String kind;
  final String status;
  final String? documentId;
  final String? sourcePath;
  final String? stagedPath;
  final String? targetPath;
  final String? checksum;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalOperation({
    required this.id,
    required this.kind,
    required this.status,
    this.documentId,
    this.sourcePath,
    this.stagedPath,
    this.targetPath,
    this.checksum,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || documentId != null) {
      map['document_id'] = Variable<String>(documentId);
    }
    if (!nullToAbsent || sourcePath != null) {
      map['source_path'] = Variable<String>(sourcePath);
    }
    if (!nullToAbsent || stagedPath != null) {
      map['staged_path'] = Variable<String>(stagedPath);
    }
    if (!nullToAbsent || targetPath != null) {
      map['target_path'] = Variable<String>(targetPath);
    }
    if (!nullToAbsent || checksum != null) {
      map['checksum'] = Variable<String>(checksum);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalOperationsCompanion toCompanion(bool nullToAbsent) {
    return LocalOperationsCompanion(
      id: Value(id),
      kind: Value(kind),
      status: Value(status),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
      sourcePath: sourcePath == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePath),
      stagedPath: stagedPath == null && nullToAbsent
          ? const Value.absent()
          : Value(stagedPath),
      targetPath: targetPath == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPath),
      checksum: checksum == null && nullToAbsent
          ? const Value.absent()
          : Value(checksum),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOperation(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      documentId: serializer.fromJson<String?>(json['documentId']),
      sourcePath: serializer.fromJson<String?>(json['sourcePath']),
      stagedPath: serializer.fromJson<String?>(json['stagedPath']),
      targetPath: serializer.fromJson<String?>(json['targetPath']),
      checksum: serializer.fromJson<String?>(json['checksum']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'documentId': serializer.toJson<String?>(documentId),
      'sourcePath': serializer.toJson<String?>(sourcePath),
      'stagedPath': serializer.toJson<String?>(stagedPath),
      'targetPath': serializer.toJson<String?>(targetPath),
      'checksum': serializer.toJson<String?>(checksum),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalOperation copyWith({
    String? id,
    String? kind,
    String? status,
    Value<String?> documentId = const Value.absent(),
    Value<String?> sourcePath = const Value.absent(),
    Value<String?> stagedPath = const Value.absent(),
    Value<String?> targetPath = const Value.absent(),
    Value<String?> checksum = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalOperation(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    documentId: documentId.present ? documentId.value : this.documentId,
    sourcePath: sourcePath.present ? sourcePath.value : this.sourcePath,
    stagedPath: stagedPath.present ? stagedPath.value : this.stagedPath,
    targetPath: targetPath.present ? targetPath.value : this.targetPath,
    checksum: checksum.present ? checksum.value : this.checksum,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalOperation copyWithCompanion(LocalOperationsCompanion data) {
    return LocalOperation(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      sourcePath: data.sourcePath.present
          ? data.sourcePath.value
          : this.sourcePath,
      stagedPath: data.stagedPath.present
          ? data.stagedPath.value
          : this.stagedPath,
      targetPath: data.targetPath.present
          ? data.targetPath.value
          : this.targetPath,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOperation(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('documentId: $documentId, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('stagedPath: $stagedPath, ')
          ..write('targetPath: $targetPath, ')
          ..write('checksum: $checksum, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    status,
    documentId,
    sourcePath,
    stagedPath,
    targetPath,
    checksum,
    errorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOperation &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.documentId == this.documentId &&
          other.sourcePath == this.sourcePath &&
          other.stagedPath == this.stagedPath &&
          other.targetPath == this.targetPath &&
          other.checksum == this.checksum &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalOperationsCompanion extends UpdateCompanion<LocalOperation> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> status;
  final Value<String?> documentId;
  final Value<String?> sourcePath;
  final Value<String?> stagedPath;
  final Value<String?> targetPath;
  final Value<String?> checksum;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalOperationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.documentId = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.stagedPath = const Value.absent(),
    this.targetPath = const Value.absent(),
    this.checksum = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOperationsCompanion.insert({
    required String id,
    required String kind,
    required String status,
    this.documentId = const Value.absent(),
    this.sourcePath = const Value.absent(),
    this.stagedPath = const Value.absent(),
    this.targetPath = const Value.absent(),
    this.checksum = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       status = Value(status);
  static Insertable<LocalOperation> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<String>? documentId,
    Expression<String>? sourcePath,
    Expression<String>? stagedPath,
    Expression<String>? targetPath,
    Expression<String>? checksum,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (documentId != null) 'document_id': documentId,
      if (sourcePath != null) 'source_path': sourcePath,
      if (stagedPath != null) 'staged_path': stagedPath,
      if (targetPath != null) 'target_path': targetPath,
      if (checksum != null) 'checksum': checksum,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? status,
    Value<String?>? documentId,
    Value<String?>? sourcePath,
    Value<String?>? stagedPath,
    Value<String?>? targetPath,
    Value<String?>? checksum,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalOperationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      documentId: documentId ?? this.documentId,
      sourcePath: sourcePath ?? this.sourcePath,
      stagedPath: stagedPath ?? this.stagedPath,
      targetPath: targetPath ?? this.targetPath,
      checksum: checksum ?? this.checksum,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (sourcePath.present) {
      map['source_path'] = Variable<String>(sourcePath.value);
    }
    if (stagedPath.present) {
      map['staged_path'] = Variable<String>(stagedPath.value);
    }
    if (targetPath.present) {
      map['target_path'] = Variable<String>(targetPath.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOperationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('documentId: $documentId, ')
          ..write('sourcePath: $sourcePath, ')
          ..write('stagedPath: $stagedPath, ')
          ..write('targetPath: $targetPath, ')
          ..write('checksum: $checksum, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncJobsTable extends SyncJobs with TableInfo<$SyncJobsTable, SyncJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
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
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leasedUntilMeta = const VerificationMeta(
    'leasedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> leasedUntil = GeneratedColumn<DateTime>(
    'leased_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountBindingMeta = const VerificationMeta(
    'accountBinding',
  );
  @override
  late final GeneratedColumn<String> accountBinding = GeneratedColumn<String>(
    'account_binding',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseRevisionMeta = const VerificationMeta(
    'baseRevision',
  );
  @override
  late final GeneratedColumn<int> baseRevision = GeneratedColumn<int>(
    'base_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revisionPayloadMeta = const VerificationMeta(
    'revisionPayload',
  );
  @override
  late final GeneratedColumn<String> revisionPayload = GeneratedColumn<String>(
    'revision_payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorRedactedMeta = const VerificationMeta(
    'errorRedacted',
  );
  @override
  late final GeneratedColumn<String> errorRedacted = GeneratedColumn<String>(
    'error_redacted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    destination,
    kind,
    status,
    attempts,
    nextRetryAt,
    leasedUntil,
    accountBinding,
    baseRevision,
    contentHash,
    revisionPayload,
    errorRedacted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('leased_until')) {
      context.handle(
        _leasedUntilMeta,
        leasedUntil.isAcceptableOrUnknown(
          data['leased_until']!,
          _leasedUntilMeta,
        ),
      );
    }
    if (data.containsKey('account_binding')) {
      context.handle(
        _accountBindingMeta,
        accountBinding.isAcceptableOrUnknown(
          data['account_binding']!,
          _accountBindingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountBindingMeta);
    }
    if (data.containsKey('base_revision')) {
      context.handle(
        _baseRevisionMeta,
        baseRevision.isAcceptableOrUnknown(
          data['base_revision']!,
          _baseRevisionMeta,
        ),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('revision_payload')) {
      context.handle(
        _revisionPayloadMeta,
        revisionPayload.isAcceptableOrUnknown(
          data['revision_payload']!,
          _revisionPayloadMeta,
        ),
      );
    }
    if (data.containsKey('error_redacted')) {
      context.handle(
        _errorRedactedMeta,
        errorRedacted.isAcceptableOrUnknown(
          data['error_redacted']!,
          _errorRedactedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      leasedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}leased_until'],
      ),
      accountBinding: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_binding'],
      )!,
      baseRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_revision'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      revisionPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_payload'],
      ),
      errorRedacted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_redacted'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncJobsTable createAlias(String alias) {
    return $SyncJobsTable(attachedDatabase, alias);
  }
}

class SyncJob extends DataClass implements Insertable<SyncJob> {
  final String id;
  final String documentId;
  final String destination;
  final String kind;

  /// pending | leased | complete | blocked
  final String status;
  final int attempts;

  /// The earliest time a worker may re-claim this job. Advanced by the
  /// retry/backoff policy; set to NULL for immediate eligibility.
  final DateTime? nextRetryAt;

  /// A leased job carries the moment its lease expires so a crashed
  /// worker does not strand the row forever.
  final DateTime? leasedUntil;
  final String accountBinding;

  /// Local revision the job will present as baseRevision when it runs.
  /// A mismatch on the server side yields `conflict` and blocks further
  /// retries until the user resolves (Phase 2.6).
  final int baseRevision;
  final String? contentHash;
  final String? revisionPayload;
  final String? errorRedacted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SyncJob({
    required this.id,
    required this.documentId,
    required this.destination,
    required this.kind,
    required this.status,
    required this.attempts,
    this.nextRetryAt,
    this.leasedUntil,
    required this.accountBinding,
    required this.baseRevision,
    this.contentHash,
    this.revisionPayload,
    this.errorRedacted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['destination'] = Variable<String>(destination);
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || leasedUntil != null) {
      map['leased_until'] = Variable<DateTime>(leasedUntil);
    }
    map['account_binding'] = Variable<String>(accountBinding);
    map['base_revision'] = Variable<int>(baseRevision);
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    if (!nullToAbsent || revisionPayload != null) {
      map['revision_payload'] = Variable<String>(revisionPayload);
    }
    if (!nullToAbsent || errorRedacted != null) {
      map['error_redacted'] = Variable<String>(errorRedacted);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SyncJobsCompanion toCompanion(bool nullToAbsent) {
    return SyncJobsCompanion(
      id: Value(id),
      documentId: Value(documentId),
      destination: Value(destination),
      kind: Value(kind),
      status: Value(status),
      attempts: Value(attempts),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      leasedUntil: leasedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(leasedUntil),
      accountBinding: Value(accountBinding),
      baseRevision: Value(baseRevision),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      revisionPayload: revisionPayload == null && nullToAbsent
          ? const Value.absent()
          : Value(revisionPayload),
      errorRedacted: errorRedacted == null && nullToAbsent
          ? const Value.absent()
          : Value(errorRedacted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncJob(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      destination: serializer.fromJson<String>(json['destination']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      leasedUntil: serializer.fromJson<DateTime?>(json['leasedUntil']),
      accountBinding: serializer.fromJson<String>(json['accountBinding']),
      baseRevision: serializer.fromJson<int>(json['baseRevision']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      revisionPayload: serializer.fromJson<String?>(json['revisionPayload']),
      errorRedacted: serializer.fromJson<String?>(json['errorRedacted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'destination': serializer.toJson<String>(destination),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'leasedUntil': serializer.toJson<DateTime?>(leasedUntil),
      'accountBinding': serializer.toJson<String>(accountBinding),
      'baseRevision': serializer.toJson<int>(baseRevision),
      'contentHash': serializer.toJson<String?>(contentHash),
      'revisionPayload': serializer.toJson<String?>(revisionPayload),
      'errorRedacted': serializer.toJson<String?>(errorRedacted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SyncJob copyWith({
    String? id,
    String? documentId,
    String? destination,
    String? kind,
    String? status,
    int? attempts,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    Value<DateTime?> leasedUntil = const Value.absent(),
    String? accountBinding,
    int? baseRevision,
    Value<String?> contentHash = const Value.absent(),
    Value<String?> revisionPayload = const Value.absent(),
    Value<String?> errorRedacted = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SyncJob(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    destination: destination ?? this.destination,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    leasedUntil: leasedUntil.present ? leasedUntil.value : this.leasedUntil,
    accountBinding: accountBinding ?? this.accountBinding,
    baseRevision: baseRevision ?? this.baseRevision,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    revisionPayload: revisionPayload.present
        ? revisionPayload.value
        : this.revisionPayload,
    errorRedacted: errorRedacted.present
        ? errorRedacted.value
        : this.errorRedacted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncJob copyWithCompanion(SyncJobsCompanion data) {
    return SyncJob(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      leasedUntil: data.leasedUntil.present
          ? data.leasedUntil.value
          : this.leasedUntil,
      accountBinding: data.accountBinding.present
          ? data.accountBinding.value
          : this.accountBinding,
      baseRevision: data.baseRevision.present
          ? data.baseRevision.value
          : this.baseRevision,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      revisionPayload: data.revisionPayload.present
          ? data.revisionPayload.value
          : this.revisionPayload,
      errorRedacted: data.errorRedacted.present
          ? data.errorRedacted.value
          : this.errorRedacted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncJob(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('destination: $destination, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('leasedUntil: $leasedUntil, ')
          ..write('accountBinding: $accountBinding, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('contentHash: $contentHash, ')
          ..write('revisionPayload: $revisionPayload, ')
          ..write('errorRedacted: $errorRedacted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    destination,
    kind,
    status,
    attempts,
    nextRetryAt,
    leasedUntil,
    accountBinding,
    baseRevision,
    contentHash,
    revisionPayload,
    errorRedacted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncJob &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.destination == this.destination &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextRetryAt == this.nextRetryAt &&
          other.leasedUntil == this.leasedUntil &&
          other.accountBinding == this.accountBinding &&
          other.baseRevision == this.baseRevision &&
          other.contentHash == this.contentHash &&
          other.revisionPayload == this.revisionPayload &&
          other.errorRedacted == this.errorRedacted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SyncJobsCompanion extends UpdateCompanion<SyncJob> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<String> destination;
  final Value<String> kind;
  final Value<String> status;
  final Value<int> attempts;
  final Value<DateTime?> nextRetryAt;
  final Value<DateTime?> leasedUntil;
  final Value<String> accountBinding;
  final Value<int> baseRevision;
  final Value<String?> contentHash;
  final Value<String?> revisionPayload;
  final Value<String?> errorRedacted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SyncJobsCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.destination = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.leasedUntil = const Value.absent(),
    this.accountBinding = const Value.absent(),
    this.baseRevision = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.revisionPayload = const Value.absent(),
    this.errorRedacted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncJobsCompanion.insert({
    required String id,
    required String documentId,
    required String destination,
    required String kind,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.leasedUntil = const Value.absent(),
    required String accountBinding,
    this.baseRevision = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.revisionPayload = const Value.absent(),
    this.errorRedacted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       destination = Value(destination),
       kind = Value(kind),
       accountBinding = Value(accountBinding);
  static Insertable<SyncJob> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<String>? destination,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? nextRetryAt,
    Expression<DateTime>? leasedUntil,
    Expression<String>? accountBinding,
    Expression<int>? baseRevision,
    Expression<String>? contentHash,
    Expression<String>? revisionPayload,
    Expression<String>? errorRedacted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (destination != null) 'destination': destination,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (leasedUntil != null) 'leased_until': leasedUntil,
      if (accountBinding != null) 'account_binding': accountBinding,
      if (baseRevision != null) 'base_revision': baseRevision,
      if (contentHash != null) 'content_hash': contentHash,
      if (revisionPayload != null) 'revision_payload': revisionPayload,
      if (errorRedacted != null) 'error_redacted': errorRedacted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncJobsCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<String>? destination,
    Value<String>? kind,
    Value<String>? status,
    Value<int>? attempts,
    Value<DateTime?>? nextRetryAt,
    Value<DateTime?>? leasedUntil,
    Value<String>? accountBinding,
    Value<int>? baseRevision,
    Value<String?>? contentHash,
    Value<String?>? revisionPayload,
    Value<String?>? errorRedacted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncJobsCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      destination: destination ?? this.destination,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      leasedUntil: leasedUntil ?? this.leasedUntil,
      accountBinding: accountBinding ?? this.accountBinding,
      baseRevision: baseRevision ?? this.baseRevision,
      contentHash: contentHash ?? this.contentHash,
      revisionPayload: revisionPayload ?? this.revisionPayload,
      errorRedacted: errorRedacted ?? this.errorRedacted,
      createdAt: createdAt ?? this.createdAt,
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
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (leasedUntil.present) {
      map['leased_until'] = Variable<DateTime>(leasedUntil.value);
    }
    if (accountBinding.present) {
      map['account_binding'] = Variable<String>(accountBinding.value);
    }
    if (baseRevision.present) {
      map['base_revision'] = Variable<int>(baseRevision.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (revisionPayload.present) {
      map['revision_payload'] = Variable<String>(revisionPayload.value);
    }
    if (errorRedacted.present) {
      map['error_redacted'] = Variable<String>(errorRedacted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncJobsCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('destination: $destination, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('leasedUntil: $leasedUntil, ')
          ..write('accountBinding: $accountBinding, ')
          ..write('baseRevision: $baseRevision, ')
          ..write('contentHash: $contentHash, ')
          ..write('revisionPayload: $revisionPayload, ')
          ..write('errorRedacted: $errorRedacted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentReplicasTable extends DocumentReplicas
    with TableInfo<$DocumentReplicasTable, DocumentReplica> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentReplicasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationMeta = const VerificationMeta(
    'destination',
  );
  @override
  late final GeneratedColumn<String> destination = GeneratedColumn<String>(
    'destination',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _revisionAckMeta = const VerificationMeta(
    'revisionAck',
  );
  @override
  late final GeneratedColumn<int> revisionAck = GeneratedColumn<int>(
    'revision_ack',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _contentHashAckMeta = const VerificationMeta(
    'contentHashAck',
  );
  @override
  late final GeneratedColumn<String> contentHashAck = GeneratedColumn<String>(
    'content_hash_ack',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteNameMeta = const VerificationMeta(
    'remoteName',
  );
  @override
  late final GeneratedColumn<String> remoteName = GeneratedColumn<String>(
    'remote_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastVerifiedAtMeta = const VerificationMeta(
    'lastVerifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastVerifiedAt =
      GeneratedColumn<DateTime>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _errorRedactedMeta = const VerificationMeta(
    'errorRedacted',
  );
  @override
  late final GeneratedColumn<String> errorRedacted = GeneratedColumn<String>(
    'error_redacted',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    destination,
    status,
    revisionAck,
    contentHashAck,
    remoteId,
    remoteName,
    lastVerifiedAt,
    errorRedacted,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_replicas';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentReplica> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('destination')) {
      context.handle(
        _destinationMeta,
        destination.isAcceptableOrUnknown(
          data['destination']!,
          _destinationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_destinationMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('revision_ack')) {
      context.handle(
        _revisionAckMeta,
        revisionAck.isAcceptableOrUnknown(
          data['revision_ack']!,
          _revisionAckMeta,
        ),
      );
    }
    if (data.containsKey('content_hash_ack')) {
      context.handle(
        _contentHashAckMeta,
        contentHashAck.isAcceptableOrUnknown(
          data['content_hash_ack']!,
          _contentHashAckMeta,
        ),
      );
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    }
    if (data.containsKey('remote_name')) {
      context.handle(
        _remoteNameMeta,
        remoteName.isAcceptableOrUnknown(data['remote_name']!, _remoteNameMeta),
      );
    }
    if (data.containsKey('last_verified_at')) {
      context.handle(
        _lastVerifiedAtMeta,
        lastVerifiedAt.isAcceptableOrUnknown(
          data['last_verified_at']!,
          _lastVerifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('error_redacted')) {
      context.handle(
        _errorRedactedMeta,
        errorRedacted.isAcceptableOrUnknown(
          data['error_redacted']!,
          _errorRedactedMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {documentId, destination},
  ];
  @override
  DocumentReplica map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentReplica(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      destination: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      revisionAck: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision_ack'],
      )!,
      contentHashAck: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash_ack'],
      ),
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      ),
      remoteName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_name'],
      ),
      lastVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_verified_at'],
      ),
      errorRedacted: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_redacted'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DocumentReplicasTable createAlias(String alias) {
    return $DocumentReplicasTable(attachedDatabase, alias);
  }
}

class DocumentReplica extends DataClass implements Insertable<DocumentReplica> {
  final String id;
  final String documentId;

  /// drive | backend
  final String destination;
  final String status;

  /// The revision number this destination acknowledged.
  final int revisionAck;

  /// The content hash this destination acknowledged. Metadata-only
  /// changes do not alter the content hash.
  final String? contentHashAck;

  /// Provider-side identifier once the destination has accepted an
  /// upload (Drive fileId for `drive`, server document UUID for
  /// `backend`).
  final String? remoteId;

  /// The remote file name the destination currently knows about.
  /// Kept separate from [local_documents.fileName] so a remote rename
  /// does not rewrite the physical file name (Phase 2.7).
  final String? remoteName;
  final DateTime? lastVerifiedAt;
  final String? errorRedacted;
  final DateTime updatedAt;
  const DocumentReplica({
    required this.id,
    required this.documentId,
    required this.destination,
    required this.status,
    required this.revisionAck,
    this.contentHashAck,
    this.remoteId,
    this.remoteName,
    this.lastVerifiedAt,
    this.errorRedacted,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['destination'] = Variable<String>(destination);
    map['status'] = Variable<String>(status);
    map['revision_ack'] = Variable<int>(revisionAck);
    if (!nullToAbsent || contentHashAck != null) {
      map['content_hash_ack'] = Variable<String>(contentHashAck);
    }
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<String>(remoteId);
    }
    if (!nullToAbsent || remoteName != null) {
      map['remote_name'] = Variable<String>(remoteName);
    }
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt);
    }
    if (!nullToAbsent || errorRedacted != null) {
      map['error_redacted'] = Variable<String>(errorRedacted);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DocumentReplicasCompanion toCompanion(bool nullToAbsent) {
    return DocumentReplicasCompanion(
      id: Value(id),
      documentId: Value(documentId),
      destination: Value(destination),
      status: Value(status),
      revisionAck: Value(revisionAck),
      contentHashAck: contentHashAck == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHashAck),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      remoteName: remoteName == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteName),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
      errorRedacted: errorRedacted == null && nullToAbsent
          ? const Value.absent()
          : Value(errorRedacted),
      updatedAt: Value(updatedAt),
    );
  }

  factory DocumentReplica.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentReplica(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      destination: serializer.fromJson<String>(json['destination']),
      status: serializer.fromJson<String>(json['status']),
      revisionAck: serializer.fromJson<int>(json['revisionAck']),
      contentHashAck: serializer.fromJson<String?>(json['contentHashAck']),
      remoteId: serializer.fromJson<String?>(json['remoteId']),
      remoteName: serializer.fromJson<String?>(json['remoteName']),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
      errorRedacted: serializer.fromJson<String?>(json['errorRedacted']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'destination': serializer.toJson<String>(destination),
      'status': serializer.toJson<String>(status),
      'revisionAck': serializer.toJson<int>(revisionAck),
      'contentHashAck': serializer.toJson<String?>(contentHashAck),
      'remoteId': serializer.toJson<String?>(remoteId),
      'remoteName': serializer.toJson<String?>(remoteName),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
      'errorRedacted': serializer.toJson<String?>(errorRedacted),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DocumentReplica copyWith({
    String? id,
    String? documentId,
    String? destination,
    String? status,
    int? revisionAck,
    Value<String?> contentHashAck = const Value.absent(),
    Value<String?> remoteId = const Value.absent(),
    Value<String?> remoteName = const Value.absent(),
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
    Value<String?> errorRedacted = const Value.absent(),
    DateTime? updatedAt,
  }) => DocumentReplica(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    destination: destination ?? this.destination,
    status: status ?? this.status,
    revisionAck: revisionAck ?? this.revisionAck,
    contentHashAck: contentHashAck.present
        ? contentHashAck.value
        : this.contentHashAck,
    remoteId: remoteId.present ? remoteId.value : this.remoteId,
    remoteName: remoteName.present ? remoteName.value : this.remoteName,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
    errorRedacted: errorRedacted.present
        ? errorRedacted.value
        : this.errorRedacted,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DocumentReplica copyWithCompanion(DocumentReplicasCompanion data) {
    return DocumentReplica(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      destination: data.destination.present
          ? data.destination.value
          : this.destination,
      status: data.status.present ? data.status.value : this.status,
      revisionAck: data.revisionAck.present
          ? data.revisionAck.value
          : this.revisionAck,
      contentHashAck: data.contentHashAck.present
          ? data.contentHashAck.value
          : this.contentHashAck,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      remoteName: data.remoteName.present
          ? data.remoteName.value
          : this.remoteName,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
      errorRedacted: data.errorRedacted.present
          ? data.errorRedacted.value
          : this.errorRedacted,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentReplica(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('destination: $destination, ')
          ..write('status: $status, ')
          ..write('revisionAck: $revisionAck, ')
          ..write('contentHashAck: $contentHashAck, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteName: $remoteName, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('errorRedacted: $errorRedacted, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    documentId,
    destination,
    status,
    revisionAck,
    contentHashAck,
    remoteId,
    remoteName,
    lastVerifiedAt,
    errorRedacted,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentReplica &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.destination == this.destination &&
          other.status == this.status &&
          other.revisionAck == this.revisionAck &&
          other.contentHashAck == this.contentHashAck &&
          other.remoteId == this.remoteId &&
          other.remoteName == this.remoteName &&
          other.lastVerifiedAt == this.lastVerifiedAt &&
          other.errorRedacted == this.errorRedacted &&
          other.updatedAt == this.updatedAt);
}

class DocumentReplicasCompanion extends UpdateCompanion<DocumentReplica> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<String> destination;
  final Value<String> status;
  final Value<int> revisionAck;
  final Value<String?> contentHashAck;
  final Value<String?> remoteId;
  final Value<String?> remoteName;
  final Value<DateTime?> lastVerifiedAt;
  final Value<String?> errorRedacted;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DocumentReplicasCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.destination = const Value.absent(),
    this.status = const Value.absent(),
    this.revisionAck = const Value.absent(),
    this.contentHashAck = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteName = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.errorRedacted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentReplicasCompanion.insert({
    required String id,
    required String documentId,
    required String destination,
    this.status = const Value.absent(),
    this.revisionAck = const Value.absent(),
    this.contentHashAck = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.remoteName = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.errorRedacted = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       destination = Value(destination);
  static Insertable<DocumentReplica> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<String>? destination,
    Expression<String>? status,
    Expression<int>? revisionAck,
    Expression<String>? contentHashAck,
    Expression<String>? remoteId,
    Expression<String>? remoteName,
    Expression<DateTime>? lastVerifiedAt,
    Expression<String>? errorRedacted,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (destination != null) 'destination': destination,
      if (status != null) 'status': status,
      if (revisionAck != null) 'revision_ack': revisionAck,
      if (contentHashAck != null) 'content_hash_ack': contentHashAck,
      if (remoteId != null) 'remote_id': remoteId,
      if (remoteName != null) 'remote_name': remoteName,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (errorRedacted != null) 'error_redacted': errorRedacted,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentReplicasCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<String>? destination,
    Value<String>? status,
    Value<int>? revisionAck,
    Value<String?>? contentHashAck,
    Value<String?>? remoteId,
    Value<String?>? remoteName,
    Value<DateTime?>? lastVerifiedAt,
    Value<String?>? errorRedacted,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DocumentReplicasCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      revisionAck: revisionAck ?? this.revisionAck,
      contentHashAck: contentHashAck ?? this.contentHashAck,
      remoteId: remoteId ?? this.remoteId,
      remoteName: remoteName ?? this.remoteName,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      errorRedacted: errorRedacted ?? this.errorRedacted,
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
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (destination.present) {
      map['destination'] = Variable<String>(destination.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (revisionAck.present) {
      map['revision_ack'] = Variable<int>(revisionAck.value);
    }
    if (contentHashAck.present) {
      map['content_hash_ack'] = Variable<String>(contentHashAck.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (remoteName.present) {
      map['remote_name'] = Variable<String>(remoteName.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<DateTime>(lastVerifiedAt.value);
    }
    if (errorRedacted.present) {
      map['error_redacted'] = Variable<String>(errorRedacted.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentReplicasCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('destination: $destination, ')
          ..write('status: $status, ')
          ..write('revisionAck: $revisionAck, ')
          ..write('contentHashAck: $contentHashAck, ')
          ..write('remoteId: $remoteId, ')
          ..write('remoteName: $remoteName, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('errorRedacted: $errorRedacted, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DriveUploadSessionsTable extends DriveUploadSessions
    with TableInfo<$DriveUploadSessionsTable, DriveUploadSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriveUploadSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jobIdMeta = const VerificationMeta('jobId');
  @override
  late final GeneratedColumn<String> jobId = GeneratedColumn<String>(
    'job_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionUriMeta = const VerificationMeta(
    'sessionUri',
  );
  @override
  late final GeneratedColumn<String> sessionUri = GeneratedColumn<String>(
    'session_uri',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bytesAcknowledgedMeta = const VerificationMeta(
    'bytesAcknowledged',
  );
  @override
  late final GeneratedColumn<int> bytesAcknowledged = GeneratedColumn<int>(
    'bytes_acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    jobId,
    documentId,
    sessionUri,
    bytesAcknowledged,
    totalBytes,
    status,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drive_upload_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriveUploadSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('job_id')) {
      context.handle(
        _jobIdMeta,
        jobId.isAcceptableOrUnknown(data['job_id']!, _jobIdMeta),
      );
    } else if (isInserting) {
      context.missing(_jobIdMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('session_uri')) {
      context.handle(
        _sessionUriMeta,
        sessionUri.isAcceptableOrUnknown(data['session_uri']!, _sessionUriMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionUriMeta);
    }
    if (data.containsKey('bytes_acknowledged')) {
      context.handle(
        _bytesAcknowledgedMeta,
        bytesAcknowledged.isAcceptableOrUnknown(
          data['bytes_acknowledged']!,
          _bytesAcknowledgedMeta,
        ),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    } else if (isInserting) {
      context.missing(_totalBytesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriveUploadSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriveUploadSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      jobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job_id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      sessionUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_uri'],
      )!,
      bytesAcknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_acknowledged'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DriveUploadSessionsTable createAlias(String alias) {
    return $DriveUploadSessionsTable(attachedDatabase, alias);
  }
}

class DriveUploadSession extends DataClass
    implements Insertable<DriveUploadSession> {
  final String id;
  final String jobId;
  final String documentId;
  final String sessionUri;
  final int bytesAcknowledged;
  final int totalBytes;

  /// open | complete | expired | aborted
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DriveUploadSession({
    required this.id,
    required this.jobId,
    required this.documentId,
    required this.sessionUri,
    required this.bytesAcknowledged,
    required this.totalBytes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['job_id'] = Variable<String>(jobId);
    map['document_id'] = Variable<String>(documentId);
    map['session_uri'] = Variable<String>(sessionUri);
    map['bytes_acknowledged'] = Variable<int>(bytesAcknowledged);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DriveUploadSessionsCompanion toCompanion(bool nullToAbsent) {
    return DriveUploadSessionsCompanion(
      id: Value(id),
      jobId: Value(jobId),
      documentId: Value(documentId),
      sessionUri: Value(sessionUri),
      bytesAcknowledged: Value(bytesAcknowledged),
      totalBytes: Value(totalBytes),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DriveUploadSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriveUploadSession(
      id: serializer.fromJson<String>(json['id']),
      jobId: serializer.fromJson<String>(json['jobId']),
      documentId: serializer.fromJson<String>(json['documentId']),
      sessionUri: serializer.fromJson<String>(json['sessionUri']),
      bytesAcknowledged: serializer.fromJson<int>(json['bytesAcknowledged']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'jobId': serializer.toJson<String>(jobId),
      'documentId': serializer.toJson<String>(documentId),
      'sessionUri': serializer.toJson<String>(sessionUri),
      'bytesAcknowledged': serializer.toJson<int>(bytesAcknowledged),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DriveUploadSession copyWith({
    String? id,
    String? jobId,
    String? documentId,
    String? sessionUri,
    int? bytesAcknowledged,
    int? totalBytes,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DriveUploadSession(
    id: id ?? this.id,
    jobId: jobId ?? this.jobId,
    documentId: documentId ?? this.documentId,
    sessionUri: sessionUri ?? this.sessionUri,
    bytesAcknowledged: bytesAcknowledged ?? this.bytesAcknowledged,
    totalBytes: totalBytes ?? this.totalBytes,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DriveUploadSession copyWithCompanion(DriveUploadSessionsCompanion data) {
    return DriveUploadSession(
      id: data.id.present ? data.id.value : this.id,
      jobId: data.jobId.present ? data.jobId.value : this.jobId,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      sessionUri: data.sessionUri.present
          ? data.sessionUri.value
          : this.sessionUri,
      bytesAcknowledged: data.bytesAcknowledged.present
          ? data.bytesAcknowledged.value
          : this.bytesAcknowledged,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriveUploadSession(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('documentId: $documentId, ')
          ..write('sessionUri: $sessionUri, ')
          ..write('bytesAcknowledged: $bytesAcknowledged, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    jobId,
    documentId,
    sessionUri,
    bytesAcknowledged,
    totalBytes,
    status,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriveUploadSession &&
          other.id == this.id &&
          other.jobId == this.jobId &&
          other.documentId == this.documentId &&
          other.sessionUri == this.sessionUri &&
          other.bytesAcknowledged == this.bytesAcknowledged &&
          other.totalBytes == this.totalBytes &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DriveUploadSessionsCompanion extends UpdateCompanion<DriveUploadSession> {
  final Value<String> id;
  final Value<String> jobId;
  final Value<String> documentId;
  final Value<String> sessionUri;
  final Value<int> bytesAcknowledged;
  final Value<int> totalBytes;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DriveUploadSessionsCompanion({
    this.id = const Value.absent(),
    this.jobId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.sessionUri = const Value.absent(),
    this.bytesAcknowledged = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriveUploadSessionsCompanion.insert({
    required String id,
    required String jobId,
    required String documentId,
    required String sessionUri,
    this.bytesAcknowledged = const Value.absent(),
    required int totalBytes,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       jobId = Value(jobId),
       documentId = Value(documentId),
       sessionUri = Value(sessionUri),
       totalBytes = Value(totalBytes);
  static Insertable<DriveUploadSession> custom({
    Expression<String>? id,
    Expression<String>? jobId,
    Expression<String>? documentId,
    Expression<String>? sessionUri,
    Expression<int>? bytesAcknowledged,
    Expression<int>? totalBytes,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (jobId != null) 'job_id': jobId,
      if (documentId != null) 'document_id': documentId,
      if (sessionUri != null) 'session_uri': sessionUri,
      if (bytesAcknowledged != null) 'bytes_acknowledged': bytesAcknowledged,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriveUploadSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? jobId,
    Value<String>? documentId,
    Value<String>? sessionUri,
    Value<int>? bytesAcknowledged,
    Value<int>? totalBytes,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DriveUploadSessionsCompanion(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      documentId: documentId ?? this.documentId,
      sessionUri: sessionUri ?? this.sessionUri,
      bytesAcknowledged: bytesAcknowledged ?? this.bytesAcknowledged,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
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
    if (jobId.present) {
      map['job_id'] = Variable<String>(jobId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (sessionUri.present) {
      map['session_uri'] = Variable<String>(sessionUri.value);
    }
    if (bytesAcknowledged.present) {
      map['bytes_acknowledged'] = Variable<int>(bytesAcknowledged.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriveUploadSessionsCompanion(')
          ..write('id: $id, ')
          ..write('jobId: $jobId, ')
          ..write('documentId: $documentId, ')
          ..write('sessionUri: $sessionUri, ')
          ..write('bytesAcknowledged: $bytesAcknowledged, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentCategoriesTable extends DocumentCategories
    with TableInfo<$DocumentCategoriesTable, DocumentCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [code, name, archived, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  DocumentCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentCategory(
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DocumentCategoriesTable createAlias(String alias) {
    return $DocumentCategoriesTable(attachedDatabase, alias);
  }
}

class DocumentCategory extends DataClass
    implements Insertable<DocumentCategory> {
  final String code;
  final String name;
  final bool archived;
  final DateTime createdAt;
  const DocumentCategory({
    required this.code,
    required this.name,
    required this.archived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['name'] = Variable<String>(name);
    map['archived'] = Variable<bool>(archived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DocumentCategoriesCompanion toCompanion(bool nullToAbsent) {
    return DocumentCategoriesCompanion(
      code: Value(code),
      name: Value(name),
      archived: Value(archived),
      createdAt: Value(createdAt),
    );
  }

  factory DocumentCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentCategory(
      code: serializer.fromJson<String>(json['code']),
      name: serializer.fromJson<String>(json['name']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'name': serializer.toJson<String>(name),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DocumentCategory copyWith({
    String? code,
    String? name,
    bool? archived,
    DateTime? createdAt,
  }) => DocumentCategory(
    code: code ?? this.code,
    name: name ?? this.name,
    archived: archived ?? this.archived,
    createdAt: createdAt ?? this.createdAt,
  );
  DocumentCategory copyWithCompanion(DocumentCategoriesCompanion data) {
    return DocumentCategory(
      code: data.code.present ? data.code.value : this.code,
      name: data.name.present ? data.name.value : this.name,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentCategory(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(code, name, archived, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentCategory &&
          other.code == this.code &&
          other.name == this.name &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class DocumentCategoriesCompanion extends UpdateCompanion<DocumentCategory> {
  final Value<String> code;
  final Value<String> name;
  final Value<bool> archived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DocumentCategoriesCompanion({
    this.code = const Value.absent(),
    this.name = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentCategoriesCompanion.insert({
    required String code,
    required String name,
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : code = Value(code),
       name = Value(name);
  static Insertable<DocumentCategory> custom({
    Expression<String>? code,
    Expression<String>? name,
    Expression<bool>? archived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (name != null) 'name': name,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentCategoriesCompanion copyWith({
    Value<String>? code,
    Value<String>? name,
    Value<bool>? archived,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DocumentCategoriesCompanion(
      code: code ?? this.code,
      name: name ?? this.name,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentCategoriesCompanion(')
          ..write('code: $code, ')
          ..write('name: $name, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name},
  ];
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class Tag extends DataClass implements Insertable<Tag> {
  final String id;
  final String name;
  final DateTime createdAt;
  const Tag({required this.id, required this.name, required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tag copyWith({String? id, String? name, DateTime? createdAt}) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    createdAt: createdAt ?? this.createdAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Tag> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DocumentTagsTable extends DocumentTags
    with TableInfo<$DocumentTagsTable, DocumentTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DocumentTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'document_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, tagId};
  @override
  DocumentTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentTag(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $DocumentTagsTable createAlias(String alias) {
    return $DocumentTagsTable(attachedDatabase, alias);
  }
}

class DocumentTag extends DataClass implements Insertable<DocumentTag> {
  final String documentId;
  final String tagId;
  const DocumentTag({required this.documentId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  DocumentTagsCompanion toCompanion(bool nullToAbsent) {
    return DocumentTagsCompanion(
      documentId: Value(documentId),
      tagId: Value(tagId),
    );
  }

  factory DocumentTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentTag(
      documentId: serializer.fromJson<String>(json['documentId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  DocumentTag copyWith({String? documentId, String? tagId}) => DocumentTag(
    documentId: documentId ?? this.documentId,
    tagId: tagId ?? this.tagId,
  );
  DocumentTag copyWithCompanion(DocumentTagsCompanion data) {
    return DocumentTag(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentTag(')
          ..write('documentId: $documentId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentTag &&
          other.documentId == this.documentId &&
          other.tagId == this.tagId);
}

class DocumentTagsCompanion extends UpdateCompanion<DocumentTag> {
  final Value<String> documentId;
  final Value<String> tagId;
  final Value<int> rowid;
  const DocumentTagsCompanion({
    this.documentId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentTagsCompanion.insert({
    required String documentId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       tagId = Value(tagId);
  static Insertable<DocumentTag> custom({
    Expression<String>? documentId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentTagsCompanion copyWith({
    Value<String>? documentId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return DocumentTagsCompanion(
      documentId: documentId ?? this.documentId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentTagsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, Collection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collection(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class Collection extends DataClass implements Insertable<Collection> {
  final String id;
  final String name;
  final DateTime createdAt;
  const Collection({
    required this.id,
    required this.name,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      name: Value(name),
      createdAt: Value(createdAt),
    );
  }

  factory Collection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collection(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Collection copyWith({String? id, String? name, DateTime? createdAt}) =>
      Collection(
        id: id ?? this.id,
        name: name ?? this.name,
        createdAt: createdAt ?? this.createdAt,
      );
  Collection copyWithCompanion(CollectionsCompanion data) {
    return Collection(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collection(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collection &&
          other.id == this.id &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class CollectionsCompanion extends UpdateCompanion<Collection> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String id,
    required String name,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Collection> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CollectionsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionItemsTable extends CollectionItems
    with TableInfo<$CollectionItemsTable, CollectionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _collectionIdMeta = const VerificationMeta(
    'collectionId',
  );
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
    'collection_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [collectionId, documentId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('collection_id')) {
      context.handle(
        _collectionIdMeta,
        collectionId.isAcceptableOrUnknown(
          data['collection_id']!,
          _collectionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {collectionId, documentId};
  @override
  CollectionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionItem(
      collectionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collection_id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
    );
  }

  @override
  $CollectionItemsTable createAlias(String alias) {
    return $CollectionItemsTable(attachedDatabase, alias);
  }
}

class CollectionItem extends DataClass implements Insertable<CollectionItem> {
  final String collectionId;
  final String documentId;
  const CollectionItem({required this.collectionId, required this.documentId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['collection_id'] = Variable<String>(collectionId);
    map['document_id'] = Variable<String>(documentId);
    return map;
  }

  CollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return CollectionItemsCompanion(
      collectionId: Value(collectionId),
      documentId: Value(documentId),
    );
  }

  factory CollectionItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionItem(
      collectionId: serializer.fromJson<String>(json['collectionId']),
      documentId: serializer.fromJson<String>(json['documentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'collectionId': serializer.toJson<String>(collectionId),
      'documentId': serializer.toJson<String>(documentId),
    };
  }

  CollectionItem copyWith({String? collectionId, String? documentId}) =>
      CollectionItem(
        collectionId: collectionId ?? this.collectionId,
        documentId: documentId ?? this.documentId,
      );
  CollectionItem copyWithCompanion(CollectionItemsCompanion data) {
    return CollectionItem(
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItem(')
          ..write('collectionId: $collectionId, ')
          ..write('documentId: $documentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(collectionId, documentId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionItem &&
          other.collectionId == this.collectionId &&
          other.documentId == this.documentId);
}

class CollectionItemsCompanion extends UpdateCompanion<CollectionItem> {
  final Value<String> collectionId;
  final Value<String> documentId;
  final Value<int> rowid;
  const CollectionItemsCompanion({
    this.collectionId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionItemsCompanion.insert({
    required String collectionId,
    required String documentId,
    this.rowid = const Value.absent(),
  }) : collectionId = Value(collectionId),
       documentId = Value(documentId);
  static Insertable<CollectionItem> custom({
    Expression<String>? collectionId,
    Expression<String>? documentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (collectionId != null) 'collection_id': collectionId,
      if (documentId != null) 'document_id': documentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionItemsCompanion copyWith({
    Value<String>? collectionId,
    Value<String>? documentId,
    Value<int>? rowid,
  }) {
    return CollectionItemsCompanion(
      collectionId: collectionId ?? this.collectionId,
      documentId: documentId ?? this.documentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemsCompanion(')
          ..write('collectionId: $collectionId, ')
          ..write('documentId: $documentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedViewsTable extends SavedViews
    with TableInfo<$SavedViewsTable, SavedView> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedViewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateJsonMeta = const VerificationMeta(
    'stateJson',
  );
  @override
  late final GeneratedColumn<String> stateJson = GeneratedColumn<String>(
    'state_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, stateJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_views';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedView> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('state_json')) {
      context.handle(
        _stateJsonMeta,
        stateJson.isAcceptableOrUnknown(data['state_json']!, _stateJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_stateJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavedView map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedView(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      stateJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SavedViewsTable createAlias(String alias) {
    return $SavedViewsTable(attachedDatabase, alias);
  }
}

class SavedView extends DataClass implements Insertable<SavedView> {
  final String id;
  final String name;
  final String stateJson;
  final DateTime createdAt;
  const SavedView({
    required this.id,
    required this.name,
    required this.stateJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['state_json'] = Variable<String>(stateJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SavedViewsCompanion toCompanion(bool nullToAbsent) {
    return SavedViewsCompanion(
      id: Value(id),
      name: Value(name),
      stateJson: Value(stateJson),
      createdAt: Value(createdAt),
    );
  }

  factory SavedView.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedView(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      stateJson: serializer.fromJson<String>(json['stateJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'stateJson': serializer.toJson<String>(stateJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SavedView copyWith({
    String? id,
    String? name,
    String? stateJson,
    DateTime? createdAt,
  }) => SavedView(
    id: id ?? this.id,
    name: name ?? this.name,
    stateJson: stateJson ?? this.stateJson,
    createdAt: createdAt ?? this.createdAt,
  );
  SavedView copyWithCompanion(SavedViewsCompanion data) {
    return SavedView(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      stateJson: data.stateJson.present ? data.stateJson.value : this.stateJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedView(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('stateJson: $stateJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, stateJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedView &&
          other.id == this.id &&
          other.name == this.name &&
          other.stateJson == this.stateJson &&
          other.createdAt == this.createdAt);
}

class SavedViewsCompanion extends UpdateCompanion<SavedView> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> stateJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SavedViewsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.stateJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedViewsCompanion.insert({
    required String id,
    required String name,
    required String stateJson,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       stateJson = Value(stateJson);
  static Insertable<SavedView> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? stateJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (stateJson != null) 'state_json': stateJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedViewsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? stateJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SavedViewsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      stateJson: stateJson ?? this.stateJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (stateJson.present) {
      map['state_json'] = Variable<String>(stateJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedViewsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('stateJson: $stateJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalDocumentsTable localDocuments = $LocalDocumentsTable(this);
  late final $StorageRootsTable storageRoots = $StorageRootsTable(this);
  late final $LocalOperationsTable localOperations = $LocalOperationsTable(
    this,
  );
  late final $SyncJobsTable syncJobs = $SyncJobsTable(this);
  late final $DocumentReplicasTable documentReplicas = $DocumentReplicasTable(
    this,
  );
  late final $DriveUploadSessionsTable driveUploadSessions =
      $DriveUploadSessionsTable(this);
  late final $DocumentCategoriesTable documentCategories =
      $DocumentCategoriesTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $DocumentTagsTable documentTags = $DocumentTagsTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $CollectionItemsTable collectionItems = $CollectionItemsTable(
    this,
  );
  late final $SavedViewsTable savedViews = $SavedViewsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localDocuments,
    storageRoots,
    localOperations,
    syncJobs,
    documentReplicas,
    driveUploadSessions,
    documentCategories,
    tags,
    documentTags,
    collections,
    collectionItems,
    savedViews,
  ];
}

typedef $$LocalDocumentsTableCreateCompanionBuilder =
    LocalDocumentsCompanion Function({
      required String id,
      required String title,
      Value<String?> documentNumber,
      required String category,
      required DateTime documentDate,
      required int fiscalYear,
      required String localFilePath,
      required String fileName,
      required int fileSizeBytes,
      required String mimeType,
      required String sha256Hash,
      Value<String?> extractedText,
      Value<String> syncStatus,
      Value<String?> gdriveFileId,
      Value<String?> remoteBackendId,
      Value<DateTime?> trashedAt,
      Value<int> baseRevision,
      Value<String?> accountBinding,
      Value<bool> isFavorite,
      Value<String?> notes,
      Value<String?> originalFileName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalDocumentsTableUpdateCompanionBuilder =
    LocalDocumentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> documentNumber,
      Value<String> category,
      Value<DateTime> documentDate,
      Value<int> fiscalYear,
      Value<String> localFilePath,
      Value<String> fileName,
      Value<int> fileSizeBytes,
      Value<String> mimeType,
      Value<String> sha256Hash,
      Value<String?> extractedText,
      Value<String> syncStatus,
      Value<String?> gdriveFileId,
      Value<String?> remoteBackendId,
      Value<DateTime?> trashedAt,
      Value<int> baseRevision,
      Value<String?> accountBinding,
      Value<bool> isFavorite,
      Value<String?> notes,
      Value<String?> originalFileName,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDocumentsTable> {
  $$LocalDocumentsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get documentDate => $composableBuilder(
    column: $table.documentDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fiscalYear => $composableBuilder(
    column: $table.fiscalYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gdriveFileId => $composableBuilder(
    column: $table.gdriveFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteBackendId => $composableBuilder(
    column: $table.remoteBackendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountBinding => $composableBuilder(
    column: $table.accountBinding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDocumentsTable> {
  $$LocalDocumentsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get documentDate => $composableBuilder(
    column: $table.documentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fiscalYear => $composableBuilder(
    column: $table.fiscalYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gdriveFileId => $composableBuilder(
    column: $table.gdriveFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteBackendId => $composableBuilder(
    column: $table.remoteBackendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get trashedAt => $composableBuilder(
    column: $table.trashedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountBinding => $composableBuilder(
    column: $table.accountBinding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDocumentsTable> {
  $$LocalDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get documentNumber => $composableBuilder(
    column: $table.documentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get documentDate => $composableBuilder(
    column: $table.documentDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fiscalYear => $composableBuilder(
    column: $table.fiscalYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localFilePath => $composableBuilder(
    column: $table.localFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gdriveFileId => $composableBuilder(
    column: $table.gdriveFileId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteBackendId => $composableBuilder(
    column: $table.remoteBackendId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get trashedAt =>
      $composableBuilder(column: $table.trashedAt, builder: (column) => column);

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountBinding => $composableBuilder(
    column: $table.accountBinding,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get originalFileName => $composableBuilder(
    column: $table.originalFileName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDocumentsTable,
          LocalDocument,
          $$LocalDocumentsTableFilterComposer,
          $$LocalDocumentsTableOrderingComposer,
          $$LocalDocumentsTableAnnotationComposer,
          $$LocalDocumentsTableCreateCompanionBuilder,
          $$LocalDocumentsTableUpdateCompanionBuilder,
          (
            LocalDocument,
            BaseReferences<_$AppDatabase, $LocalDocumentsTable, LocalDocument>,
          ),
          LocalDocument,
          PrefetchHooks Function()
        > {
  $$LocalDocumentsTableTableManager(
    _$AppDatabase db,
    $LocalDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> documentNumber = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> documentDate = const Value.absent(),
                Value<int> fiscalYear = const Value.absent(),
                Value<String> localFilePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<String> sha256Hash = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> gdriveFileId = const Value.absent(),
                Value<String?> remoteBackendId = const Value.absent(),
                Value<DateTime?> trashedAt = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                Value<String?> accountBinding = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> originalFileName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDocumentsCompanion(
                id: id,
                title: title,
                documentNumber: documentNumber,
                category: category,
                documentDate: documentDate,
                fiscalYear: fiscalYear,
                localFilePath: localFilePath,
                fileName: fileName,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                sha256Hash: sha256Hash,
                extractedText: extractedText,
                syncStatus: syncStatus,
                gdriveFileId: gdriveFileId,
                remoteBackendId: remoteBackendId,
                trashedAt: trashedAt,
                baseRevision: baseRevision,
                accountBinding: accountBinding,
                isFavorite: isFavorite,
                notes: notes,
                originalFileName: originalFileName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> documentNumber = const Value.absent(),
                required String category,
                required DateTime documentDate,
                required int fiscalYear,
                required String localFilePath,
                required String fileName,
                required int fileSizeBytes,
                required String mimeType,
                required String sha256Hash,
                Value<String?> extractedText = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> gdriveFileId = const Value.absent(),
                Value<String?> remoteBackendId = const Value.absent(),
                Value<DateTime?> trashedAt = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                Value<String?> accountBinding = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> originalFileName = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDocumentsCompanion.insert(
                id: id,
                title: title,
                documentNumber: documentNumber,
                category: category,
                documentDate: documentDate,
                fiscalYear: fiscalYear,
                localFilePath: localFilePath,
                fileName: fileName,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                sha256Hash: sha256Hash,
                extractedText: extractedText,
                syncStatus: syncStatus,
                gdriveFileId: gdriveFileId,
                remoteBackendId: remoteBackendId,
                trashedAt: trashedAt,
                baseRevision: baseRevision,
                accountBinding: accountBinding,
                isFavorite: isFavorite,
                notes: notes,
                originalFileName: originalFileName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDocumentsTable, LocalDocument>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalDocumentsTable,
                    LocalDocument
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDocumentsTable,
      LocalDocument,
      $$LocalDocumentsTableFilterComposer,
      $$LocalDocumentsTableOrderingComposer,
      $$LocalDocumentsTableAnnotationComposer,
      $$LocalDocumentsTableCreateCompanionBuilder,
      $$LocalDocumentsTableUpdateCompanionBuilder,
      (
        LocalDocument,
        BaseReferences<_$AppDatabase, $LocalDocumentsTable, LocalDocument>,
      ),
      LocalDocument,
      PrefetchHooks Function()
    >;
typedef $$StorageRootsTableCreateCompanionBuilder =
    StorageRootsCompanion Function({
      required String id,
      required String path,
      Value<String?> label,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$StorageRootsTableUpdateCompanionBuilder =
    StorageRootsCompanion Function({
      Value<String> id,
      Value<String> path,
      Value<String?> label,
      Value<bool> isActive,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$StorageRootsTableFilterComposer
    extends Composer<_$AppDatabase, $StorageRootsTable> {
  $$StorageRootsTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StorageRootsTableOrderingComposer
    extends Composer<_$AppDatabase, $StorageRootsTable> {
  $$StorageRootsTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StorageRootsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StorageRootsTable> {
  $$StorageRootsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$StorageRootsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StorageRootsTable,
          StorageRoot,
          $$StorageRootsTableFilterComposer,
          $$StorageRootsTableOrderingComposer,
          $$StorageRootsTableAnnotationComposer,
          $$StorageRootsTableCreateCompanionBuilder,
          $$StorageRootsTableUpdateCompanionBuilder,
          (
            StorageRoot,
            BaseReferences<_$AppDatabase, $StorageRootsTable, StorageRoot>,
          ),
          StorageRoot,
          PrefetchHooks Function()
        > {
  $$StorageRootsTableTableManager(_$AppDatabase db, $StorageRootsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StorageRootsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StorageRootsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StorageRootsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageRootsCompanion(
                id: id,
                path: path,
                label: label,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String path,
                Value<String?> label = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorageRootsCompanion.insert(
                id: id,
                path: path,
                label: label,
                isActive: isActive,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StorageRootsTable, StorageRoot>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StorageRootsTable,
                    StorageRoot
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StorageRootsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StorageRootsTable,
      StorageRoot,
      $$StorageRootsTableFilterComposer,
      $$StorageRootsTableOrderingComposer,
      $$StorageRootsTableAnnotationComposer,
      $$StorageRootsTableCreateCompanionBuilder,
      $$StorageRootsTableUpdateCompanionBuilder,
      (
        StorageRoot,
        BaseReferences<_$AppDatabase, $StorageRootsTable, StorageRoot>,
      ),
      StorageRoot,
      PrefetchHooks Function()
    >;
typedef $$LocalOperationsTableCreateCompanionBuilder =
    LocalOperationsCompanion Function({
      required String id,
      required String kind,
      required String status,
      Value<String?> documentId,
      Value<String?> sourcePath,
      Value<String?> stagedPath,
      Value<String?> targetPath,
      Value<String?> checksum,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalOperationsTableUpdateCompanionBuilder =
    LocalOperationsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> status,
      Value<String?> documentId,
      Value<String?> sourcePath,
      Value<String?> stagedPath,
      Value<String?> targetPath,
      Value<String?> checksum,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOperationsTable> {
  $$LocalOperationsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stagedPath => $composableBuilder(
    column: $table.stagedPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetPath => $composableBuilder(
    column: $table.targetPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOperationsTable> {
  $$LocalOperationsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stagedPath => $composableBuilder(
    column: $table.stagedPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetPath => $composableBuilder(
    column: $table.targetPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checksum => $composableBuilder(
    column: $table.checksum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOperationsTable> {
  $$LocalOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcePath => $composableBuilder(
    column: $table.sourcePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stagedPath => $composableBuilder(
    column: $table.stagedPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetPath => $composableBuilder(
    column: $table.targetPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalOperationsTable,
          LocalOperation,
          $$LocalOperationsTableFilterComposer,
          $$LocalOperationsTableOrderingComposer,
          $$LocalOperationsTableAnnotationComposer,
          $$LocalOperationsTableCreateCompanionBuilder,
          $$LocalOperationsTableUpdateCompanionBuilder,
          (
            LocalOperation,
            BaseReferences<
              _$AppDatabase,
              $LocalOperationsTable,
              LocalOperation
            >,
          ),
          LocalOperation,
          PrefetchHooks Function()
        > {
  $$LocalOperationsTableTableManager(
    _$AppDatabase db,
    $LocalOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> documentId = const Value.absent(),
                Value<String?> sourcePath = const Value.absent(),
                Value<String?> stagedPath = const Value.absent(),
                Value<String?> targetPath = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOperationsCompanion(
                id: id,
                kind: kind,
                status: status,
                documentId: documentId,
                sourcePath: sourcePath,
                stagedPath: stagedPath,
                targetPath: targetPath,
                checksum: checksum,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String status,
                Value<String?> documentId = const Value.absent(),
                Value<String?> sourcePath = const Value.absent(),
                Value<String?> stagedPath = const Value.absent(),
                Value<String?> targetPath = const Value.absent(),
                Value<String?> checksum = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOperationsCompanion.insert(
                id: id,
                kind: kind,
                status: status,
                documentId: documentId,
                sourcePath: sourcePath,
                stagedPath: stagedPath,
                targetPath: targetPath,
                checksum: checksum,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalOperationsTable, LocalOperation>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalOperationsTable,
                    LocalOperation
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalOperationsTable,
      LocalOperation,
      $$LocalOperationsTableFilterComposer,
      $$LocalOperationsTableOrderingComposer,
      $$LocalOperationsTableAnnotationComposer,
      $$LocalOperationsTableCreateCompanionBuilder,
      $$LocalOperationsTableUpdateCompanionBuilder,
      (
        LocalOperation,
        BaseReferences<_$AppDatabase, $LocalOperationsTable, LocalOperation>,
      ),
      LocalOperation,
      PrefetchHooks Function()
    >;
typedef $$SyncJobsTableCreateCompanionBuilder = SyncJobsCompanion Function({
  required String id,
  required String documentId,
  required String destination,
  required String kind,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime?> nextRetryAt,
  Value<DateTime?> leasedUntil,
  required String accountBinding,
  Value<int> baseRevision,
  Value<String?> contentHash,
  Value<String?> revisionPayload,
  Value<String?> errorRedacted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$SyncJobsTableUpdateCompanionBuilder = SyncJobsCompanion Function({
  Value<String> id,
  Value<String> documentId,
  Value<String> destination,
  Value<String> kind,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime?> nextRetryAt,
  Value<DateTime?> leasedUntil,
  Value<String> accountBinding,
  Value<int> baseRevision,
  Value<String?> contentHash,
  Value<String?> revisionPayload,
  Value<String?> errorRedacted,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SyncJobsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableFilterComposer({
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

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leasedUntil => $composableBuilder(
    column: $table.leasedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountBinding => $composableBuilder(
    column: $table.accountBinding,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revisionPayload => $composableBuilder(
    column: $table.revisionPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorRedacted => $composableBuilder(
    column: $table.errorRedacted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableOrderingComposer({
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

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leasedUntil => $composableBuilder(
    column: $table.leasedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountBinding => $composableBuilder(
    column: $table.accountBinding,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revisionPayload => $composableBuilder(
    column: $table.revisionPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorRedacted => $composableBuilder(
    column: $table.errorRedacted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncJobsTable> {
  $$SyncJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get leasedUntil => $composableBuilder(
    column: $table.leasedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountBinding => $composableBuilder(
    column: $table.accountBinding,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseRevision => $composableBuilder(
    column: $table.baseRevision,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get revisionPayload => $composableBuilder(
    column: $table.revisionPayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorRedacted => $composableBuilder(
    column: $table.errorRedacted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncJobsTable,
          SyncJob,
          $$SyncJobsTableFilterComposer,
          $$SyncJobsTableOrderingComposer,
          $$SyncJobsTableAnnotationComposer,
          $$SyncJobsTableCreateCompanionBuilder,
          $$SyncJobsTableUpdateCompanionBuilder,
          (SyncJob, BaseReferences<_$AppDatabase, $SyncJobsTable, SyncJob>),
          SyncJob,
          PrefetchHooks Function()
        > {
  $$SyncJobsTableTableManager(_$AppDatabase db, $SyncJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime?> leasedUntil = const Value.absent(),
                Value<String> accountBinding = const Value.absent(),
                Value<int> baseRevision = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<String?> revisionPayload = const Value.absent(),
                Value<String?> errorRedacted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncJobsCompanion(
                id: id,
                documentId: documentId,
                destination: destination,
                kind: kind,
                status: status,
                attempts: attempts,
                nextRetryAt: nextRetryAt,
                leasedUntil: leasedUntil,
                accountBinding: accountBinding,
                baseRevision: baseRevision,
                contentHash: contentHash,
                revisionPayload: revisionPayload,
                errorRedacted: errorRedacted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required String destination,
                required String kind,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime?> leasedUntil = const Value.absent(),
                required String accountBinding,
                Value<int> baseRevision = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<String?> revisionPayload = const Value.absent(),
                Value<String?> errorRedacted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncJobsCompanion.insert(
                id: id,
                documentId: documentId,
                destination: destination,
                kind: kind,
                status: status,
                attempts: attempts,
                nextRetryAt: nextRetryAt,
                leasedUntil: leasedUntil,
                accountBinding: accountBinding,
                baseRevision: baseRevision,
                contentHash: contentHash,
                revisionPayload: revisionPayload,
                errorRedacted: errorRedacted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncJobsTable, SyncJob>(table),
                  BaseReferences<_$AppDatabase, $SyncJobsTable, SyncJob>(
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

typedef $$SyncJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncJobsTable,
      SyncJob,
      $$SyncJobsTableFilterComposer,
      $$SyncJobsTableOrderingComposer,
      $$SyncJobsTableAnnotationComposer,
      $$SyncJobsTableCreateCompanionBuilder,
      $$SyncJobsTableUpdateCompanionBuilder,
      (SyncJob, BaseReferences<_$AppDatabase, $SyncJobsTable, SyncJob>),
      SyncJob,
      PrefetchHooks Function()
    >;
typedef $$DocumentReplicasTableCreateCompanionBuilder =
    DocumentReplicasCompanion Function({
      required String id,
      required String documentId,
      required String destination,
      Value<String> status,
      Value<int> revisionAck,
      Value<String?> contentHashAck,
      Value<String?> remoteId,
      Value<String?> remoteName,
      Value<DateTime?> lastVerifiedAt,
      Value<String?> errorRedacted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DocumentReplicasTableUpdateCompanionBuilder =
    DocumentReplicasCompanion Function({
      Value<String> id,
      Value<String> documentId,
      Value<String> destination,
      Value<String> status,
      Value<int> revisionAck,
      Value<String?> contentHashAck,
      Value<String?> remoteId,
      Value<String?> remoteName,
      Value<DateTime?> lastVerifiedAt,
      Value<String?> errorRedacted,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DocumentReplicasTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentReplicasTable> {
  $$DocumentReplicasTableFilterComposer({
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

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revisionAck => $composableBuilder(
    column: $table.revisionAck,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHashAck => $composableBuilder(
    column: $table.contentHashAck,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorRedacted => $composableBuilder(
    column: $table.errorRedacted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentReplicasTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentReplicasTable> {
  $$DocumentReplicasTableOrderingComposer({
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

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisionAck => $composableBuilder(
    column: $table.revisionAck,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHashAck => $composableBuilder(
    column: $table.contentHashAck,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorRedacted => $composableBuilder(
    column: $table.errorRedacted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentReplicasTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentReplicasTable> {
  $$DocumentReplicasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destination => $composableBuilder(
    column: $table.destination,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get revisionAck => $composableBuilder(
    column: $table.revisionAck,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHashAck => $composableBuilder(
    column: $table.contentHashAck,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get remoteName => $composableBuilder(
    column: $table.remoteName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorRedacted => $composableBuilder(
    column: $table.errorRedacted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DocumentReplicasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentReplicasTable,
          DocumentReplica,
          $$DocumentReplicasTableFilterComposer,
          $$DocumentReplicasTableOrderingComposer,
          $$DocumentReplicasTableAnnotationComposer,
          $$DocumentReplicasTableCreateCompanionBuilder,
          $$DocumentReplicasTableUpdateCompanionBuilder,
          (
            DocumentReplica,
            BaseReferences<
              _$AppDatabase,
              $DocumentReplicasTable,
              DocumentReplica
            >,
          ),
          DocumentReplica,
          PrefetchHooks Function()
        > {
  $$DocumentReplicasTableTableManager(
    _$AppDatabase db,
    $DocumentReplicasTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentReplicasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentReplicasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentReplicasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> destination = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> revisionAck = const Value.absent(),
                Value<String?> contentHashAck = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> remoteName = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<String?> errorRedacted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentReplicasCompanion(
                id: id,
                documentId: documentId,
                destination: destination,
                status: status,
                revisionAck: revisionAck,
                contentHashAck: contentHashAck,
                remoteId: remoteId,
                remoteName: remoteName,
                lastVerifiedAt: lastVerifiedAt,
                errorRedacted: errorRedacted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required String destination,
                Value<String> status = const Value.absent(),
                Value<int> revisionAck = const Value.absent(),
                Value<String?> contentHashAck = const Value.absent(),
                Value<String?> remoteId = const Value.absent(),
                Value<String?> remoteName = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<String?> errorRedacted = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentReplicasCompanion.insert(
                id: id,
                documentId: documentId,
                destination: destination,
                status: status,
                revisionAck: revisionAck,
                contentHashAck: contentHashAck,
                remoteId: remoteId,
                remoteName: remoteName,
                lastVerifiedAt: lastVerifiedAt,
                errorRedacted: errorRedacted,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentReplicasTable, DocumentReplica>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DocumentReplicasTable,
                    DocumentReplica
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentReplicasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentReplicasTable,
      DocumentReplica,
      $$DocumentReplicasTableFilterComposer,
      $$DocumentReplicasTableOrderingComposer,
      $$DocumentReplicasTableAnnotationComposer,
      $$DocumentReplicasTableCreateCompanionBuilder,
      $$DocumentReplicasTableUpdateCompanionBuilder,
      (
        DocumentReplica,
        BaseReferences<_$AppDatabase, $DocumentReplicasTable, DocumentReplica>,
      ),
      DocumentReplica,
      PrefetchHooks Function()
    >;
typedef $$DriveUploadSessionsTableCreateCompanionBuilder =
    DriveUploadSessionsCompanion Function({
      required String id,
      required String jobId,
      required String documentId,
      required String sessionUri,
      Value<int> bytesAcknowledged,
      required int totalBytes,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DriveUploadSessionsTableUpdateCompanionBuilder =
    DriveUploadSessionsCompanion Function({
      Value<String> id,
      Value<String> jobId,
      Value<String> documentId,
      Value<String> sessionUri,
      Value<int> bytesAcknowledged,
      Value<int> totalBytes,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$DriveUploadSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $DriveUploadSessionsTable> {
  $$DriveUploadSessionsTableFilterComposer({
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

  ColumnFilters<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionUri => $composableBuilder(
    column: $table.sessionUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesAcknowledged => $composableBuilder(
    column: $table.bytesAcknowledged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DriveUploadSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DriveUploadSessionsTable> {
  $$DriveUploadSessionsTableOrderingComposer({
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

  ColumnOrderings<String> get jobId => $composableBuilder(
    column: $table.jobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionUri => $composableBuilder(
    column: $table.sessionUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesAcknowledged => $composableBuilder(
    column: $table.bytesAcknowledged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DriveUploadSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DriveUploadSessionsTable> {
  $$DriveUploadSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get jobId =>
      $composableBuilder(column: $table.jobId, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionUri => $composableBuilder(
    column: $table.sessionUri,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesAcknowledged => $composableBuilder(
    column: $table.bytesAcknowledged,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$DriveUploadSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DriveUploadSessionsTable,
          DriveUploadSession,
          $$DriveUploadSessionsTableFilterComposer,
          $$DriveUploadSessionsTableOrderingComposer,
          $$DriveUploadSessionsTableAnnotationComposer,
          $$DriveUploadSessionsTableCreateCompanionBuilder,
          $$DriveUploadSessionsTableUpdateCompanionBuilder,
          (
            DriveUploadSession,
            BaseReferences<
              _$AppDatabase,
              $DriveUploadSessionsTable,
              DriveUploadSession
            >,
          ),
          DriveUploadSession,
          PrefetchHooks Function()
        > {
  $$DriveUploadSessionsTableTableManager(
    _$AppDatabase db,
    $DriveUploadSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriveUploadSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriveUploadSessionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DriveUploadSessionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> jobId = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> sessionUri = const Value.absent(),
                Value<int> bytesAcknowledged = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DriveUploadSessionsCompanion(
                id: id,
                jobId: jobId,
                documentId: documentId,
                sessionUri: sessionUri,
                bytesAcknowledged: bytesAcknowledged,
                totalBytes: totalBytes,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String jobId,
                required String documentId,
                required String sessionUri,
                Value<int> bytesAcknowledged = const Value.absent(),
                required int totalBytes,
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DriveUploadSessionsCompanion.insert(
                id: id,
                jobId: jobId,
                documentId: documentId,
                sessionUri: sessionUri,
                bytesAcknowledged: bytesAcknowledged,
                totalBytes: totalBytes,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DriveUploadSessionsTable, DriveUploadSession>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DriveUploadSessionsTable,
                    DriveUploadSession
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DriveUploadSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DriveUploadSessionsTable,
      DriveUploadSession,
      $$DriveUploadSessionsTableFilterComposer,
      $$DriveUploadSessionsTableOrderingComposer,
      $$DriveUploadSessionsTableAnnotationComposer,
      $$DriveUploadSessionsTableCreateCompanionBuilder,
      $$DriveUploadSessionsTableUpdateCompanionBuilder,
      (
        DriveUploadSession,
        BaseReferences<
          _$AppDatabase,
          $DriveUploadSessionsTable,
          DriveUploadSession
        >,
      ),
      DriveUploadSession,
      PrefetchHooks Function()
    >;
typedef $$DocumentCategoriesTableCreateCompanionBuilder =
    DocumentCategoriesCompanion Function({
      required String code,
      required String name,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$DocumentCategoriesTableUpdateCompanionBuilder =
    DocumentCategoriesCompanion Function({
      Value<String> code,
      Value<String> name,
      Value<bool> archived,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DocumentCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentCategoriesTable> {
  $$DocumentCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentCategoriesTable> {
  $$DocumentCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentCategoriesTable> {
  $$DocumentCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DocumentCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentCategoriesTable,
          DocumentCategory,
          $$DocumentCategoriesTableFilterComposer,
          $$DocumentCategoriesTableOrderingComposer,
          $$DocumentCategoriesTableAnnotationComposer,
          $$DocumentCategoriesTableCreateCompanionBuilder,
          $$DocumentCategoriesTableUpdateCompanionBuilder,
          (
            DocumentCategory,
            BaseReferences<
              _$AppDatabase,
              $DocumentCategoriesTable,
              DocumentCategory
            >,
          ),
          DocumentCategory,
          PrefetchHooks Function()
        > {
  $$DocumentCategoriesTableTableManager(
    _$AppDatabase db,
    $DocumentCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> code = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentCategoriesCompanion(
                code: code,
                name: name,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String code,
                required String name,
                Value<bool> archived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentCategoriesCompanion.insert(
                code: code,
                name: name,
                archived: archived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentCategoriesTable, DocumentCategory>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $DocumentCategoriesTable,
                    DocumentCategory
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentCategoriesTable,
      DocumentCategory,
      $$DocumentCategoriesTableFilterComposer,
      $$DocumentCategoriesTableOrderingComposer,
      $$DocumentCategoriesTableAnnotationComposer,
      $$DocumentCategoriesTableCreateCompanionBuilder,
      $$DocumentCategoriesTableUpdateCompanionBuilder,
      (
        DocumentCategory,
        BaseReferences<
          _$AppDatabase,
          $DocumentCategoriesTable,
          DocumentCategory
        >,
      ),
      DocumentCategory,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
          Tag,
          PrefetchHooks Function()
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  BaseReferences<_$AppDatabase, $TagsTable, Tag>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, BaseReferences<_$AppDatabase, $TagsTable, Tag>),
      Tag,
      PrefetchHooks Function()
    >;
typedef $$DocumentTagsTableCreateCompanionBuilder =
    DocumentTagsCompanion Function({
      required String documentId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$DocumentTagsTableUpdateCompanionBuilder =
    DocumentTagsCompanion Function({
      Value<String> documentId,
      Value<String> tagId,
      Value<int> rowid,
    });

class $$DocumentTagsTableFilterComposer
    extends Composer<_$AppDatabase, $DocumentTagsTable> {
  $$DocumentTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DocumentTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $DocumentTagsTable> {
  $$DocumentTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DocumentTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DocumentTagsTable> {
  $$DocumentTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);
}

class $$DocumentTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DocumentTagsTable,
          DocumentTag,
          $$DocumentTagsTableFilterComposer,
          $$DocumentTagsTableOrderingComposer,
          $$DocumentTagsTableAnnotationComposer,
          $$DocumentTagsTableCreateCompanionBuilder,
          $$DocumentTagsTableUpdateCompanionBuilder,
          (
            DocumentTag,
            BaseReferences<_$AppDatabase, $DocumentTagsTable, DocumentTag>,
          ),
          DocumentTag,
          PrefetchHooks Function()
        > {
  $$DocumentTagsTableTableManager(_$AppDatabase db, $DocumentTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DocumentTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DocumentTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DocumentTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentTagsCompanion(
                documentId: documentId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => DocumentTagsCompanion.insert(
                documentId: documentId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DocumentTagsTable, DocumentTag>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DocumentTagsTable,
                    DocumentTag
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DocumentTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DocumentTagsTable,
      DocumentTag,
      $$DocumentTagsTableFilterComposer,
      $$DocumentTagsTableOrderingComposer,
      $$DocumentTagsTableAnnotationComposer,
      $$DocumentTagsTableCreateCompanionBuilder,
      $$DocumentTagsTableUpdateCompanionBuilder,
      (
        DocumentTag,
        BaseReferences<_$AppDatabase, $DocumentTagsTable, DocumentTag>,
      ),
      DocumentTag,
      PrefetchHooks Function()
    >;
typedef $$CollectionsTableCreateCompanionBuilder =
    CollectionsCompanion Function({
      required String id,
      required String name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$CollectionsTableUpdateCompanionBuilder =
    CollectionsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CollectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionsTable,
          Collection,
          $$CollectionsTableFilterComposer,
          $$CollectionsTableOrderingComposer,
          $$CollectionsTableAnnotationComposer,
          $$CollectionsTableCreateCompanionBuilder,
          $$CollectionsTableUpdateCompanionBuilder,
          (
            Collection,
            BaseReferences<_$AppDatabase, $CollectionsTable, Collection>,
          ),
          Collection,
          PrefetchHooks Function()
        > {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionsCompanion.insert(
                id: id,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionsTable, Collection>(table),
                  BaseReferences<_$AppDatabase, $CollectionsTable, Collection>(
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

typedef $$CollectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionsTable,
      Collection,
      $$CollectionsTableFilterComposer,
      $$CollectionsTableOrderingComposer,
      $$CollectionsTableAnnotationComposer,
      $$CollectionsTableCreateCompanionBuilder,
      $$CollectionsTableUpdateCompanionBuilder,
      (
        Collection,
        BaseReferences<_$AppDatabase, $CollectionsTable, Collection>,
      ),
      Collection,
      PrefetchHooks Function()
    >;
typedef $$CollectionItemsTableCreateCompanionBuilder =
    CollectionItemsCompanion Function({
      required String collectionId,
      required String documentId,
      Value<int> rowid,
    });
typedef $$CollectionItemsTableUpdateCompanionBuilder =
    CollectionItemsCompanion Function({
      Value<String> collectionId,
      Value<String> documentId,
      Value<int> rowid,
    });

class $$CollectionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get collectionId => $composableBuilder(
    column: $table.collectionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );
}

class $$CollectionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionItemsTable,
          CollectionItem,
          $$CollectionItemsTableFilterComposer,
          $$CollectionItemsTableOrderingComposer,
          $$CollectionItemsTableAnnotationComposer,
          $$CollectionItemsTableCreateCompanionBuilder,
          $$CollectionItemsTableUpdateCompanionBuilder,
          (
            CollectionItem,
            BaseReferences<
              _$AppDatabase,
              $CollectionItemsTable,
              CollectionItem
            >,
          ),
          CollectionItem,
          PrefetchHooks Function()
        > {
  $$CollectionItemsTableTableManager(
    _$AppDatabase db,
    $CollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> collectionId = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion(
                collectionId: collectionId,
                documentId: documentId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String collectionId,
                required String documentId,
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion.insert(
                collectionId: collectionId,
                documentId: documentId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CollectionItemsTable, CollectionItem>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CollectionItemsTable,
                    CollectionItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionItemsTable,
      CollectionItem,
      $$CollectionItemsTableFilterComposer,
      $$CollectionItemsTableOrderingComposer,
      $$CollectionItemsTableAnnotationComposer,
      $$CollectionItemsTableCreateCompanionBuilder,
      $$CollectionItemsTableUpdateCompanionBuilder,
      (
        CollectionItem,
        BaseReferences<_$AppDatabase, $CollectionItemsTable, CollectionItem>,
      ),
      CollectionItem,
      PrefetchHooks Function()
    >;
typedef $$SavedViewsTableCreateCompanionBuilder = SavedViewsCompanion Function({
  required String id,
  required String name,
  required String stateJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$SavedViewsTableUpdateCompanionBuilder = SavedViewsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> stateJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$SavedViewsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedViewsTable> {
  $$SavedViewsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedViewsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedViewsTable> {
  $$SavedViewsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stateJson => $composableBuilder(
    column: $table.stateJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedViewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedViewsTable> {
  $$SavedViewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get stateJson =>
      $composableBuilder(column: $table.stateJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SavedViewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SavedViewsTable,
          SavedView,
          $$SavedViewsTableFilterComposer,
          $$SavedViewsTableOrderingComposer,
          $$SavedViewsTableAnnotationComposer,
          $$SavedViewsTableCreateCompanionBuilder,
          $$SavedViewsTableUpdateCompanionBuilder,
          (
            SavedView,
            BaseReferences<_$AppDatabase, $SavedViewsTable, SavedView>,
          ),
          SavedView,
          PrefetchHooks Function()
        > {
  $$SavedViewsTableTableManager(_$AppDatabase db, $SavedViewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedViewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedViewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedViewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> stateJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedViewsCompanion(
                id: id,
                name: name,
                stateJson: stateJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String stateJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavedViewsCompanion.insert(
                id: id,
                name: name,
                stateJson: stateJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedViewsTable, SavedView>(table),
                  BaseReferences<_$AppDatabase, $SavedViewsTable, SavedView>(
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

typedef $$SavedViewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SavedViewsTable,
      SavedView,
      $$SavedViewsTableFilterComposer,
      $$SavedViewsTableOrderingComposer,
      $$SavedViewsTableAnnotationComposer,
      $$SavedViewsTableCreateCompanionBuilder,
      $$SavedViewsTableUpdateCompanionBuilder,
      (SavedView, BaseReferences<_$AppDatabase, $SavedViewsTable, SavedView>),
      SavedView,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalDocumentsTableTableManager get localDocuments =>
      $$LocalDocumentsTableTableManager(_db, _db.localDocuments);
  $$StorageRootsTableTableManager get storageRoots =>
      $$StorageRootsTableTableManager(_db, _db.storageRoots);
  $$LocalOperationsTableTableManager get localOperations =>
      $$LocalOperationsTableTableManager(_db, _db.localOperations);
  $$SyncJobsTableTableManager get syncJobs =>
      $$SyncJobsTableTableManager(_db, _db.syncJobs);
  $$DocumentReplicasTableTableManager get documentReplicas =>
      $$DocumentReplicasTableTableManager(_db, _db.documentReplicas);
  $$DriveUploadSessionsTableTableManager get driveUploadSessions =>
      $$DriveUploadSessionsTableTableManager(_db, _db.driveUploadSessions);
  $$DocumentCategoriesTableTableManager get documentCategories =>
      $$DocumentCategoriesTableTableManager(_db, _db.documentCategories);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$DocumentTagsTableTableManager get documentTags =>
      $$DocumentTagsTableTableManager(_db, _db.documentTags);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
  $$SavedViewsTableTableManager get savedViews =>
      $$SavedViewsTableTableManager(_db, _db.savedViews);
}
