//
//  CTSRestCore.m
//  CTSRestKit
//
//  Created by Yadnesh Wankhede on 29/07/14.
//  Copyright (c) 2014 CitrusPay. All rights reserved.
//

#import "CTSRestCore.h"
@implementation CTSRestCore
@synthesize baseUrl, delegate;

- (instancetype)initWithBaseUrl:(NSString*)url {
  self = [super init];
  if (self) {
    baseUrl = url;
  }
  return self;
}

// request to server
//
- (void)requestServer:(CTSRestCoreRequest*)restRequest {
  NSMutableURLRequest* request =
      [self fetchDefaultRequestForPath:restRequest.urlPath];
  [restRequest logProperties];

  [request setHTTPMethod:[self getHTTPMethodFor:restRequest.httpMethod]];

  request = [self requestByAddingHeaders:request headers:restRequest.headers];

  request = [self requestByAddingParameters:request
                                 parameters:restRequest.parameters];
  __block int requestId = restRequest.requestId;

  NSOperationQueue* mainQueue = [[NSOperationQueue alloc] init];
  [mainQueue setMaxConcurrentOperationCount:5];

  __block id<CTSRestCoreDelegate> blockDelegate = delegate;
  LogTrace(@"URL > %@ ", request);

  [NSURLConnection
      sendAsynchronousRequest:request
                        queue:mainQueue
            completionHandler:^(NSURLResponse* response,
                                NSData* data,
                                NSError* connectionError) {
                CTSRestCoreResponse* restResponse =
                    [[CTSRestCoreResponse alloc] init];
                NSError* error = nil;
                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                int statusCode = [httpResponse statusCode];
                if (![self isHttpSucces:statusCode]) {
                  error =
                      [CTSError getServerErrorWithCode:statusCode withInfo:nil];
                }
                restResponse.responseString =
                    [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
                restResponse.requestId = requestId;
                restResponse.error = error;
                [restResponse logProperties];
                [blockDelegate restCore:self didReceiveResponse:restResponse];
            }];
}

- (NSMutableURLRequest*)fetchDefaultRequestForPath:(NSString*)path {
  NSURL* serverUrl =
      [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", baseUrl, path]];

  return [NSMutableURLRequest requestWithURL:serverUrl
                                 cachePolicy:NSURLRequestUseProtocolCachePolicy
                             timeoutInterval:30.0];
}

- (NSMutableURLRequest*)requestByAddingHeaders:(NSMutableURLRequest*)request
                                       headers:(NSDictionary*)headers {
  for (NSString* key in [headers allKeys]) {
    [request addValue:[headers valueForKey:key] forHTTPHeaderField:key];
  }
  return request;
}

- (NSMutableURLRequest*)requestByAddingParameters:(NSMutableURLRequest*)request
                                       parameters:(NSDictionary*)parameters {
  if (parameters != nil)
    [request setHTTPBody:[[self serializeParams:parameters]
                             dataUsingEncoding:NSUTF8StringEncoding]];
  return request;
}

#pragma mark - helper methods

- (NSString*)getHTTPMethodFor:(HTTPMethod)methodType {
  switch (methodType) {
    case GET:
      return @"GET";
      break;
    case POST:
      return @"POST";
      break;
    case PUT:
      return @"PUT";
      break;
    case DELETE:
      return @"DELETE";
      break;
  }
}

- (NSString*)serializeParams:(NSDictionary*)params {
  NSMutableArray* pairs = NSMutableArray.array;
  for (NSString* key in params.keyEnumerator) {
    id value = params[key];
    if ([value isKindOfClass:[NSDictionary class]])
      for (NSString* subKey in value)
        [pairs addObject:[NSString stringWithFormat:
                                       @"%@[%@]=%@",
                                       key,
                                       subKey,
                                       [self escapeValueForURLParameter:
                                                 [value objectForKey:subKey]]]];

    else if ([value isKindOfClass:[NSArray class]])
      for (NSString* subValue in value)
        [pairs addObject:[NSString
                             stringWithFormat:
                                 @"%@[]=%@",
                                 key,
                                 [self escapeValueForURLParameter:subValue]]];

    else
      [pairs addObject:[NSString stringWithFormat:
                                     @"%@=%@",
                                     key,
                                     [self escapeValueForURLParameter:value]]];
  }
  return [pairs componentsJoinedByString:@"&"];
}

- (NSString*)escapeValueForURLParameter:(NSString*)valueToEscape {
  return (__bridge_transfer NSString*)CFURLCreateStringByAddingPercentEscapes(
      NULL,
      (__bridge CFStringRef)valueToEscape,
      NULL,
      (CFStringRef) @"!*'();:@&=+$,/?%#[]",
      kCFStringEncodingUTF8);
}

- (BOOL)isHttpSucces:(int)statusCode {
  return [statusCodeIndexSetForClass(CTSStatusCodeClassSuccessful)
      containsIndex:statusCode];
}

NSIndexSet* statusCodeIndexSetForClass(CTSStatusCodeClass statusCodeClass) {
  return [NSIndexSet
      indexSetWithIndexesInRange:statusCodeRangeForClass(statusCodeClass)];
}

NSRange statusCodeRangeForClass(CTSStatusCodeClass statusCodeClass) {
  return NSMakeRange(statusCodeClass, CTSStatusCodeRangeLength);
}

@end
