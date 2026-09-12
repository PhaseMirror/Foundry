package net.openid.conformance.condition.client;

import net.openid.conformance.condition.PreEnvironment;
import net.openid.conformance.testmodule.Environment;

public class ValidateErrorDescriptionFromTokenEndpointResponseError extends AbstractValidateErrorDescriptionFromResponseError {

	@Override
	@PreEnvironment(required = "token_endpoint_response")
	public Environment evaluate(Environment env) {
		return validateErrorDescription(env, "token_endpoint_response");
	}

}
