//
//  CTMarvelCharactersEventsAPIManager.m
//  APIManagers
//
//  Created by casa's script.
//  Copyright © 2018年 casa. All rights reserved.
//

#import "CTMarvelCharactersEventsAPIManager.h"
#import "CTMarvelService.h"

NSString * const kCTMarvelCharactersEventsAPIManagerRequiredParamKeyCharacterID = @"characterId";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyFilterByName = @"name";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyEventStartByName = @"nameStartWith";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyModifiedSince = @"modifiedSince";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyCreators = @"creators";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeySeries = @"series";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyComics = @"comics";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyStories = @"stories";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyOrderBy = @"orderBy";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyOrderBy_Value_NameASC = @"name";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyOrderBy_Value_NameDESC = @"-name";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyOrderBy_Value_ModifiedASC = @"modified";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyOrderBy_Value_ModifiedDESC = @"-modified";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyOrderBy_Value_StartDateASC = @"startDate";
NSString * const kCTMarvelCharactersEventsAPIManagerOptionalParamKeyOrderBy_Value_StartDateDESC = @"-startDate";

@interface CTMarvelCharactersEventsAPIManager () <CTAPIManagerValidator>

@property (nonatomic, assign, readwrite) BOOL isFirstPage;
@property (nonatomic, assign, readwrite) BOOL isLastPage;
@property (nonatomic, assign, readwrite) NSUInteger pageNumber;
@property (nonatomic, strong, readwrite) NSString *errorMessage;

@end

@implementation CTMarvelCharactersEventsAPIManager

@synthesize errorMessage = _errorMessage;

#pragma mark - life cycle
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.validator = self;
        self.cachePolicy = CTAPIManagerCachePolicyNoCache;
        _pageSize = 10;
		_pageNumber = 0;
        _isFirstPage = YES;
        _isLastPage = NO;
    }
    return self;
}

#pragma mark - public methods
- (NSInteger)loadData
{
    [self cleanData];
    return [super loadData];
}

- (void)loadNextPage
{
    if (self.isLastPage) {
        if ([self.interceptor respondsToSelector:@selector(manager:didReceiveResponse:)]) {
            [self.interceptor manager:self didReceiveResponse:nil];
        }
        return;
    }

    if (!self.isLoading) {
        [super loadData];
    }
}

- (void)cleanData
{
    [super cleanData];
    self.isFirstPage = YES;
    self.pageNumber = 0;
}

- (NSDictionary *)reformParams:(NSDictionary *)params
{
    NSMutableDictionary *result = [params mutableCopy];
    if (result == nil) {
        result = [[NSMutableDictionary alloc] init];
    }

    if (result[@"limit"] == nil) {
        result[@"limit"] = @(self.pageSize);
    } else {
        self.pageSize = [result[@"limit"] integerValue];
    }

    if (result[@"offset"] == nil) {
        if (self.isFirstPage == NO) {
            result[@"offset"] = @(self.pageNumber * self.pageSize);
        } else {
            result[@"offset"] = @(0);
        }
    } else {
        self.pageNumber = [result[@"offset"] unsignedIntegerValue] / self.pageSize;
    }
    
    if ([params[@"creators"] isKindOfClass:[NSArray class]]) {
        result[@"creators"] = [params[@"creators"] componentsJoinedByString:@","];
    }
    if ([params[@"series"] isKindOfClass:[NSArray class]]) {
        result[@"series"] = [params[@"series"] componentsJoinedByString:@","];
    }
    if ([params[@"comics"] isKindOfClass:[NSArray class]]) {
        result[@"comics"] = [params[@"comics"] componentsJoinedByString:@","];
    }
    if ([params[@"stories"] isKindOfClass:[NSArray class]]) {
        result[@"stories"] = [params[@"stories"] componentsJoinedByString:@","];
    }

    return result;
}

#pragma mark - interceptors
- (BOOL)beforePerformSuccessWithResponse:(CTURLResponse *)response
{
    self.isFirstPage = NO;
    NSInteger totalPageCount = ceil([response.content[@"data"][@"total"] doubleValue]/(double)self.pageSize);
    if (self.pageNumber == totalPageCount - 1) {
        self.isLastPage = YES;
    } else {
        self.isLastPage = NO;
    }
    self.pageNumber++;
    return [super beforePerformSuccessWithResponse:response];
}

- (BOOL)beforePerformFailWithResponse:(CTURLResponse *)response
{
    [super beforePerformFailWithResponse:response];
    self.errorMessage = response.content[@"status"];
    return YES;
}

#pragma mark - CTAPIManager
- (NSString *)methodName
{
    NSString *characterID = [self.paramSource paramsForApi:self][kCTMarvelCharactersEventsAPIManagerRequiredParamKeyCharacterID];
    return [NSString stringWithFormat:@"characters/%@/events", characterID];
}

- (NSString *)serviceIdentifier
{
    return CTServiceIdentifierMarvel;
}

- (CTAPIManagerRequestType)requestType
{
    return CTAPIManagerRequestTypeGet;
}

#pragma mark - CTAPIManagerValidator
- (CTAPIManagerErrorType)manager:(CTAPIBaseManager *)manager isCorrectWithParamsData:(NSDictionary *)data
{
    return CTAPIManagerErrorTypeNoError;
}

- (CTAPIManagerErrorType)manager:(CTAPIBaseManager *)manager isCorrectWithCallBackData:(NSDictionary *)data
{
    return CTAPIManagerErrorTypeNoError;
}

#pragma mark - getters and setters
- (NSUInteger)currentPageNumber
{
    return self.pageNumber;
}

@end
