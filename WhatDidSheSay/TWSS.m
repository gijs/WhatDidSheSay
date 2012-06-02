//
//  TWSS.m
//  WhatDidSheSay
//
//  Created by Max Weisel on 1/17/12.
//  Copyright (c) 2012 Develoe LLC. All rights reserved.
//

#import "TWSS.h"

@implementation TWSS

- (id)init {
    if ((self = [super init]) != nil) {
        numberOfWordsInNgram = 1;
        threshold = 0.8f;
        trainingSize = 1900;
        positiveData = [[NSMutableArray alloc] initWithArray:[[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Positive_Prompts_TS" ofType:@"plist"]] subarrayWithRange:NSMakeRange(0, trainingSize)]];
        negativeData = [[NSMutableArray alloc] initWithArray:[[NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Negative_Prompts_FML" ofType:@"plist"]] subarrayWithRange:NSMakeRange(0, trainingSize)]];
        probabilities = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Probabilities" ofType:@"plist"]];
    }
    return self;
}

- (NSString *)cleanString:(NSString *)string {
    NSMutableString *mutableString = [[NSMutableString alloc] initWithString:string];
    [[NSRegularExpression regularExpressionWithPattern:@"[^\\s\\w]" options:0 error:nil] replaceMatchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length]) withTemplate:@""];
    [[NSRegularExpression regularExpressionWithPattern:@"^\\s+|\\s+$" options:0 error:nil] replaceMatchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length]) withTemplate:@""];
    [[NSRegularExpression regularExpressionWithPattern:@"\\s\\s" options:0 error:nil] replaceMatchesInString:mutableString options:0 range:NSMakeRange(0, [mutableString length]) withTemplate:@" "];
    NSString *returnString = [mutableString lowercaseString];
    [mutableString release];
    return returnString;
}

- (NSArray *)getNgrams:(NSString *)string {
    NSArray *words = [string componentsSeparatedByString:@" "];
    NSMutableArray *ngrams = [[NSMutableArray alloc] init];
    for (int w = 0; w+numberOfWordsInNgram <= words.count; w++) {
        NSMutableString *ngram = [[NSMutableString alloc] initWithString:@""];
        for (int n = 0; n < numberOfWordsInNgram; n++) {
            [ngram appendString:[words objectAtIndex:w+n]];
            if (n+1 < numberOfWordsInNgram)
                [ngram appendString:@" "];
        }
        [ngrams addObject:ngram];
        [ngram release];
    }
    [ngrams autorelease];
    return (ngrams.count > 0) ? ngrams : nil;
}

- (NSDictionary *)getNgramFrequencies:(NSArray *)documents_ {
    NSMutableArray *documents = [[NSMutableArray alloc] initWithArray:documents_];
    NSMutableDictionary *ngramFrequencies = [[NSMutableDictionary alloc] init];
    int totalNgrams = 0;
    for (int d = 0; d < documents.count; d++) {
        [documents replaceObjectAtIndex:d withObject:[self cleanString:[documents objectAtIndex:d]]];
        NSArray *ngrams = [self getNgrams:[documents objectAtIndex:d]];
        
        if (ngrams == nil) continue;
        
        for (int n = 0; n < ngrams.count; n++) {
            totalNgrams++;
            
            if ([ngramFrequencies objectForKey:[ngrams objectAtIndex:n]] != nil)
                [ngramFrequencies setObject:[NSNumber numberWithInt:[[ngramFrequencies objectForKey:[ngrams objectAtIndex:n]] intValue]+1] forKey:[ngrams objectAtIndex:n]];
            else
                [ngramFrequencies setObject:[NSNumber numberWithInt:1] forKey:[ngrams objectAtIndex:n]];
        }
    }
    [documents release];
    return [NSDictionary dictionaryWithObjectsAndKeys:[ngramFrequencies autorelease], @"ngramFrequencies", [NSNumber numberWithInt:totalNgrams], @"totalNgrams", nil];
}

- (NSDictionary *)getNgramBayesianProbabilities {
    NSLog(@"Building Ngram Bayesian Probabilities");
    
    NSMutableDictionary *probs = [[NSMutableDictionary alloc] init];
    
    NSDictionary *positiveNgramFrequencyData = [[self getNgramFrequencies:positiveData] retain];
    NSDictionary *negativeNgramFrequencyData = [[self getNgramFrequencies:negativeData] retain];
    
    for (NSString *ngram in [positiveNgramFrequencyData objectForKey:@"ngramFrequencies"]) {
        if ([[negativeNgramFrequencyData objectForKey:@"ngramFrequencies"] objectForKey:ngram] == nil)
            continue;
        
        [probs setObject:[NSNumber numberWithFloat:[[[positiveNgramFrequencyData objectForKey:@"ngramFrequencies"] objectForKey:ngram] floatValue] / ([[[positiveNgramFrequencyData objectForKey:@"ngramFrequencies"] objectForKey:ngram] floatValue] + [[[negativeNgramFrequencyData objectForKey:@"ngramFrequencies"] objectForKey:ngram] floatValue])] forKey:ngram];
    }
    
    [positiveNgramFrequencyData release];
    [negativeNgramFrequencyData release];
    
    return [probs autorelease];
}

- (float)getTWSSProbabilityForString:(NSString *)string {
    NSString *prompt = [self cleanString:string];
    NSArray *ngrams = [self getNgrams:prompt];
    if (probabilities == nil)
        probabilities = [[self getNgramBayesianProbabilities] retain];
    
    float n = 0.0f;
    for (int i = 0; i < ngrams.count; i++) {
        NSString *ngram = [ngrams objectAtIndex:i];
        if ([probabilities objectForKey:ngram] == nil) {
            continue;
        }
        n += logf(1.0f - [[probabilities objectForKey:ngram] floatValue]) - logf([[probabilities objectForKey:ngram] floatValue]);
    }
        
    return (1.0f / (1.0f + expf(n)));
}

- (BOOL)isTWSS:(NSString *)string {
    return [self getTWSSProbabilityForString:string] > threshold;
}

- (void)dealloc {
    [positiveData release];
    [negativeData release];
    [probabilities release];
    [super dealloc];
}

@end
