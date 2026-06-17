// This is a generated file - do not edit.
//
// Generated from log_service.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use levelDescriptor instead')
const Level$json = {
  '1': 'Level',
  '2': [
    {'1': 'LEVEL_UNSPECIFIED', '2': 0},
    {'1': 'LEVEL_CRITICAL', '2': 1},
    {'1': 'LEVEL_ERROR', '2': 2},
    {'1': 'LEVEL_WARNING', '2': 3},
    {'1': 'LEVEL_INFO', '2': 4},
    {'1': 'LEVEL_DEBUG', '2': 5},
    {'1': 'LEVEL_VERBOSE', '2': 6},
  ],
};

/// Descriptor for `Level`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List levelDescriptor = $convert.base64Decode(
    'CgVMZXZlbBIVChFMRVZFTF9VTlNQRUNJRklFRBAAEhIKDkxFVkVMX0NSSVRJQ0FMEAESDwoLTE'
    'VWRUxfRVJST1IQAhIRCg1MRVZFTF9XQVJOSU5HEAMSDgoKTEVWRUxfSU5GTxAEEg8KC0xFVkVM'
    'X0RFQlVHEAUSEQoNTEVWRUxfVkVSQk9TRRAG');

@$core.Deprecated('Use logEntryDescriptor instead')
const LogEntry$json = {
  '1': 'LogEntry',
  '2': [
    {'1': 'level', '3': 1, '4': 1, '5': 14, '6': '.logui.Level', '10': 'level'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
    {'1': 'time', '3': 4, '4': 1, '5': 3, '10': 'time'},
  ],
};

/// Descriptor for `LogEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logEntryDescriptor = $convert.base64Decode(
    'CghMb2dFbnRyeRIiCgVsZXZlbBgBIAEoDjIMLmxvZ3VpLkxldmVsUgVsZXZlbBIUCgV0aXRsZR'
    'gCIAEoCVIFdGl0bGUSGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZRISCgR0aW1lGAQgASgDUgR0'
    'aW1l');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor =
    $convert.base64Decode('CgVFbXB0eQ==');

const $core.Map<$core.String, $core.dynamic> LogServiceBase$json = {
  '1': 'LogService',
  '2': [
    {'1': 'SendLog', '2': '.logui.LogEntry', '3': '.logui.Empty'},
  ],
};

@$core.Deprecated('Use logServiceDescriptor instead')
const $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>>
    LogServiceBase$messageJson = {
  '.logui.LogEntry': LogEntry$json,
  '.logui.Empty': Empty$json,
};

/// Descriptor for `LogService`. Decode as a `google.protobuf.ServiceDescriptorProto`.
final $typed_data.Uint8List logServiceDescriptor = $convert.base64Decode(
    'CgpMb2dTZXJ2aWNlEigKB1NlbmRMb2cSDy5sb2d1aS5Mb2dFbnRyeRoMLmxvZ3VpLkVtcHR5');
