//! Public registered Prism diagnostics and structured underlying causes.

use std::fmt;

/// One code from the closed `prismpm/errors/1` diagnostic namespace.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub struct DiagnosticCode(String);

impl DiagnosticCode {
    const REGISTERED: [&'static str; 57] = [
        "PP1001", "PP1002", "PP1003", "PP2001", "PP2002", "PP2003", "PP2004", "PP2005", "PP2006",
        "PP2007", "PP2008", "PP3001", "PP3002", "PP3003", "PP3004", "PP3005", "PP3006", "PP3007",
        "PP3008", "PP3009", "PP3010", "PP3011", "PP3012", "PP3013", "PP3014", "PP3015", "PP4001",
        "PP4002", "PP4003", "PP4004", "PP4101", "PP4102", "PP4103", "PP4104", "PP4105", "PP5001",
        "PP5002", "PP5003", "PP5004", "PP5005", "PP5006", "PP5007", "PP5008", "PP5101", "PP5102",
        "PP5103", "PP5104", "PP5201", "PP5202", "PP5203", "PP5204", "PP5205", "PP5301", "PP6001",
        "PP6002", "PP6003", "PP6004",
    ];

    fn parse(value: &str) -> Option<Self> {
        (Self::REGISTERED.contains(&value) || matches!(value, "PP8001" | "PP8002" | "PP9001"))
            .then(|| Self(value.to_owned()))
    }

    /// The stable registered spelling.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl fmt::Display for DiagnosticCode {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.as_str())
    }
}

impl PartialEq<&str> for DiagnosticCode {
    fn eq(&self, other: &&str) -> bool {
        self.as_str() == *other
    }
}

impl serde::Serialize for DiagnosticCode {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(self.as_str())
    }
}

impl<'de> serde::Deserialize<'de> for DiagnosticCode {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let value = <String as serde::Deserialize>::deserialize(deserializer)?;
        Self::parse(&value).ok_or_else(|| serde::de::Error::custom("unregistered Prism code"))
    }
}

/// A canonical half-open UTF-8 source span.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(deny_unknown_fields)]
pub struct PrismSpan {
    /// Project-relative source path.
    pub path: String,
    /// Zero-based first byte.
    pub byte_start: usize,
    /// Zero-based exclusive final byte.
    pub byte_end: usize,
    /// One-based first line.
    pub line_start: usize,
    /// One-based first Unicode-scalar column.
    pub column_start: usize,
    /// One-based final line.
    pub line_end: usize,
    /// One-based exclusive final Unicode-scalar column.
    pub column_end: usize,
}

/// A secondary labeled source span.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(deny_unknown_fields)]
pub struct PrismLabel {
    /// Meaning of the secondary span.
    pub message: String,
    /// Secondary source location.
    pub span: PrismSpan,
}

/// A diagnostic note with an optional source location.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(deny_unknown_fields)]
pub struct PrismNote {
    /// Stable note text.
    pub message: String,
    /// Optional related source location.
    pub span: Option<PrismSpan>,
}

/// A structured underlying diagnostic retained across a subsystem boundary.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(deny_unknown_fields)]
pub struct PrismCause {
    /// Producing subsystem.
    pub subsystem: String,
    /// Subsystem diagnostic code.
    pub code: String,
    /// Stable diagnostic message.
    pub message: String,
    /// Primary source location from the producing subsystem.
    pub primary: Option<PrismSpan>,
    /// Canonically ordered secondary labels.
    pub labels: Vec<PrismLabel>,
    /// Canonically ordered diagnostic notes.
    pub notes: Vec<PrismNote>,
    /// Canonically ordered fix-it help lines.
    pub help: Vec<String>,
}

