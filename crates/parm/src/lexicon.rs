use serde::{Deserialize, Serialize};
use quick_xml::de::from_str;

#[derive(Debug, Serialize, Deserialize)]
#[serde(rename = "lexicon")]
pub struct Lexicon {
    #[serde(rename = "part", default)]
    pub parts: Vec<Part>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Part {
    #[serde(rename = "@id")]
    pub id: String,
    #[serde(rename = "@title")]
    pub title: String,
    #[serde(rename = "section", default)]
    pub sections: Vec<Section>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Section {
    #[serde(rename = "@id")]
    pub id: String,
    #[serde(rename = "entry", default)]
    pub entries: Vec<Entry>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Entry {
    #[serde(rename = "@id")]
    pub id: String,
    #[serde(rename = "@type", default)]
    pub entry_type: Option<String>,
    #[serde(rename = "w", default)]
    pub word: Option<String>,
    #[serde(rename = "def", default)]
    pub definition: Option<String>,
}

pub fn parse_lexicon(xml: &str) -> Result<Lexicon, quick_xml::de::DeError> {
    from_str(xml)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_simple() {
        let xml = r#"
        <lexicon>
            <part id="a" title="א">
                <section id="a.aa">
                    <entry id="a.aa.aa" type="root">
                        <w>א</w>
                        <def>Āleph</def>
                    </entry>
                </section>
            </part>
        </lexicon>
        "#;

        let lexicon: Lexicon = from_str(xml).unwrap();
        assert_eq!(lexicon.parts.len(), 1);
        assert_eq!(lexicon.parts[0].sections[0].entries[0].word.as_ref().unwrap(), "א");
    }
}
