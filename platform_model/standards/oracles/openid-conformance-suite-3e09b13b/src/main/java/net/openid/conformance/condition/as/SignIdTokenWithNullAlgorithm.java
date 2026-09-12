package net.openid.conformance.condition.as;

import net.openid.conformance.condition.PostEnvironment;
import net.openid.conformance.condition.PreEnvironment;
import net.openid.conformance.condition.common.AbstractSignClaimsWithNullAlgorithm;
import net.openid.conformance.testmodule.Environment;

public class SignIdTokenWithNullAlgorithm extends AbstractSignClaimsWithNullAlgorithm {

	@Override
	protected String getClaimsNotFoundErrorMsg() {
		return "ID Token claims not found";
	}

	@Override
	protected String getSuccessMsg() {
		return "Signed the id_token with null algorithm";
	}

	@Override
	@PreEnvironment(required = "id_token_claims" )
	@PostEnvironment(strings = "id_token")
	public Environment evaluate(Environment env) {
		return signWithNullAlgorithm(env, "id_token_claims", "id_token");
	}

}
