Title: Implementing Windows Azure ACS with everyauth
Author: Dario Renzulli
Date: Wed Jan 20 2012 12:00:00 GMT-0300
Node: v0.6.6

In this article we will walk you through the implementation of the Windows Azure ACS module for [everyauth](https://github.com/bnoguchi/everyauth).

## Adding Windows Azure ACS module to everyauth

We forked [everyauth](https://github.com/bnoguchi/everyauth) git repo. Then, created a new module, called `azureacs`, following the design guidelines suggested by [Brian Noguchi](https://github.com/bnoguchi). We did a quick and dirty implementation just to see if the whole flow would work. Once we had it working, we refactored it and created two independent modules: [node-wsfederation](https://github.com/darrenzully/node-wsfederation) and [node-swt](https://github.com/darrenzully/node-swt).

### The token format: parsing and validating SimpleWebTokens with node-swt

SimpleWebTokens are really simple :). Windows Azure ACS can issue SimpleWebTokens as well as SAML 1.1 or 2.0 tokens. We decided to implement SWT because it is a very simple format and it's based on HMAC256 signatures which are ubiquous in every platform. 

The key method, where we validate the token is this one:

      isValid: function(rawToken, audienceUri, swtSigningKey) {
        var chunks = rawToken.split(hmacSHA256);
        if(chunks.length < 2)
          return false;
      
        if(this.isExpired())
          return false;
    
         if(this.audience !== audienceUri)
            return false;
    
        var hash = crypto.createHmac('RSA-SHA256', new Buffer(swtSigningKey, 'base64').toString('binary')).update(new Buffer(chunks[0], 'utf8')).digest('base64');
    
        return (hash === decodeURIComponent(chunks[1]));
      }

The logic basically checks

1. There is an HMAC hash
2. The token has not expired
3. The audience uri (the target application for this token) matches with the one in the configuration
4. Finaly calculates the HMAC based on the signing key set on the configuration and compare it with the one in the token

### The protocol: implementing the basic ws-federation protocol with node-wsfederation

Ws-Federation is a very simple protocol. It expects an HTTP GET against the identity provider endpoint and it will produce an HTTP POST against the application with an envelope that contains the token (swt, saml, custom, etc.).

These are the key methods:

      getRequestSecurityTokenUrl: function () {
        if (this.homerealm !== '') {
          return this.identityProviderUrl + "?wtrealm=" + this.realm + "&wa=wsignin1.0&whr=" + this.homerealm;   
        }
        else {
          return this.identityProviderUrl + "?wtrealm=" + this.realm + "&wa=wsignin1.0";
        } 
      },

      extractToken: function(res) {
        var promise = {};
        var parser = new xml2js.Parser();
        parser.on('end', function(result) {
          promise = result['t:RequestedSecurityToken'];
        });

        parser.parseString(res.req.body['wresult']);
        return promise;
      }

The `getRequestSecurityTokenUrl` will build the url that will be used for the redirect folowing the protocol (`wtrealm` to specify the application, `wa` to specify that this is a sign in and optionally `whr` to specify the identity provider, if there are more than one possible)

The `extractToken` will simply parse the response and extract from the XML the `RequestedSecurityToken` element. Inside that element we will find the token.

### The glue: putting it all together in everyauth

[everyauth](https://github.com/bnoguchi/everyauth) uses an interesting model for defining the whole sequenece of steps so that you don't have to nest callbacks inside callbacks. Basically you define the flow like this, and then create each function that will be called.

      .get('entryPath', 
         'the link a user follows, whereupon you redirect them to ACS url- e.g., "/auth/facebook"')          
        .step('redirectToIdentityProviderSelector')
          .accepts('req res')
          .promises(null)
      
      .post('callbackPath',
           'the callback path that the ACS redirects to after an authorization result - e.g., "/auth/facscallback"')
        .step('getToken')
          .description('retrieves a verifier code from the url query')
          .accepts('req res')
          .promises('token')
          .canBreakTo('notValidTokenCallbackErrorSteps')
          .canBreakTo('authCallbackErrorSteps')
        .step('parseToken')
          .description('retrieves a verifier code from the url query')
          .accepts('req res token')
          .promises('claims')
          .canBreakTo('notValidTokenCallbackErrorSteps')
        .step('fetchUser')
          .accepts('claims')
          .promises('acsUser')
        .step('getSession')
          .accepts('req')
          .promises('session')      
        .step('findOrCreateUser')
          .accepts('session acsUser')
          .promises('user')
        .step('addToSession')
          .accepts('session acsUser token')
          .promises(null)
        .step('sendResponse')
          .accepts('res')
          .promises(null)

Here are the most important steps

      .redirectToIdentityProviderSelector( function (req, res) {
        var identityProviderSelectorUri = this.wsfederation.getRequestSecurityTokenUrl();
        
        res.writeHead(303, {'Location': identityProviderSelectorUri});
        res.end();
      })
    
      .getToken( function (req, res) {
        var token = this.wsfederation.extractToken(res);
    
        if (this.tokenFormat() === 'swt') {
          var str = token['wsse:BinarySecurityToken']['#'];
          var result = new Buffer(str, 'base64').toString('ascii'); 
        }
        else {
          return this.breakTo('protocolNotImplementedErrorSteps', this.tokenFormat());
        }
    
        if (this._authCallbackDidErr(req)) {
          return this.breakTo('authCallbackErrorSteps', req, res);
        }
    
        return result;
      })
    
      .parseToken( function (req, res, token) {
        if (this.tokenFormat() === 'swt') {
          var swt = new Swt(token);
          if (!swt.isValid(token, this.realm(), this.signingKey())) {
            return this.breakTo('notValidTokenCallbackErrorSteps', token);
          }
          return swt.claims;
        }
    
        return this.breakTo('protocolNotImplementedErrorSteps', this.tokenFormat());
      })

## Conclusion

Integrating with everyauth was simple once we understood how it works. Anyway, we created two reusable modules [node-swt](https://github.com/darrenzully/node-swt) and [node-wsfederation](https://github.com/darrenzully/node-wsfederation) that can be used to implement support for [connect-auth](https://github.com/ciaranj/connect-auth) or [passport](https://github.com/jaredhanson/passport). By using the `azureacs` module you will be able to provide single sign on for multiple applications in different domains and platforms and also the ability to integrate with enterprise customers that use ADFS, SiteMinder or any other ws-federation identity provider.

I would like to thanks my co-workers [@jpgd](http://twitter.com/jpgd) and [@woloski](http://twitter.com/woloski) from [Southworks](http://blogs.southworks.net) because they helped  shaping this package.