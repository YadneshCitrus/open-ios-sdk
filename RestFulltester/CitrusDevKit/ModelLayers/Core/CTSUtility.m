//
//  CTSUtility.m
//  RestFulltester
//
//  Created by Yadnesh Wankhede on 17/06/14.
//  Copyright (c) 2014 Citrus. All rights reserved.
//

#import "CTSUtility.h"
#import "CreditCard-Validator.h"
#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_ERROR;
#endif
#import "CTSAuthLayerConstants.h"
@implementation CTSUtility
+ (BOOL)validateCardNumber:(NSString*)number {
  return [CreditCard_Validator checkCreditCardNumber:number];
}

+ (NSString*)readFromDisk:(NSString*)key {
  DDLogInfo(@"Key %@ value %@",
            key,
            [[NSUserDefaults standardUserDefaults] valueForKey:key]);
  return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

+ (void)saveToDisk:(id)data as:(NSString*)key {
  [[NSUserDefaults standardUserDefaults] setObject:data forKey:key];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)removeFromDisk:(NSString*)key {
  DDLogInfo(@"removing key %@", key);
  [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary*)readSigninTokenAsHeader {
  return @{
    @"Authorization" : [NSString
        stringWithFormat:@" Bearer %@",
                         [CTSUtility
                             readFromDisk:MLC_SIGNIN_ACCESS_OAUTH_TOKEN]]
  };
}

+ (NSDictionary*)readOauthTokenAsHeader:(NSString*)oauthToken {
  return @{
    @"Authorization" : [NSString stringWithFormat:@" Bearer %@", oauthToken]
  };
}

+ (NSDictionary*)readSignupTokenAsHeader {
  return @{
    @"Authorization" : [NSString
        stringWithFormat:@" Bearer %@",
                         [CTSUtility
                             readFromDisk:MLC_SIGNUP_ACCESS_OAUTH_TOKEN]]
  };
}

//+ (BOOL)validateEmail:(NSString*)candidate {
//  NSString* emailRegex =
//      @"(?:[a-z0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[a-z0-9!#$%\\&'*+/=?\\^_`{|}"
//      @"~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
//      @"x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
//      @"z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
//      @"]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
//      @"9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
//      @"-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])";
//  NSPredicate* emailTest =
//      [NSPredicate predicateWithFormat:@"SELF MATCHES[c] %@", emailRegex];
//
//  return [emailTest evaluateWithObject:candidate];
//}

+ (BOOL)validateEmail:(NSString*)candidate {
  NSString* emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
  NSPredicate* emailTest =
      [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];

  return [emailTest evaluateWithObject:candidate];
}

+ (BOOL)validateMobile:(NSString*)mobile {
  BOOL error = NO;
  if ([mobile length] == 10) {
    error = YES;
  }
  return error;
}

+ (BOOL)validateCVV:(NSString*)cvv cardNumber:(NSString*)cardNumber {
  BOOL error = NO;
  if ([CreditCard_Validator checkCardBrandWithNumber:cardNumber] ==
      CreditCardBrandAmex) {
    if ([cvv length] == 4) {
      error = YES;
    }
  } else {
    if ([cvv length] == 3) {
      error = YES;
    }
  }
  return error;
}

+ (BOOL)validateExpiryDate:(NSString*)date {
  NSArray* subStrings = [date componentsSeparatedByString:@"/"];
  if ([subStrings count] < 2) {
    return NO;
  }
  int month = [[subStrings objectAtIndex:0] intValue];
  int year = [[subStrings objectAtIndex:1] intValue];

  return [self validateExpiryDateMonth:month year:year];
}

+ (BOOL)validateExpiryDateMonth:(int)month year:(int)year {
  int expiryYear = year;
  int expiryMonth = month;
  if (![self validateExpiryMonth:month year:year]) {
    return FALSE;
  }
  if (![self validateExpiryYear:year]) {
    return FALSE;
  }
  return [self hasMonthPassed:expiryYear:expiryMonth];
}

+ (BOOL)validateExpiryMonth:(int)month year:(int)year {
  int expiryYear = year;
  int expiryMonth = month;
  if (expiryMonth == 0) {
    return FALSE;
  }
  return (expiryYear >= 1 && expiryMonth <= 12);
}

+ (BOOL)validateExpiryYear:(int)year {
  int expiryYear = year;
  if (expiryYear == 0) {
    return FALSE;
  }
  return [self hasYearPassed:expiryYear];
  // return FALSE;
}
+ (BOOL)hasYearPassed:(int)year {
  int normalized = [self normalizeYear:year];
  NSCalendar* gregorian =
      [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents* components =
      [gregorian components:NSYearCalendarUnit fromDate:[NSDate date]];
  int currentyear = [components year];
  return normalized > currentyear;
}

+ (BOOL)hasMonthPassed:(int)year:(int)month {
  NSCalendar* gregorian =
      [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
  NSDateComponents* components =
      [gregorian components:NSYearCalendarUnit fromDate:[NSDate date]];
  NSDateComponents* monthcomponent =
      [gregorian components:NSMonthCalendarUnit fromDate:[NSDate date]];
  int currentYear = [components year];
  int currentmonth = [monthcomponent month];
  int normalizeyear = [self normalizeYear:year];
  // Expires at end of specified month, Calendar month starts at 0
  return [self hasYearPassed:year] ||
         (normalizeyear == currentYear && month < (currentmonth + 1));
}
+ (int)normalizeYear:(int)year {
  if (year < 100 && year >= 0) {
    NSCalendar* gregorian =
        [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents* components =
        [gregorian components:NSYearCalendarUnit fromDate:[NSDate date]];
    NSInteger yearr = [components year];
    NSString* currentYear = [NSString stringWithFormat:@"%d", (int)yearr];

    NSString* prefix =
        [currentYear substringWithRange:NSMakeRange(0, currentYear.length - 2)];

    // year = Integer.parseInt(String.format(Locale.US, "%s%02d", prefix,
    // year));
    year = [[NSString stringWithFormat:@"%@%02d", prefix, year] intValue];
  }
  return year;
}

@end
