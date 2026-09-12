//! Total projection from the stable LexLean semantic snapshot.

use super::model_document::{
    ActivityRecord, ArchitectureModel, AssetRecord, CatalogRecord, ComponentRecord, ControlRecord,
    EdgeRecord, FacetPackage, IndexedRecord, MeasureRecord, MeasurementRecord, ModelDocument,
    ProjectionProvenance, QualityModel, RequirementRecord, RiskRecord, SecurityModel,
    SubcharacteristicRecord, ViewRecord, ViewpointRecord,
};
use crate::error::PrismError;
use lexlean::SemanticSnapshot;
use serde::Deserialize;
use serde_json::Value;
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};

const TABLE_SOURCE: &str = include_str!("../../model/projection.toml");
const PROFILE: [&str; 5] = [
    "ISO-25010-2023",
    "ISO-27005-2022",
    "ISO-27034-1-2011",
    "ISO-27034-5-2017",
    "ISO-42010-2022",
];

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct Table {
    spec: String,
    catalog: Vec<CatalogMap>,
    entity: Vec<EntityMap>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct CatalogMap {
    module: String,
    declaration: String,
    facet: String,
    target: String,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct EntityMap {
    module: String,
    type_name: String,
    target: String,
}

struct Raw<'a> {
    id: String,
    fields: BTreeMap<&'a str, &'a Value>,
}

fn table() -> Result<Table, PrismError> {
    let value: Table = toml::from_str(TABLE_SOURCE)
        .map_err(|error| PrismError::new("PP9001", format!("projection table: {error}")))?;
    if value.spec != "prismpm/projection/1" {
        return Err(PrismError::new("PP9001", "wrong projection schema"));
    }
    let mut keys = BTreeSet::new();
    for row in &value.catalog {
        if !keys.insert(format!("c:{}::{}", row.module, row.declaration)) {
            return Err(PrismError::new("PP9001", "duplicate catalog projection"));
        }
    }
    for row in &value.entity {
        if !keys.insert(format!("e:{}::{}", row.module, row.type_name)) {
            return Err(PrismError::new("PP9001", "duplicate entity projection"));
        }
    }
    Ok(value)
}

fn facets(snapshot: &SemanticSnapshot) -> Result<Vec<FacetPackage>, PrismError> {
    let packages = snapshot
        .lexicon_closure()
        .get("packages")
        .and_then(Value::as_array)
        .ok_or_else(|| PrismError::new("PP4004", "malformed package closure"))?;
    let mut out = Vec::new();
    for package in packages {
        let id = package
            .get("id")
            .and_then(Value::as_str)
            .unwrap_or_default();
        if id.starts_with("prism.") {
            out.push(FacetPackage {
                package: id.to_owned(),
                version: package
                    .get("version")
                    .and_then(Value::as_str)
                    .ok_or_else(|| PrismError::new("PP4004", "missing facet version"))?
                    .to_owned(),
                content_id: package
                    .get("tree_sha256")
                    .and_then(Value::as_str)
                    .ok_or_else(|| PrismError::new("PP4004", "missing facet digest"))?
                    .to_owned(),
            });
        }
    }
    out.sort_by(|a, b| a.package.as_bytes().cmp(b.package.as_bytes()));
    if out
        .iter()
        .map(|row| row.package.as_str())
        .collect::<Vec<_>>()
        != ["prism.arch", "prism.qual", "prism.sec"]
    {
        return Err(PrismError::new("PP2001", "facet closure is not exact"));
    }
    Ok(out)
}

fn result_type(value: &Value) -> Option<(&str, Option<&str>)> {
    let member = value.get("result")?.get("member")?;
    Some((
        member.get("name")?.as_str()?,
        member.get("module").and_then(Value::as_str),
    ))
}

fn fields(value: &Value) -> Option<BTreeMap<&str, &Value>> {
    let body = value.get("body")?;
    if body.get("kind")?.as_str()? != "record" {
        return None;
    }
    let mut out = BTreeMap::new();
    for row in body.get("fields")?.as_array()? {
        if out
            .insert(row.get("field")?.as_str()?, row.get("value")?)
            .is_some()
        {
            return None;
        }
    }
    Some(out)
}

fn nat(fields: &BTreeMap<&str, &Value>, name: &str) -> Result<u64, PrismError> {
    let value = fields
        .get(name)
        .ok_or_else(|| PrismError::new("PP2001", format!("missing field {name}")))?;
    if value.get("kind").and_then(Value::as_str) != Some("nat") {
        return Err(PrismError::new(
            "PP2001",
            format!("field {name} is not Nat"),
        ));
    }
    let text = value
        .get("value")
        .and_then(Value::as_str)
        .ok_or_else(|| PrismError::new("PP2001", format!("field {name} is malformed")))?;
    if text != "0" && (text.starts_with('0') || !text.bytes().all(|byte| byte.is_ascii_digit())) {
        return Err(PrismError::new("PP4004", "noncanonical natural number"));
    }
    text.parse()
        .map_err(|_| PrismError::new("PP4004", format!("field {name} exceeds u64")))
}

fn bool_field(fields: &BTreeMap<&str, &Value>, name: &str) -> Result<bool, PrismError> {
    let value = fields
        .get(name)
        .ok_or_else(|| PrismError::new("PP2001", format!("missing field {name}")))?;
    if value.get("kind").and_then(Value::as_str) != Some("bool") {
        return Err(PrismError::new(
            "PP2001",
            format!("field {name} is not Bool"),
        ));
    }
    value
        .get("value")
        .and_then(Value::as_bool)
        .ok_or_else(|| PrismError::new("PP2001", format!("field {name} is malformed")))
}

fn constructor<'a>(fields: &'a BTreeMap<&str, &Value>, name: &str) -> Result<&'a str, PrismError> {
    fields
        .get(name)
        .filter(|value| value.get("kind").and_then(Value::as_str) == Some("constructor"))
        .and_then(|value| value.get("constructor"))
        .and_then(|value| value.get("name"))
        .and_then(Value::as_str)
        .ok_or_else(|| PrismError::new("PP2001", format!("field {name} is not a constructor")))
}

