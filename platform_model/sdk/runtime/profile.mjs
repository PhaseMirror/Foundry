/** The only runtime profile interpreted by the production command-service host. */
export const TRANSACTIONAL_COMMAND_SERVICE_PROFILE = 'prismpm/transactional-command-service/1';

const profileKeys = [
  'acceptance_conflict_input_b', 'acceptance_error_input_a', 'acceptance_error_input_b',
  'acceptance_error_operation', 'acceptance_expected_error', 'acceptance_expected_result',
  'acceptance_success_input_a', 'acceptance_success_input_b', 'acceptance_success_operation',
  'accepted_event_type', 'annotation_column', 'annotation_field', 'annotation_max_scalars',
  'application_errors', 'application_model_digest', 'audit_queue', 'audit_table', 'availability_threshold_millionths',
  'broker_user', 'command_encoding', 'command_id_field', 'command_id_pattern',
  'command_id_column', 'command_operations', 'command_path', 'contract', 'core_artifact', 'database_name',
  'database_user', 'event_exchange', 'event_source', 'history_default_limit',
  'history_max_limit', 'history_table', 'identity_audience', 'input_a_column', 'input_a_field',
  'input_b_column', 'input_b_field', 'max_request_bytes', 'observer_role', 'operation_column',
  'operation_field', 'optional_annotation',
  'outbox_lag_threshold_millis', 'outbox_table', 'public_hostname_parameter',
  'redacted_fields', 'rejected_event_type', 'release', 'response_version', 'submitter_role',
  'token_path', 'view', 'product_id'
].sort();
const viewKeys = [
  'access_denied_text', 'annotation_heading', 'annotation_label', 'authenticated_text',
  'authenticate_label', 'authenticating_text', 'authentication_failed_text',
  'command_column_heading', 'command_failed_text', 'command_form_heading', 'command_id_label',
  'denied_role_label', 'empty_text', 'heading', 'history_empty_text', 'history_failed_text', 'history_heading',
  'history_loaded_text', 'identity_heading', 'input_a_label', 'input_b_label',
  'input_summary_heading', 'loading_text', 'operation_label', 'outcome_heading',
  'outcome_prefix', 'principal_default', 'principal_label', 'refresh_label', 'release_prefix',
  'retry_label', 'role_label', 'sequence_heading', 'submit_label', 'submitter_role_label',
  'submitting_text', 'observer_role_label', 'title'
].sort();

function exactKeys(value, expected, name) {
  if (!value || typeof value !== 'object' || Array.isArray(value)
      || JSON.stringify(Object.keys(value).sort()) !== JSON.stringify(expected)) {
    throw new Error(`${name} has missing or unknown terms`);
  }
}

