module.exports = grammar({
  name: 'pirtm',

  rules: {
    // The canonical document consists of rigorous state declarations and operations
    source_file: $ => repeat($.statement),

    statement: $ => choice(
      $.tensor_declaration,
      $.operator_application,
      $.contractivity_assertion
    ),

    // e.g., tensor M_state[p_2, p_3];
    tensor_declaration: $ => seq(
      'tensor',
      field('name', $.identifier),
      '[',
      field('prime_axes', $.prime_list),
      ']',
      ';'
    ),

    // e.g., M_state |> \Lambda_m * p_5 * p_7;
    operator_application: $ => seq(
      field('target', $.identifier),
      '|>',
      optional(seq(field('scaling_factor', $.lambda_constant), '*')),
      field('prime_chain', $.prime_chain),
      ';'
    ),

    // e.g., assert_contractive(M_state) < 1.0;
    contractivity_assertion: $ => seq(
      'assert_contractive',
      '(',
      field('target', $.identifier),
      ')',
      '<',
      field('bound', $.float),
      ';'
    ),

    prime_list: $ => sepBy1(',', $.prime_literal),
    
    prime_chain: $ => sepBy1('*', $.prime_literal),

    // Primes must be explicitly denoted to prevent integer overlap (e.g., p_2, p_108)
    prime_literal: $ => /p_[1-9][0-9]*/,

    lambda_constant: $ => '\\Lambda_m',

    identifier: $ => /[a-zA-Z_][a-zA-Z0-9_]*/,
    
    float: $ => /[0-9]+\.[0-9]+/,
  }
});

function sepBy1(sep, rule) {
  return seq(rule, repeat(seq(sep, rule)));
}