/// Public Prism operation failure.
#[derive(Debug, Clone, PartialEq, Eq, serde::Serialize, serde::Deserialize)]
#[serde(deny_unknown_fields)]
pub struct PrismError {
    /// Registered PP diagnostic code.
    pub code: DiagnosticCode,
    /// Stable primary message.
    pub message: String,
    /// Primary source location, when the Prism phase has one.
    pub primary: Option<PrismSpan>,
    /// Canonically ordered secondary labels.
    pub labels: Vec<PrismLabel>,
    /// Canonically ordered diagnostic notes.
    pub notes: Vec<PrismNote>,
    /// Canonically ordered fix-it help lines.
    pub help: Vec<String>,
    /// Structured causes, never debug strings.
    pub causes: Vec<PrismCause>,
}

impl PrismError {
    /// Stable process exit class for this registered diagnostic.
    #[must_use]
    pub fn exit_code(&self) -> u8 {
        if self.code.as_str().starts_with("PP100") {
            2
        } else if self.code == "PP9001" {
            101
        } else {
            1
        }
    }
}

impl PrismError {
    /// Construct a registered Prism failure.
    #[must_use]
    pub fn new(code: &'static str, message: impl Into<String>) -> Self {
        let (code, invalid) = match DiagnosticCode::parse(code) {
            Some(code) => (code, None),
            None => (
                DiagnosticCode::parse("PP9001").expect("internal code is registered"),
                Some(code),
            ),
        };
        let mut notes = Vec::new();
        if let Some(invalid) = invalid {
            notes.push(PrismNote {
                message: format!("an unregistered internal diagnostic `{invalid}` was rejected"),
                span: None,
            });
        }
        Self {
            code,
            message: message.into(),
            primary: None,
            labels: Vec::new(),
            notes,
            help: Vec::new(),
            causes: Vec::new(),
        }
    }

    /// Attach one stable note.
    #[must_use]
    pub fn with_note(mut self, note: impl Into<String>) -> Self {
        self.notes.push(PrismNote {
            message: note.into(),
            span: None,
        });
        self
    }

    /// Convert a LexLean failure while preserving structured diagnostics up to
    /// the configured public diagnostic limit.
    #[must_use]
    pub(crate) fn from_lexlean(
        code: &'static str,
        context: &str,
        error: lexlean::LexLeanError,
        limit: u64,
    ) -> Self {
        let total = error.diagnostics.len();
        let limit = usize::try_from(limit).unwrap_or(usize::MAX);
        let causes = error
            .diagnostics
            .into_iter()
            .take(limit)
            .map(|diagnostic| {
                let span = |span: lexlean::diagnostic::Span| PrismSpan {
                    path: span.path,
                    byte_start: span.byte_start,
                    byte_end: span.byte_end,
                    line_start: span.line_start,
                    column_start: span.column_start,
                    line_end: span.line_end,
                    column_end: span.column_end,
                };
                PrismCause {
                    subsystem: "lexlean".to_owned(),
                    code: diagnostic.code.as_str().to_owned(),
                    message: diagnostic.message,
                    primary: diagnostic.primary.map(&span),
                    labels: diagnostic
                        .labels
                        .into_iter()
                        .map(|label| PrismLabel {
                            message: label.message,
                            span: span(label.span),
                        })
                        .collect(),
                    notes: diagnostic
                        .notes
                        .into_iter()
                        .map(|note| PrismNote {
                            message: note.message,
                            span: note.span.map(&span),
                        })
                        .collect(),
                    help: diagnostic.help,
                }
            })
            .collect();
        let mut result = Self {
            code: DiagnosticCode::parse(code).unwrap_or_else(|| {
                DiagnosticCode::parse("PP9001").expect("internal code is registered")
            }),
            message: context.to_owned(),
            primary: None,
            labels: Vec::new(),
            notes: Vec::new(),
            help: Vec::new(),
            causes,
        };
        if total > limit {
            result.notes.push(PrismNote {
                message: format!(
                    "{} additional LexLean diagnostics were omitted",
                    total - limit
                ),
                span: None,
            });
        }
        result
    }
}

impl fmt::Display for PrismError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{}: {}", self.code, self.message)
    }
}

impl std::error::Error for PrismError {}