/** Validate the closed typed profile before any listener or dependency is started. */
export function validateApplicationProfile(value) {
  exactKeys(value, profileKeys, 'application profile');
  if (value.contract !== TRANSACTIONAL_COMMAND_SERVICE_PROFILE) {
    throw new Error(`unsupported application profile ${String(value.contract)}`);
  }
  exactKeys(value.view, viewKeys, 'application profile View');
  const stringTerms = [
    'acceptance_conflict_input_b', 'acceptance_error_input_a', 'acceptance_error_input_b',
    'acceptance_error_operation', 'acceptance_expected_error', 'acceptance_expected_result',
    'acceptance_success_input_a', 'acceptance_success_input_b', 'acceptance_success_operation',
    'accepted_event_type', 'annotation_column', 'annotation_field', 'application_model_digest',
    'audit_queue', 'audit_table', 'broker_user', 'command_encoding', 'command_id_column',
    'command_id_field', 'command_id_pattern', 'command_path', 'contract', 'core_artifact',
    'database_name', 'database_user', 'event_exchange', 'event_source', 'history_table',
    'identity_audience', 'input_a_column', 'input_a_field', 'input_b_column', 'input_b_field',
    'observer_role', 'operation_column', 'operation_field', 'outbox_table', 'product_id',
    'public_hostname_parameter', 'rejected_event_type', 'release', 'response_version',
    'submitter_role', 'token_path'
  ];
  if (stringTerms.some((name) => typeof value[name] !== 'string' || value[name].length === 0)
      || viewKeys.some((name) => typeof value.view[name] !== 'string' || value.view[name].length === 0)) {
    throw new Error('application profile contains an absent or non-string term');
  }
  const positiveIntegers = ['annotation_max_scalars', 'history_default_limit', 'history_max_limit', 'max_request_bytes', 'outbox_lag_threshold_millis'];
  if (positiveIntegers.some((name) => !Number.isSafeInteger(value[name]) || value[name] < 1)
      || !Number.isSafeInteger(value.availability_threshold_millionths)
      || value.availability_threshold_millionths < 0 || value.availability_threshold_millionths > 1000000
      || value.history_default_limit > value.history_max_limit) {
    throw new Error('application profile numeric bounds are invalid');
  }
  if (!/^sha256:[0-9a-f]{64}$/.test(value.application_model_digest)
      || !/^\/[^?#]*$/.test(value.command_path) || !/^\/[^?#]*$/.test(value.token_path)
      || !['absent', 'optional'].includes(value.optional_annotation)) {
    throw new Error('application profile digest, path, or optional-annotation term is invalid');
  }
  try { new RegExp(value.command_id_pattern); } catch { throw new Error('application profile command ID pattern is invalid'); }
  const fieldNames = ['command_id_field', 'operation_field', 'input_a_field', 'input_b_field', 'annotation_field'].map((name) => value[name]);
  if (new Set(fieldNames).size !== fieldNames.length || fieldNames.some((name) => !/^[A-Za-z_][A-Za-z0-9_]{0,127}$/.test(name))) {
    throw new Error('application profile command fields must be distinct JSON member names');
  }
  const storageColumns = ['command_id_column', 'operation_column', 'input_a_column', 'input_b_column', 'annotation_column'].map((name) => value[name]);
  if (new Set(storageColumns).size !== storageColumns.length
      || storageColumns.some((name) => !/^[a-z][a-z0-9_]{0,62}$/.test(name))) {
    throw new Error('application profile storage columns must be distinct SQL identifiers');
  }
  if (!Array.isArray(value.command_operations) || value.command_operations.length === 0
      || value.command_operations.some((operation) => typeof operation !== 'string' || operation.length === 0)
      || new Set(value.command_operations).size !== value.command_operations.length) {
    throw new Error('application profile command operations are absent or duplicate');
  }
  if (!Array.isArray(value.application_errors) || value.application_errors.length === 0
      || !Array.isArray(value.redacted_fields)
      || value.redacted_fields.some((name) => typeof name !== 'string' || name.length === 0)) {
    throw new Error('application profile errors are absent');
  }
  const wireNames = new Set();
  const modelNames = new Set();
  for (const error of value.application_errors) {
    exactKeys(error, ['model_name', 'wire_name'], 'application error binding');
    if (typeof error.wire_name !== 'string' || error.wire_name.length === 0
        || typeof error.model_name !== 'string' || error.model_name.length === 0
        || wireNames.has(error.wire_name) || modelNames.has(error.model_name)) {
      throw new Error('application error bindings must be one-to-one');
    }
    wireNames.add(error.wire_name);
    modelNames.add(error.model_name);
  }
  const acceptanceIntegers = [
    value.acceptance_error_input_a, value.acceptance_error_input_b,
    value.acceptance_conflict_input_b, value.acceptance_success_input_a,
    value.acceptance_success_input_b, value.acceptance_expected_result
  ];
  if (![value.acceptance_error_operation, value.acceptance_success_operation]
        .every((operation) => value.command_operations.includes(operation))
      || !modelNames.has(value.acceptance_expected_error)
      || acceptanceIntegers.some((integer) => !/^(?:0|-[1-9][0-9]*|[1-9][0-9]*)$/.test(integer)
        || BigInt(integer) < -9223372036854775808n || BigInt(integer) > 9223372036854775807n)
      || value.acceptance_error_input_b === value.acceptance_conflict_input_b) {
    throw new Error('application profile acceptance bindings are inconsistent');
  }
  if (value.submitter_role === value.observer_role
      || !['{operation}', '{inputA}', '{inputB}'].every((term) => value.command_encoding.includes(term))) {
    throw new Error('application profile command, role, or encoding terms are inconsistent');
  }
  return value;
}

/**
 * Resolve the only two modeled history visibility modes. Unknown roles are
 * denied instead of being silently treated as a subject-scoped submitter.
 */
export function historyVisibility(roles, profile) {
  if (!(roles instanceof Set)) throw new Error('history roles must be a Set');
  if (roles.has(profile.observer_role)) return 'all-subjects';
  if (roles.has(profile.submitter_role)) return 'own-subject';
  return null;
}

/** OpenID Connect Core 1.0 Subject Identifier lexical boundary. */
export function validOidcSubject(value) {
  return typeof value === 'string' && /^[\x00-\x7f]{1,255}$/.test(value);
}
