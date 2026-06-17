// This is a generated file - do not edit.
//
// Generated from log_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

/// / Log level enum, aligned with talker [LogLevel].
class Level extends $pb.ProtobufEnum {
  static const Level LEVEL_UNSPECIFIED =
      Level._(0, _omitEnumNames ? '' : 'LEVEL_UNSPECIFIED');
  static const Level LEVEL_CRITICAL =
      Level._(1, _omitEnumNames ? '' : 'LEVEL_CRITICAL');
  static const Level LEVEL_ERROR =
      Level._(2, _omitEnumNames ? '' : 'LEVEL_ERROR');
  static const Level LEVEL_WARNING =
      Level._(3, _omitEnumNames ? '' : 'LEVEL_WARNING');
  static const Level LEVEL_INFO =
      Level._(4, _omitEnumNames ? '' : 'LEVEL_INFO');
  static const Level LEVEL_DEBUG =
      Level._(5, _omitEnumNames ? '' : 'LEVEL_DEBUG');
  static const Level LEVEL_VERBOSE =
      Level._(6, _omitEnumNames ? '' : 'LEVEL_VERBOSE');

  static const $core.List<Level> values = <Level>[
    LEVEL_UNSPECIFIED,
    LEVEL_CRITICAL,
    LEVEL_ERROR,
    LEVEL_WARNING,
    LEVEL_INFO,
    LEVEL_DEBUG,
    LEVEL_VERBOSE,
  ];

  static final $core.List<Level?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static Level? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Level._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
