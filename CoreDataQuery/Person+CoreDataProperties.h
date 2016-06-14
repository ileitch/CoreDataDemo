//
//  Person+CoreDataProperties.h
//  CoreDataQuery
//
//  Created by Ian Leitch on 6/14/16.
//  Copyright © 2016 Ian Leitch. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Person.h"

NS_ASSUME_NONNULL_BEGIN

@interface Person (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *personName;
@property (nullable, nonatomic, retain) NSString *sectionName;

@end

NS_ASSUME_NONNULL_END