fn catalog_id(table: &Table, module: &str, constructor: &str) -> Result<String, PrismError> {
    let owner = constructor
        .split_once('.')
        .map(|pair| pair.0)
        .ok_or_else(|| PrismError::new("PP2001", "unqualified catalog value"))?;
    let row = table
        .catalog
        .iter()
        .find(|row| row.module == module && row.declaration == owner)
        .ok_or_else(|| PrismError::new("PP2001", format!("unmapped catalog {constructor}")))?;
    Ok(format!("{}::{constructor}", row.facet))
}

fn index(rows: &mut [Raw<'_>]) -> Result<(), PrismError> {
    rows.sort_by(|a, b| a.id.as_bytes().cmp(b.id.as_bytes()));
    for (expected, row) in rows.iter().enumerate() {
        let expected = u64::try_from(expected)
            .map_err(|_| PrismError::new("PP4004", "entity count exceeds u64"))?;
        if nat(&row.fields, "index")? != expected {
            return Err(PrismError::new(
                "PP4004",
                format!("{} must have canonical index {expected}", row.id),
            ));
        }
    }
    Ok(())
}

fn indexed(rows: Vec<Raw<'_>>) -> Vec<IndexedRecord> {
    rows.into_iter()
        .enumerate()
        .map(|(index, row)| IndexedRecord {
            id: row.id,
            index: index as u64,
        })
        .collect()
}

/// Validate the stable snapshot envelope before semantic projection.
pub fn validate_snapshot_envelope(bytes: &[u8]) -> Result<(), PrismError> {
    let value: Value = serde_json::from_slice(bytes)
        .map_err(|error| PrismError::new("PP4004", format!("semantic snapshot: {error}")))?;
    if value.get("spec").and_then(Value::as_str) != Some("lexlean/semantic-snapshot/1")
        || value.get("language").and_then(Value::as_str) != Some("1.1")
        || !value.get("modules").is_some_and(Value::is_array)
    {
        return Err(PrismError::new("PP4004", "unsupported semantic snapshot"));
    }
    Ok(())
}

fn take_raw<'a>(map: &mut BTreeMap<String, Vec<Raw<'a>>>, name: &str) -> Vec<Raw<'a>> {
    map.remove(name).unwrap_or_default()
}

