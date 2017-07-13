
exports.prototype.getOAuthParams = function(auth) {
    return {
	oauth_consumer_key: auth.consumerKey,
	oauth_signature_method: "PLAINTEXT",
	oauth_signature: auth.consumerSecret + "&" + (auth.token_secret || ""),
	oauth_timestamp: Math.floor(Date.now()/1000),
	oauth_nonce: Math.floor(Math.random()*1000000)
    };
};

exports.prototype.getHMACAuthorization = function(httpMethod, url, queryparams, auth) {
    var _ = require('lodash');
    var oauthSignature = require("oauth-sign");
    var crypto = require('crypto');

    if(auth.token && auth.tokenSecret) {
	var params = _.extend({}, queryparams, exports.prototype.getOAuthParams(auth), {
	    oauth_signature_method: "HMAC-SHA512",
	    oauth_token: auth.token
	});

	var signature = exports.prototype.signHmacSHA512(httpMethod, url, _.omit(params, "oauth_signature"), auth);

	return  ["OAuth realm=\"" + "https://api.clever-cloud.com/v2" + "/oauth\"",
		 "oauth_consumer_key=\"" + auth.consumerKey + "\"",
		 "oauth_token=\"" + params.oauth_token + "\"",
		 "oauth_signature_method=\"" + params.oauth_signature_method + "\"",
		 "oauth_signature=\"" + signature + "\"",
		 "oauth_timestamp=\"" + params.oauth_timestamp + "\"",
		 "oauth_nonce=\"" + params.oauth_nonce + "\""].join(", ");
    }
    else {
	return "";
    }
};

exports.prototype.signHmacSHA512 = function(httpMethod, url, params, tokens){
    var _ = require('lodash');
    var oauthSignature = require("oauth-sign");
    var crypto = require('crypto');

    var key = [
	tokens.consumerSecret,
	tokens.tokenSecret
    ].map(oauthSignature.rfc3986).join('&');
    var base = oauthSignature.generateBase(httpMethod, url, params);

    return crypto.createHmac("sha512", key).update(base).digest('base64');
};
return exports;
}));
