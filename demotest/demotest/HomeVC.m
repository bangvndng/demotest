//
//  HomeVC.m
//  demotest
//
//  Created by Bang Ngoc Vu on 4/26/14.
//  Copyright (c) 2014 Bang Ngoc Vu. All rights reserved.
//

#import "HomeVC.h"
#import <MapKit/MapKit.h>

@interface HomeVC ()<MKMapViewDelegate>{
    
    __weak IBOutlet MKMapView *_mapview;
    
}

@end

@implementation HomeVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_mapview setDelegate:self];
    _mapview.showsUserLocation = YES;
    
    }

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IMPLEMENTATION
- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
    MKPolylineView *polylineView = [[MKPolylineView alloc] initWithPolyline:overlay];
    polylineView.strokeColor = [UIColor colorWithRed:204/255. green:45/255. blue:70/255. alpha:1.0];
    polylineView.lineWidth = 10.0;
    
    return polylineView;
}

- (CLLocationCoordinate2D)coordinateWithLocation:(NSDictionary*)location
{
    double latitude = [[location objectForKey:@"lat"] doubleValue];
    double longitude = [[location objectForKey:@"lng"] doubleValue];
    
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (void)drawRoute:(NSString *)isPrimary withRoute:(NSDictionary *)route andUserLocation:(MKUserLocation *)userLocation{
    
//    NSDictionary *firstRoute = [routes objectAtIndex:0];
    NSDictionary *firstRoute = route;
    
    NSDictionary *leg =  [[firstRoute objectForKey:@"legs"] objectAtIndex:0];
    
    NSDictionary *end_location = [leg objectForKey:@"end_location"];
    
    double latitude = [[end_location objectForKey:@"lat"] doubleValue];
    double longitude = [[end_location objectForKey:@"lng"] doubleValue];
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = coordinate;
    point.title =  [leg objectForKey:@"end_address"];
    point.subtitle = @"I'm here!!!";
    
    [_mapview addAnnotation:point];
    
    NSArray *steps = [leg objectForKey:@"steps"];
    
    int stepIndex = 0;
    
    CLLocationCoordinate2D stepCoordinates[1  + [steps count] + 1];
    
    stepCoordinates[stepIndex] = userLocation.coordinate;
    
    for (NSDictionary *step in steps) {
        
        NSDictionary *start_location = [step objectForKey:@"start_location"];
        stepCoordinates[++stepIndex] = [self coordinateWithLocation:start_location];
        
        if ([steps count] == stepIndex){
            NSDictionary *end_location = [step objectForKey:@"end_location"];
            stepCoordinates[++stepIndex] = [self coordinateWithLocation:end_location];
        }
    }
    
    MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:stepCoordinates count:1 + stepIndex];
    [_mapview addOverlay:polyLine];
    
    if ([isPrimary isEqualToString:@"YES"]) {
        CLLocationCoordinate2D centerCoordinate = CLLocationCoordinate2DMake((userLocation.location.coordinate.latitude + coordinate.latitude)/2, (userLocation.location.coordinate.longitude + coordinate.longitude)/2);
        
        MKCoordinateSpan span = MKCoordinateSpanMake(0.05, 0.05);
        MKCoordinateRegion region = MKCoordinateRegionMake(centerCoordinate, span);
        
        [_mapview setRegion:region];
        
        [_mapview setCenterCoordinate:centerCoordinate animated:YES];
    }
    
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation{
    
    NSString *baseUrl = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%@&sensor=true&alternatives=true", mapView.userLocation.location.coordinate.latitude,  mapView.userLocation.location.coordinate.longitude, @"Louise Dr Mountain View CA"];
    
    NSLog(@"%@", baseUrl);
    
    NSURL *url = [NSURL URLWithString:[baseUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSError *error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        NSArray *routes = [result objectForKey:@"routes"];
        
        NSLog(@"%@", routes);
        
        if ([routes count] > 0) {
            int i = 0;
            for (NSDictionary* route in routes) {
                if (i == 0) {
                    [self drawRoute:@"YES" withRoute:route andUserLocation:userLocation];
                }else{
                    [self drawRoute:@"NO" withRoute:route andUserLocation:userLocation];
                }
                i++;
            }
            
        }
    }];

}

@end
