import assert from 'node:assert/strict';
import test from 'node:test';
import { historyVisibility, validOidcSubject, validateApplicationProfile } from './profile.mjs';

const viewTerms = [
  'access_denied_text', 'annotation_heading', 'annotation_label', 'authenticated_text',
  'authenticate_label', 'authenticating_text', 'authentication_failed_text',
  'command_column_heading', 'command_failed_text', 'command_form_heading', 'command_id_label',
  'denied_role_label', 'empty_text', 'heading', 'history_empty_text', 'history_failed_text', 'history_heading',
  'history_loaded_text', 'identity_heading', 'input_a_label', 'input_b_label',
  'input_summary_heading', 'loading_text', 'operation_label', 'outcome_heading',
  'outcome_prefix', 'principal_default', 'principal_label', 'refresh_label', 'release_prefix',
  'retry_label', 'role_label', 'sequence_heading', 'submit_label', 'submitter_role_label',
  'submitting_text', 'observer_role_label', 'title'
];

function validProfile() {
  return {
    acceptance_conflict_input_b: '0', acceptance_error_input_a: '9223372036854775807',
    acceptance_error_input_b: '-1', acceptance_error_operation: 'reject',
    acceptance_expected_error: 'Rejected', acceptance_expected_result: '42',
    acceptance_success_input_a: '7', acceptance_success_input_b: '6',
    acceptance_success_operation: 'execute', accepted_event_type: 'example.command.accepted.v1',
    annotation_column: 'annotation', annotation_field: 'annotation',
    annotation_max_scalars: 128, application_errors: [{ model_name: 'Rejected', wire_name: 'rejected' }],
    application_model_digest: `sha256:${'0'.repeat(64)}`, audit_queue: 'application.audit',
    audit_table: 'command_audit', availability_threshold_millionths: 990000,
    broker_user: 'application', command_encoding: '1\t{operation}\t{inputA}\t{inputB}',
    command_id_column: 'command_id', command_id_field: 'command_id',
    command_id_pattern: '^[a-z][a-z0-9-]{0,62}$',
    command_operations: ['execute', 'reject'], command_path: '/v1/commands',
    contract: 'prismpm/transactional-command-service/1', core_artifact: 'core.wasm',
    database_name: 'application', database_user: 'application', event_exchange: 'application.events',
    event_source: 'https://example.invalid/application', history_default_limit: 25,
    history_max_limit: 100, history_table: 'command_history', identity_audience: 'application-api',
    input_a_column: 'input_a', input_a_field: 'input_a', input_b_column: 'input_b',
    input_b_field: 'input_b', max_request_bytes: 16384,
    observer_role: 'application.observer', operation_column: 'operation',
    operation_field: 'operation', optional_annotation: 'optional',
    outbox_lag_threshold_millis: 5000, outbox_table: 'command_outbox', product_id: 'application',
    public_hostname_parameter: 'public-hostname', redacted_fields: ['authorization'],
    rejected_event_type: 'example.command.rejected.v1', release: '1', response_version: '1',
    submitter_role: 'application.submitter', token_path: '/oidc/token',
    view: Object.fromEntries(viewTerms.map((name) => [name, name]))
  };
}

test('accepts the complete typed transactional-command profile', () => {
  const value = validProfile();
  assert.equal(validateApplicationProfile(value), value);
});

test('history visibility is closed over the two modeled roles', () => {
  const profile = validProfile();
  assert.equal(historyVisibility(new Set([profile.observer_role]), profile), 'all-subjects');
  assert.equal(historyVisibility(new Set([profile.submitter_role]), profile), 'own-subject');
  assert.equal(historyVisibility(new Set([profile.observer_role, profile.submitter_role]), profile), 'all-subjects');
  assert.equal(historyVisibility(new Set(['application.unmodeled']), profile), null);
  assert.equal(historyVisibility(new Set(), profile), null);
});

test('OIDC subject identifiers are nonempty ASCII strings of at most 255 characters', () => {
  assert.equal(validOidcSubject('Case-Sensitive-Subject'), true);
  assert.equal(validOidcSubject('a'.repeat(255)), true);
  assert.equal(validOidcSubject(''), false);
  assert.equal(validOidcSubject('a'.repeat(256)), false);
  assert.equal(validOidcSubject('subject-é'), false);
});

for (const [name, mutate, diagnostic] of [
  ['missing term', (value) => { delete value.command_path; }, /missing or unknown terms/],
  ['unknown term', (value) => { value.undeclared_path = '/v1/commands'; }, /missing or unknown terms/],
  ['unknown contract', (value) => { value.contract = 'prismpm/unknown/1'; }, /unsupported application profile/],
  ['duplicate input field', (value) => { value.input_b_field = value.input_a_field; }, /distinct JSON member names/],
  ['duplicate storage column', (value) => { value.input_b_column = value.input_a_column; }, /distinct SQL identifiers/],
  ['missing View term', (value) => { delete value.view.command_form_heading; }, /missing or unknown terms/],
  ['duplicate operation', (value) => { value.command_operations.push('execute'); }, /absent or duplicate/],
  ['duplicate error binding', (value) => { value.application_errors.push({ model_name: 'Rejected', wire_name: 'other' }); }, /one-to-one/],
  ['malformed digest', (value) => { value.application_model_digest = 'latest'; }, /digest, path, or optional-annotation/],
  ['incomplete encoding', (value) => { value.command_encoding = '1\t{operation}'; }, /command, role, or encoding/],
  ['unmodeled acceptance operation', (value) => { value.acceptance_error_operation = 'missing'; }, /acceptance bindings/]
]) {
  test(`rejects ${name}`, () => {
    const value = validProfile();
    mutate(value);
    assert.throws(() => validateApplicationProfile(value), diagnostic);
  });
}
