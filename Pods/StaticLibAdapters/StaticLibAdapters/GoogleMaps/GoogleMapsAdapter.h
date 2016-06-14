@import Foundation;
@import UIKit;

/* How To Enable GoogleMapsAdapter
 *
 * # On the App Target
 *
 * Provide the implementation for the factory methods, e.g.:
 *
 *   + (UIView<GMSMapViewAPI> *)mapViewWithFrame:(CGRect)frame {
 *       return [[GMSMapView alloc] initWithFrame:frame];
 *   }
 *
 * # On Libraries That Need GoogleMaps
 *
 * Use `GoogleMapsAdapter` factory methods to create the objects.
 *
 */


@protocol GMSPathAPI <NSObject>

- (NSString *)encodedPath;

@end


@protocol GMSCameraPositionAPI <NSObject>
@end


@protocol GMSCoordinateBoundsAPI <NSObject>
@end


@protocol GMSMapViewAPI <NSObject>

@property (nonatomic, strong) id<GMSCameraPositionAPI> camera;

- (id<GMSCameraPositionAPI>)cameraForBounds:(id<GMSCoordinateBoundsAPI>)bounds insets:(UIEdgeInsets)insets;

// UIView Stuff
@property(nonatomic) CGRect frame;
@property(nonatomic) UIViewAutoresizing autoresizingMask;
@property(nonatomic) BOOL translatesAutoresizingMaskIntoConstraints;

@end


@protocol GMSPolygonAPI <NSObject>

@property (nonatomic, weak) id<GMSMapViewAPI> map;
@property (nonatomic, strong) UIColor *fillColor;

@end


@interface GoogleMapsAdapter : NSObject

+ (id<GMSPathAPI>)pathFromEncodedPath:(NSString *)path;

+ (UIView<GMSMapViewAPI> *)mapViewWithFrame:(CGRect)frame;

+ (id<GMSCoordinateBoundsAPI>)coordinateBoundsWithPath:(id<GMSPathAPI>)path;

+ (id<GMSPolygonAPI>)polygonWithPath:(id<GMSPathAPI>)path;

@end