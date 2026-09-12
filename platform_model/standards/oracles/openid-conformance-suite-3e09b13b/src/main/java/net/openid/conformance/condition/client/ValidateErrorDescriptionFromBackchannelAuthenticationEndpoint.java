package net.openid.conformance.condition.client;

import net.openid.conformance.condition.PreEnvironment;
import net.openid.conformance.testmodule.Environment;

public class ValidateErrorDescriptionFromBackchannelAuthenticationEndpoint extends AbstractValidateErrorDescriptionFromResponseError {

	@Override
	@PreEnvironment(required = "backchannel_authentication_endpoint_response")
	public Environment evaluate(Environment env) {
		return validateErrorDescription(env, "backchannel_authentication_endpoint_response");
	}
}
