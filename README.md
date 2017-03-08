# LAClient

![LAClient](laclient-square.png)

The Light API Client (LAClient) is a simple, light-weight client for working with REST-based APIs.

At it's simplest, it looks like:

```Objective-C
LAClient *apiClient = [[LAClient alloc] initWithURL:[NSURL URLWithString:@"https://localhost/api"];
[apiClient getResource:[Person class]
			   atPath:@"person/123"
			   callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
			   Person *person = resource;
			   NSLog(@"Person found: %@", person);
			}];
```

# Installation

Add the LightAPIClient directory (and contents) to your project
Add the Security.framework to your project

OR

Add to your Podfile:

pod 'LAClient', '1.0.0'

# Usage


## Representations
You can have your classes implement the LARepresentation protocol and map their properties from the raw data returned from the api calls

OR

Create representation objects that have the same properties as the JSON representation you'll be getting from your API and have your objects extend LAJsonRepresentation.  This class attempts to deserialize and map json representations being returned from the API to your object model. This works well in most all situations with the exception of Arrays. Without generics in Objective C, we have have no way to know what type of objects you are expecting in your array.  Therefore, if your object has a property that is an array, you'll need to write a custom setter to 'type' the repponse.  Take a look at the example below:

JSON Representation:
```
{firstName:"Lana", lastName:"Del-rey", favoriteFood:"pizza", birthday:334179084000, phoneNumbers:[{"type:":"mobile", "number":"123-456-7890"}], uri:"https://localhost/api/person/123"}
```

Class:
```Objective-C
@interface Person : LAJsonResource
@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;
@property (nonatomic, retain) NSString *favoriteFood;
@property (nonatomic, retain) NSDate *birthday;
@property (nonatomic, retain) NSString *uri;
@property (nonatomic, retain) NSArray *phoneNumbers;
@end

...

@implementation Person

/*
 Because the deserialization process cannot detect what
 type of object the 'phoneNumber' array consists of,
 you need to tell it how to desearizlize in this way.
 */
-(void)setPhoneNumbers:(NSArray *)phoneNumbers{
	_phoneNumbers = [self typedArrayWithType:[PhoneNumber class] value:phoneNumberrs];
}

/*
	If you need to customize the serialization of date formats to suite your api,
	you can have your representation implement a dateformmatter to be used
	by the client
*/
-(NSDateFormatter*)dateformatter{
    if(_dateformatter == nil){
        _dateformatter =  [[NSDateFormatter alloc] init];
        _dateformatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        [_dateformatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }
    return _dateformatter;
}
@end
```

## API Client Configuration

### Basic
```Objective-C
LAClient *apiClient = [[LAClient alloc] initWithURL:[NSURL URLWithString:@"https://localhost/api"];
```
### Advanced
Additional features of the client can be enabled by setting properties on it.  For example:

```Objective-C
LAClient *apiClient = [[LAClient alloc] initWithURL:[NSURL URLWithString:@"https://localhost/api"]];
apiClient.connectionUserAgent = @"iOS App V1.2";
apiClient.connectionTimeoutInSeconds = 30;
apiClient.debugEnabled = YES;
apiClient.securityProvider = [[LASimpleOAuthProvider alloc] initWithURL:[NSURL URLWithString:@"https://localhost:8081/oauth"]
																			  securityDomain:@"security_domain"
																					clientId:@"my_client"
																				clientSecret:@"my_client_secret"]];

```
### Security
Setting the security provider on the client, will cause it to use that security provider to secure HTTP requests to the API.

* NOTE that the 'securityDomain' must be unique or each LASecurityProvider you create. For example, if you make two different api clients to talk to two different apis, but they use the same oauth server (client creds, etc...), then you must use the same instance of the oauth client with the same keychain app id or you'll get refresh race conditions.

## Make API Calls

```Objective-C
apiClient getResourceList:[Person class]
			   atPath:@"person"
			   callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
			   NSArray *people = resource;
			   NSLog(@"%d people found", people.count);
			}];

apiClient getResource:[Person class]
			   atPath:@"person/123"
			   callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
			   Person *person = resource;
			   NSLog(@"Person found: %@", person);
			}];

...

person.favoriteFood = @"Lasagna";

[apiClient putResource:person
			  callback:^(id resource, NSHTTPURLResponse *response, NSError *error) {
			  	if(error != nil && response.statusCode == 200){}
			  		NSLog(@"Person saved");
			  	}
			  }];
```

# TODO

* Finish demo - find sample api to hit
