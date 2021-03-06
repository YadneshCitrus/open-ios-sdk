//
//  CTSRestPluginBase.m
//  CTSRestKit
//
//  Created by Yadnesh Wankhede on 30/07/14.
//  Copyright (c) 2014 CitrusPay. All rights reserved.
//

#import "CTSRestPluginBase.h"
#import "CTSRestError.h"

@implementation CTSRestPluginBase
- (instancetype)initWithRequestSelectorMapping:(NSDictionary*)mapping
                                       baseUrl:(NSString*)baseUrl {
  self = [super init];
  if (self) {
    restCore = [[CTSRestCore alloc] initWithBaseUrl:baseUrl];
    restCore.delegate = self;
    requestSelectorMap = mapping;
    if (self != [CTSRestPluginBase class] &&
        ![self conformsToProtocol:@protocol(CTSRestCoreDelegate)]) {
      @throw
          [[NSException alloc] initWithName:@"UnImplimented Protocol"
                                     reason:@"CTSRestCoreDelegate - not adopted"
                                   userInfo:nil];
    }
  }
  return self;
}

- (void)restCore:(CTSRestCore*)restCore
    didReceiveResponse:(CTSRestCoreResponse*)response {
  SEL sel = [[requestSelectorMap
      valueForKey:toNSString(response.requestId)] pointerValue];

  if ([self respondsToSelector:sel]) {
    if (response.error != nil) {
      response = [self addJsonErrorToResponse:response];
    }
      
    [self performSelector:sel withObject:response];
  } else {
    @throw [[NSException alloc]
        initWithName:@"No Selector Found"
              reason:[NSString stringWithFormat:@"method %@ | NOT FOUND",
                                                NSStringFromSelector(sel)]
            userInfo:nil];
  }
}

- (CTSRestCoreResponse*)addJsonErrorToResponse:(CTSRestCoreResponse*)response {
  JSONModelError* jsonError = nil;
  NSError* serverError = response.error;
  CTSRestError* error;
  error = [[CTSRestError alloc] initWithString:response.responseString
                                         error:&jsonError];
  [error logProperties];
  if (error != nil) {
    if (error.type != nil) {
      error.error = error.type;
    } else {
      error.type = error.error;
    }
  } else {
    error = [[CTSRestError alloc] init];
  }

  error.serverResponse = response.responseString;

  NSDictionary* userInfo = @{
    CITRUS_ERROR_DESCRIPTION_KEY : error,
    NSLocalizedDescriptionKey :
        [[serverError userInfo] valueForKey:NSLocalizedDescriptionKey]
  };
  response.error = [NSError errorWithDomain:CITRUS_ERROR_DOMAIN
                                       code:[serverError code]
                                   userInfo:userInfo];
  return response;
}
@end
