package io.swagger.client;

import io.swagger.client.auth.Authentication;
import io.swagger.client.auth.OAuth;
import org.glassfish.jersey.client.oauth1.AccessToken;
import org.glassfish.jersey.client.oauth1.ConsumerCredentials;
import org.glassfish.jersey.client.oauth1.OAuth1AuthorizationFlow;
import org.glassfish.jersey.client.oauth1.OAuth1ClientSupport;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.Feature;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.Charset;

public class CleverApiClient extends ApiClient {

    private Client client = ClientBuilder.newBuilder().build();
    private ConsumerCredentials consumerCredentials;
    private String consumerKey;
    private String consumerSecret;
    private String token;
    private String tokenSecret;
    private final BufferedReader IN = new BufferedReader(new InputStreamReader(System.in, Charset.forName("UTF-8")));

    public CleverApiClient(String consumerKey, String consumerSecret, String token, String tokenSecret) {
        this.consumerKey = consumerKey;
        this.consumerSecret = consumerSecret;
        this.token = token;
        this.tokenSecret = tokenSecret;

        consumerCredentials = new ConsumerCredentials(consumerKey, consumerSecret);
        AccessToken storedToken = new AccessToken(token, tokenSecret);
        Feature filterFeature = OAuth1ClientSupport.builder(consumerCredentials)
                .feature()
                .accessToken(storedToken)
                .build();
        client.register(filterFeature);
        this.setHttpClient(client);
    }

    public CleverApiClient(String consumerKey, String consumerSecret) {
        consumerCredentials = new ConsumerCredentials(consumerKey, consumerSecret);
        ConsumerCredentials consumerCredentials = new ConsumerCredentials(consumerKey, consumerSecret);

        final OAuth1AuthorizationFlow authFlow = OAuth1ClientSupport.builder(consumerCredentials)
                .authorizationFlow(
                        "https://api.clever-cloud.com/v2/oauth/request_token_query",
                        "https://api.clever-cloud.com/v2/oauth/access_token_query",
                        "https://api.clever-cloud.com/v2/oauth/authorize")
                .client(client)
                .callbackUri("http://artifactory-addon-provider.cleverapps.io/").build();

        final String authorizationUri = authFlow.start();
        System.out.println("We will give you the token and token secret. Enter the following URI into a web browser and authorize me:");
        System.out.println(authorizationUri);
        System.out.print("Enter the oauth (you can get it from the URL): ");
        String in = null;
        try {
            in = IN.readLine();
        } catch (Exception e) {}
        AccessToken accessToken = authFlow.finish(in);
        System.out.println("Your token : " + accessToken.getToken() + "\nYour token secret : " + accessToken.getAccessTokenSecret());

        OAuth OAuthSecurity = (OAuth) this.getAuthentication("OAuthSecurity");
        OAuthSecurity.setAccessToken(accessToken);
        this.setHttpClient(client);
    }

    public String getConsumerKey() { return this.consumerKey; }

    public String getConsumerSecret() { return this.consumerSecret; }

    public String getToken() { return this.token; }

    public String getTokenSecret() { return this.tokenSecret; }
}