/// Project one checked LexLean snapshot without filesystem writes or child processes.
pub fn project_snapshot(snapshot: &SemanticSnapshot) -> Result<ModelDocument, PrismError> {
    if snapshot.spec() != "lexlean/semantic-snapshot/1" || snapshot.language() != "1.1" {
        return Err(PrismError::new("PP4004", "unsupported semantic snapshot"));
    }
    let table = table()?;
    let mut catalogs: BTreeMap<String, Vec<CatalogRecord>> = BTreeMap::new();
    let mut entities: BTreeMap<String, Vec<Raw<'_>>> = BTreeMap::new();
    for module in snapshot.modules() {
        for declaration in module.declarations() {
            let linked = declaration.linked_ir();
            if declaration.kind() == "inductive" {
                if let Some(mapping) = table.catalog.iter().find(|row| {
                    row.module == module.name() && row.declaration == declaration.logical_id()
                }) {
                    let constructors = linked
                        .get("constructors")
                        .and_then(Value::as_array)
                        .ok_or_else(|| PrismError::new("PP4004", "missing constructors"))?;
                    for constructor in constructors {
                        let name = constructor
                            .get("name")
                            .and_then(Value::as_str)
                            .ok_or_else(|| PrismError::new("PP4004", "missing constructor name"))?;
                        catalogs
                            .entry(mapping.target.clone())
                            .or_default()
                            .push(CatalogRecord {
                                id: format!("{}::{}.{}", mapping.facet, mapping.declaration, name),
                                index: 0,
                            });
                    }
                }
                continue;
            }
            if declaration.kind() != "definition" {
                continue;
            }
            let Some((type_name, None)) = result_type(linked) else {
                continue;
            };
            let Some(mapping) = table
                .entity
                .iter()
                .find(|row| row.module == module.name() && row.type_name == type_name)
            else {
                continue;
            };
            entities
                .entry(mapping.target.clone())
                .or_default()
                .push(Raw {
                    id: format!("{}::{}", module.name(), declaration.logical_id()),
                    fields: fields(linked).ok_or_else(|| {
                        PrismError::new("PP2001", "mapped entity is not a record definition")
                    })?,
                });
        }
    }
    for rows in catalogs.values_mut() {
        rows.sort_by(|a, b| a.id.as_bytes().cmp(b.id.as_bytes()));
        for (index, row) in rows.iter_mut().enumerate() {
            row.index = index as u64;
        }
    }
    for rows in entities.values_mut() {
        index(rows)?;
    }
    let take_catalog = |map: &mut BTreeMap<String, Vec<CatalogRecord>>, name: &str| {
        map.remove(name).unwrap_or_default()
    };
    let component_rows = take_raw(&mut entities, "components");
    let components = component_rows
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(ComponentRecord {
                id: row.id,
                index: index as u64,
                kind_id: catalog_id(&table, "Foundation.Arch", constructor(&row.fields, "kind")?)?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let edge_rows = take_raw(&mut entities, "edges");
    let edges = edge_rows
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(EdgeRecord {
                id: row.id,
                index: index as u64,
                from_index: nat(&row.fields, "fromIndex")?,
                to_index: nat(&row.fields, "toIndex")?,
                kind_id: catalog_id(&table, "Foundation.Arch", constructor(&row.fields, "kind")?)?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let stakeholders = indexed(take_raw(&mut entities, "stakeholders"));
    let concerns = indexed(take_raw(&mut entities, "concerns"));
    let viewpoints = take_raw(&mut entities, "viewpoints")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(ViewpointRecord {
                id: row.id,
                index: index as u64,
                stakeholder_index: nat(&row.fields, "stakeholderIndex")?,
                concern_index: nat(&row.fields, "concernIndex")?,
                model_kind_index: nat(&row.fields, "modelKindIndex")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let views = take_raw(&mut entities, "views")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(ViewRecord {
                id: row.id,
                index: index as u64,
                viewpoint_index: nat(&row.fields, "viewpointIndex")?,
                model_kind_index: nat(&row.fields, "modelKindIndex")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let assets = take_raw(&mut entities, "assets")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(AssetRecord {
                id: row.id,
                index: index as u64,
                component_index: nat(&row.fields, "componentIndex")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let threats = indexed(take_raw(&mut entities, "threats"));
    let risks = take_raw(&mut entities, "risks")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(RiskRecord {
                id: row.id,
                index: index as u64,
                asset_index: nat(&row.fields, "assetIndex")?,
                threat_index: nat(&row.fields, "threatIndex")?,
                likelihood_id: catalog_id(
                    &table,
                    "Foundation.Sec",
                    constructor(&row.fields, "likelihood")?,
                )?,
                impact_id: catalog_id(
                    &table,
                    "Foundation.Sec",
                    constructor(&row.fields, "impact")?,
                )?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let controls = take_raw(&mut entities, "controls")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(ControlRecord {
                id: row.id,
                index: index as u64,
                risk_index: nat(&row.fields, "riskIndex")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let activities = take_raw(&mut entities, "activities")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(ActivityRecord {
                id: row.id,
                index: index as u64,
                control_index: nat(&row.fields, "controlIndex")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let measurements = take_raw(&mut entities, "measurements")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(MeasurementRecord {
                id: row.id,
                index: index as u64,
                control_index: nat(&row.fields, "controlIndex")?,
                passed: bool_field(&row.fields, "passed")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let characteristics = indexed(take_raw(&mut entities, "characteristics"));
    let subcharacteristics = take_raw(&mut entities, "subcharacteristics")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(SubcharacteristicRecord {
                id: row.id,
                index: index as u64,
                characteristic_index: nat(&row.fields, "characteristicIndex")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let requirements = take_raw(&mut entities, "requirements")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(RequirementRecord {
                id: row.id,
                index: index as u64,
                subcharacteristic_index: nat(&row.fields, "subcharacteristicIndex")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    let measures = take_raw(&mut entities, "measures")
        .into_iter()
        .enumerate()
        .map(|(index, row)| {
            Ok(MeasureRecord {
                id: row.id,
                index: index as u64,
                requirement_index: nat(&row.fields, "requirementIndex")?,
                threshold: nat(&row.fields, "threshold")?,
            })
        })
        .collect::<Result<Vec<_>, PrismError>>()?;
    if !entities.is_empty() {
        return Err(PrismError::new("PP9001", "unconsumed entity projection"));
    }

    let doc = ModelDocument {
        schema: "prismpm/model-document/1".to_owned(),
        provenance: ProjectionProvenance {
            source_id: snapshot.source_id().to_string(),
            semantic_id: snapshot.semantic_id().to_string(),
            compiler_semantics_id: snapshot.compiler_semantics_id().to_string(),
            snapshot_id: snapshot.snapshot_id().to_string(),
            emitter_semantics_id: compute_emitter_semantics_id(),
            facet_packages: facets(snapshot)?,
        },
        standards_profile: PROFILE.iter().map(|value| (*value).to_owned()).collect(),
        architecture: ArchitectureModel {
            component_kinds: take_catalog(&mut catalogs, "component_kinds"),
            edge_kinds: take_catalog(&mut catalogs, "edge_kinds"),
            model_kinds: take_catalog(&mut catalogs, "model_kinds"),
            components,
            edges,
            stakeholders,
            concerns,
            viewpoints,
            views,
        },
        security: SecurityModel {
            likelihoods: take_catalog(&mut catalogs, "likelihoods"),
            impacts: take_catalog(&mut catalogs, "impacts"),
            assets,
            threats,
            risks,
            controls,
            activities,
            measurements,
        },
        quality: QualityModel {
            characteristics,
            subcharacteristics,
            requirements,
            measures,
        },
        application: None,
    };
    if !catalogs.is_empty() {
        return Err(PrismError::new("PP9001", "unconsumed catalog projection"));
    }
    super::validate::validate(&doc)?;
    Ok(doc)
}

/// Compute the canonical tree digest of the exact declared emitter inputs.
#[must_use]
pub fn compute_emitter_semantics_id() -> String {
    const INPUTS: [(&str, &[u8]); 8] = [
        (
            "crates/prismpm/src/holo/canonical.rs",
            include_bytes!("canonical.rs"),
        ),
        (
            "crates/prismpm/src/holo/model_document.rs",
            include_bytes!("model_document.rs"),
        ),
        ("crates/prismpm/src/holo/mod.rs", include_bytes!("mod.rs")),
        (
            "crates/prismpm/src/holo/projector.rs",
            include_bytes!("projector.rs"),
        ),
        (
            "crates/prismpm/src/holo/validate.rs",
            include_bytes!("validate.rs"),
        ),
        (
            "model/projection.toml",
            include_bytes!("../../model/projection.toml"),
        ),
        (
            "model/standards.toml",
            include_bytes!("../../model/standards.toml"),
        ),
        (
            "schemas/model-document.schema.json",
            include_bytes!("../../schemas/model-document.schema.json"),
        ),
    ];
    let mut hasher = Sha256::new();
    for (path, bytes) in INPUTS {
        hasher.update((path.len() as u64).to_be_bytes());
        hasher.update(path.as_bytes());
        hasher.update((bytes.len() as u64).to_be_bytes());
        hasher.update(bytes);
    }
    format!("{:x}", hasher.finalize())
}
