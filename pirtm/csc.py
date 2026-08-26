"""
pirtm/csc.py
============
Recursive Descent Decoding Parser for PIRTM-lang Source and Bytecode Specifications.
Translates tensor declarations, operator applications, and contractivity assertions
into verified AST representations.
"""

import re
from dataclasses import dataclass
from typing import List, Union, Optional, Tuple


@dataclass(frozen=True)
class TensorDeclaration:
    identifier: str
    primes: List[str]


@dataclass(frozen=True)
class OperatorApplication:
    identifier: str
    has_lambda: bool
    prime_chain: List[str]


@dataclass(frozen=True)
class ContractivityAssertion:
    identifier: str
    bound: float


Statement = Union[TensorDeclaration, OperatorApplication, ContractivityAssertion]


class PIRTMDecoderParser:
    """
    Recursive descent decoder parser for PIRTM EBNF grammar.
    """

    def __init__(self, source_code: Optional[str] = None):
        self.source_code = source_code
        self.tokens: List[Tuple[str, str]] = []
        self.pos = 0
        if source_code is not None:
            self.tokens = self._tokenize(source_code)

    def _tokenize(self, code: str) -> List[Tuple[str, str]]:
        # Lexical rules aligned with the PIRTM EBNF specification
        token_specification = [
            ('COMMENT', r'#.*$'),
            ('KEYWORD', r'\b(tensor|assert_contractive)\b'),
            ('LAMBDA', r'(\\Lambda_m|Λ_m)'),
            ('PRIME', r'p_\d+'),
            ('FLOAT', r'\d+\.\d+'),
            ('IDENT', r'[a-zA-Z_][a-zA-Z0-9_]*'),
            ('OP', r'\|>|\*|\[|\]|\(|\)|,|;|<|>'),
            ('SKIP', r'[ \t\n\r]+'),
            ('MISMATCH', r'.'),
        ]
        tok_regex = '|'.join(f'(?P<{name}>{pat})' for name, pat in token_specification)
        tokens = []
        for mo in re.finditer(tok_regex, code, re.MULTILINE):
            kind = mo.lastgroup
            value = mo.group(kind)
            if kind == 'SKIP' or kind == 'COMMENT':
                continue
            elif kind == 'MISMATCH':
                raise SyntaxError(f"Unexpected character: '{value}'")
            tokens.append((kind, value))
        return tokens

    def _peek(self) -> Optional[Tuple[str, str]]:
        if self.pos < len(self.tokens):
            return self.tokens[self.pos]
        return None

    def _consume(self, expected_kind: Optional[str] = None, expected_val: Optional[str] = None) -> Tuple[str, str]:
        tok = self._peek()
        if not tok:
            raise SyntaxError("Unexpected end of file during decoding.")
        kind, val = tok
        if expected_kind and kind != expected_kind:
            raise SyntaxError(f"Expected token kind {expected_kind}, got {kind} ('{val}')")
        if expected_val and val != expected_val:
            raise SyntaxError(f"Expected token value '{expected_val}', got '{val}'")
        self.pos += 1
        return tok

    def parse(self, source_code: Optional[str] = None) -> List[Statement]:
        """Parses the provided source code or the source code passed during initialization."""
        if source_code is not None:
            self.source_code = source_code
            self.tokens = self._tokenize(source_code)
            self.pos = 0
        return self.parse_source()

    def parse_source(self) -> List[Statement]:
        statements = []
        while self._peek() is not None:
            statements.append(self._parse_statement())
        return statements

    def _parse_statement(self) -> Statement:
        tok = self._peek()
        if not tok:
            raise SyntaxError("Empty statement.")
        
        _, val = tok
        if val == 'tensor':
            return self._parse_tensor_declaration()
        elif val == 'assert_contractive':
            return self._parse_contractivity_assertion()
        else:
            return self._parse_operator_application()

    def _parse_tensor_declaration(self) -> TensorDeclaration:
        self._consume('KEYWORD', 'tensor')
        _, ident = self._consume('IDENT')
        self._consume('OP', '[')
        
        primes = []
        while True:
            _, prime_val = self._consume('PRIME')
            primes.append(prime_val)
            next_tok = self._peek()
            if next_tok and next_tok[1] == ',':
                self._consume('OP', ',')
            else:
                break
                
        self._consume('OP', ']')
        self._consume('OP', ';')
        return TensorDeclaration(identifier=ident, primes=primes)

    def _parse_operator_application(self) -> OperatorApplication:
        _, ident = self._consume('IDENT')
        self._consume('OP', '|>')
        
        has_lambda = False
        if self._peek() and self._peek()[0] == 'LAMBDA':
            self._consume('LAMBDA')
            self._consume('OP', '*')
            has_lambda = True
            
        prime_chain = []
        while True:
            _, prime_val = self._consume('PRIME')
            prime_chain.append(prime_val)
            next_tok = self._peek()
            if next_tok and next_tok[1] == '*':
                self._consume('OP', '*')
            else:
                break
                
        self._consume('OP', ';')
        return OperatorApplication(identifier=ident, has_lambda=has_lambda, prime_chain=prime_chain)

    def _parse_contractivity_assertion(self) -> ContractivityAssertion:
        self._consume('KEYWORD', 'assert_contractive')
        self._consume('OP', '(')
        _, ident = self._consume('IDENT')
        self._consume('OP', ')')
        self._consume('OP', '<')
        _, float_val = self._consume('FLOAT')
        self._consume('OP', ';')
        return ContractivityAssertion(identifier=ident, bound=float(float_val))


def parse_pirtm(source_code: str) -> List[Statement]:
    """Convenience entry point for parsing PIRTM source strings."""
    return PIRTMDecoderParser(source_code).parse_source()
