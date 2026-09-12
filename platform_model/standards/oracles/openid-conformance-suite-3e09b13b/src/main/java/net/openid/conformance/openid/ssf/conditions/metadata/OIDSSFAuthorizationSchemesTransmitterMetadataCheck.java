package net.openid.conformance.openid.ssf.conditions.metadata;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import net.openid.conformance.condition.AbstractCondition;
import net.openid.conformance.condition.PreEnvironment;
import net.openid.conformance.testmodule.Environment;
import net.openid.conformance.testmodule.OIDFJSON;

public class OIDSSFAuthorizationSchemesTransmitterMetadataCheck extends AbstractCondition {

	@Override
	@PreEnvironment(required = {"ssf"})
	public Environment evaluate(Environment env) {

		JsonObject transmitterMetadata = env.getElementFromObject("ssf","transmitter_metadata").getAsJsonObject();

		// OIDSSF-7.1.1
		JsonArray authorizationSchemes = transmitterMetadata.getAsJsonArray("authorization_schemes");

		if (authorizationSchemes == null || authorizationSchemes.isEmpty()) {
			log("Found no authorization_schemes in transmitter metadata");
			return env;
		}

		for (var element : authorizationSchemes) {
			JsonElement specUrnEl = element.getAsJsonObject().get("spec_urn");
			if (specUrnEl == null) {
				throw error("Missing required field spec_urn for authorization_schemes element!");
			}
			String specUrn = OIDFJSON.getString(specUrnEl);

			if (!specUrn.startsWith("urn:")) {
				throw error("Found invalid spec_urn for authorization_schemes element! spec_url value must start with 'urn:'", args("spec_urn", specUrn));
			}
		}

		log("Found authorization_schemes in transmitter metadata", args("authorization_schemes", authorizationSchemes));

		return env;
	}
}
