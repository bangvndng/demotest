//
//  HomeVC.m
//  demotest
//
//  Created by Bang Ngoc Vu on 4/26/14.
//  Copyright (c) 2014 Bang Ngoc Vu. All rights reserved.
//

#import "HomeVC.h"
#import <MapKit/MapKit.h>
#import "DMPointAnnotation.h"
#import "DMPolyline.h"
#import "DetailTableViewCell.h"
#import "DetailVC.h"

@interface HomeVC ()<MKMapViewDelegate, CLLocationManagerDelegate, DetailTableViewCellDelegate>{
    
    __weak IBOutlet MKMapView *_mapview;
    NSArray *_parkingAreas;
    CLLocation *_currentLocation;
    BOOL _updated;
    BOOL _detailView;
    
    NSArray *_currentRoutes;
    NSMutableDictionary *_cureentRoute;
    int _currentRouteIndex;
    NSString *_currentAdress;
}

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation HomeVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        
        [self.locationManager startUpdatingLocation];
        
        _parkingAreas = @[
                          @[@"Esrumvej 158, 3000 Helsingør, Denmark", @56.041409, @12.575931],
                          @[@"Lærkevej 52, 3000 Helsingør, Denmark",@56.040369, @12.576697],
                          @[@"Ewaldsvænget 34, 3000 Helsingør, Denmark",@56.037378, @12.583382],
                          @[@"Marienlyst Alle 26, 3000 Helsingør, Denmark", @56.040669, @12.603683],
                          @[@"Nordre Strandvej 2, 3000 Helsingør, Denmark",@56.043984, @12.601077]
                          ];
        _detailView = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [_mapview setDelegate:self];
    //_mapview.showsUserLocation = YES;
    
    _updated = NO;

    [self registerNibsForTableView];
    
    [self hideDetailsTable];
    
    self.title = @"POC DEMO MAP DIRECTION";
    
    _currentRouteIndex = 0;
}

- (void) registerNibsForTableView
{
    NSArray *cells = @[@"DetailTableViewCell"];
    
    for (NSString *cellClass in cells) {
        [_tableView registerNib:[UINib  nibWithNibName:cellClass
                                                bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:cellClass];
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MAPVIEW AND CLLOCATIONMANAGER DELEGATES

- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
{
    NSLog(@"locationManager didUpdateToLocation Location: %@", [newLocation description]);
    [self.locationManager stopUpdatingLocation];
    
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:56.0409323 longitude:12.5885987];
    
    _currentLocation = userLocation;
    
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = userLocation.coordinate;
    point.title = @"Current Location";
    point.subtitle = @"I'm here!!!";
    
    [_mapview addAnnotation:point];
    
    MKCoordinateSpan span = MKCoordinateSpanMake(0.02, 0.02);
    MKCoordinateRegion region = MKCoordinateRegionMake(userLocation.coordinate, span);
    
    [_mapview setRegion:region];
    
    [_mapview setCenterCoordinate:userLocation.coordinate animated:YES];

    
    for (NSArray *area in _parkingAreas) {
        DMPointAnnotation *point = [[DMPointAnnotation alloc] init];
        point.coordinate = CLLocationCoordinate2DMake([[area objectAtIndex:1] doubleValue], [[area objectAtIndex:2] doubleValue]);
        point.title = [area objectAtIndex:0];
        point.subtitle = [area objectAtIndex:0];
        point.address = [area objectAtIndex:0];
        
        [_mapview addAnnotation:point];
    }

    
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // If it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    // Handle any custom annotations.
    if ([annotation isKindOfClass:[MKPointAnnotation class]])
    {
        // Try to dequeue an existing pin view first.
        MKPinAnnotationView *pinView = (MKPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:@"CustomPinAnnotationView"];
        if (!pinView)
        {
            // If an existing pin view was not available, create one.
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"CustomPinAnnotationView"];
            
            if ([annotation isKindOfClass:[DMPointAnnotation class]]) {
                pinView.tintColor = [UIColor greenColor];
                pinView.pinColor = MKPinAnnotationColorGreen;
            }else{
                pinView.tintColor = [UIColor redColor];//or Green or Purple
                pinView.pinColor = MKPinAnnotationColorRed;
            }
            
            
            pinView.enabled = YES;
            pinView.canShowCallout = YES;
            
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pinView.rightCalloutAccessoryView = rightButton;
        } else {
            pinView.annotation = annotation;
        }
        
        
        
        return pinView;
    }
    return nil;
}

-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    NSLog(@"HomeVC calloutAccessoryControlTapped");
    id <MKAnnotation> annotation = [view annotation];
    if ([annotation isKindOfClass:[DMPointAnnotation class]])
    {
        DMPointAnnotation *pannotation = annotation;
        NSLog(@"%f", pannotation.coordinate.latitude);
        NSLog(@"%f", pannotation.coordinate.longitude);
        NSLog(@"%@", pannotation.address);
        
        [self showRouteForAddress:pannotation.address andCurrentLocation:_currentLocation];
        
    }else{
        NSLog(@"HomeVC mapView calloutAccessoryControlTapped annontation is not kind of class DMPointAnnotation");
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    NSLog(@"HomeVC rendererForOverlay");
    if ([overlay isKindOfClass:[MKPolygon class]])
    {
        MKPolygonRenderer *renderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        
        renderer.fillColor   = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        renderer.lineWidth   = 3;
        
        return renderer;
    }
    
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
        
        renderer.fillColor   = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        renderer.lineWidth   = 3;
        
        return renderer;
    }
    
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        
        if ([overlay isKindOfClass:[DMPolyline class]]) {
            
            DMPolyline *poverlay = overlay;
            
            if ([poverlay.linetype isEqualToString:@"YES"]) {
                renderer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.9];
                renderer.lineWidth   = 5;
            }else{
                renderer.strokeColor = [[UIColor greenColor] colorWithAlphaComponent:0.6];
                renderer.lineWidth   = 3;
            }
            
            return renderer;
        }else{
            renderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.7];
            renderer.lineWidth   = 3;
            
            return renderer;
        }
        
        
    }
    
    return nil;
}

// for iOS versions prior to 7; see `rendererForOverlay` for iOS7 and later

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    NSLog(@"HomeVC viewForOverlay");
    if ([overlay isKindOfClass:[MKPolygon class]])
    {
        MKPolygonView *overlayView = [[MKPolygonView alloc] initWithPolygon:overlay];
        
        overlayView.fillColor      = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        overlayView.strokeColor    = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        overlayView.lineWidth      = 3;
        
        return overlayView;
    }
    
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircleView *overlayView = [[MKCircleView alloc] initWithCircle:overlay];
        
        overlayView.fillColor     = [[UIColor cyanColor] colorWithAlphaComponent:0.2];
        overlayView.strokeColor   = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        overlayView.lineWidth     = 3;
        
        return overlayView;
    }
    
    if ([overlay isKindOfClass:[MKPolyline class]])
    {
        MKPolylineView *overlayView = [[MKPolylineView alloc] initWithPolyline:overlay];
        
        overlayView.strokeColor     = [[UIColor blueColor] colorWithAlphaComponent:0.7];
        overlayView.lineWidth       = 3;
        
        return overlayView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    NSLog(@"HomeVC didDeselectAnnotationView");
    [self hideDetailsTable];
}

#pragma mark- PRIVATE FUNCTIONS

-(void)hideDetailsTable
{
    NSLog(@"HomeVC hideDetailsTable");
    _detailView = NO;
    _mapview.frame = CGRectMake(0, 0, _mapview.frame.size.width, 568);
}

-(void)showDetailsTable
{
    NSLog(@"HomeVC showDetailsTable");
    _detailView = YES;
    _mapview.frame = CGRectMake(0, 0, _mapview.frame.size.width, 358);
}

- (void)showNextAlternativeRoute
{
    for (id<MKOverlay> overlayToRemove in _mapview.overlays)
    {
        //if ([overlayToRemove isKindOfClass:[OverlayClassToRemove class]])
        //{
        [_mapview removeOverlay:overlayToRemove];
        //}
    }

    
    int i = 0;
    int max = [_currentRoutes count] -1;
    
    if (_currentRouteIndex == max) {
        _currentRouteIndex = 0;
    }else{
        _currentRouteIndex += 1;
    }
    
    for (NSDictionary* route in _currentRoutes) {
        if (_currentRouteIndex == i) {
            [self drawRoute:@"YES" withRoute:route andUserLocation:_currentLocation];
            
            _cureentRoute = [[NSMutableDictionary alloc] initWithDictionary:route];
            
            [_cureentRoute setObject:_currentAdress forKey:@"name"];
            [_cureentRoute setObject:_currentAdress forKey:@"address"];
            
        }else{
            [self drawRoute:@"NO" withRoute:route andUserLocation:_currentLocation];
        }
        i++;
    }
    
    [_tableView reloadData];

}

- (void)showRouteForAddress:(NSString *)address andCurrentLocation:(CLLocation *)userLocation{
    
    NSString *baseUrl = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/json?origin=%f,%f&destination=%@&sensor=true&alternatives=true", userLocation.coordinate.latitude,  userLocation.coordinate.longitude, address];
    
    
    NSLog(@"HomeVC showRouteForAddress %@", baseUrl);
    
    NSURL *url = [NSURL URLWithString:[baseUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    //for (NSObject<MKAnnotation> *annotation in [_mapview selectedAnnotations]) {
        //[_mapview deselectAnnotation:(id <MKAnnotation>)annotation animated:NO];
    //}
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSError *error = nil;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        
        //NSLog(@"%@", result);
        
        NSArray *routes = [result objectForKey:@"routes"];
        
        for (id<MKOverlay> overlayToRemove in _mapview.overlays)
        {
            //if ([overlayToRemove isKindOfClass:[OverlayClassToRemove class]])
            //{
                [_mapview removeOverlay:overlayToRemove];
            //}
        }
        
        if (!_detailView) {
            [self showDetailsTable];
        }
        
        if ([routes count] > 0) {
            
            _currentRoutes = [routes copy];
            
            if ([routes count] == 1) {
                [self drawRoute:@"YES" withRoute:[routes objectAtIndex:0] andUserLocation:userLocation];
            }else{
                int i = 0;
                for (NSDictionary* route in routes) {
                    if (i == 0) {
                        [self drawRoute:@"YES" withRoute:route andUserLocation:userLocation];
                        
                        _cureentRoute = [[NSMutableDictionary alloc] initWithDictionary:route];
                        
                        [_cureentRoute setObject:address forKey:@"name"];
                        [_cureentRoute setObject:address forKey:@"address"];
                        
                        _currentAdress = address;
                        
                    }else{
                        [self drawRoute:@"NO" withRoute:route andUserLocation:userLocation];
                    }
                    i++;
                }
            }
            
        }else{
            
            
        }
        
        [_tableView reloadData];
    }];

    
}

- (CLLocationCoordinate2D)coordinateWithLocation:(NSDictionary*)location
{
    double latitude = [[location objectForKey:@"lat"] doubleValue];
    double longitude = [[location objectForKey:@"lng"] doubleValue];
    
    return CLLocationCoordinate2DMake(latitude, longitude);
}

- (void)drawRoute:(NSString *)isPrimary withRoute:(NSDictionary *)route andUserLocation:(CLLocation *)userLocation{
    
    NSDictionary *firstRoute = route;
    
    NSDictionary *leg =  [[firstRoute objectForKey:@"legs"] objectAtIndex:0];
    
    NSDictionary *end_location = [leg objectForKey:@"end_location"];
    
    double latitude = [[end_location objectForKey:@"lat"] doubleValue];
    double longitude = [[end_location objectForKey:@"lng"] doubleValue];
    
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
    
    DMPolyline *polyLine = [DMPolyline polylineWithCoordinates:stepCoordinates count:1 + stepIndex];
    polyLine.linetype = isPrimary;
    [_mapview addOverlay:polyLine];
    
    if ([isPrimary isEqualToString:@"YES"]) {
   
        CLLocationCoordinate2D min = userLocation.coordinate;
        CLLocationCoordinate2D max = CLLocationCoordinate2DMake(latitude ,longitude);
        
        CLLocationCoordinate2D points[2] = {min, max};
        
        //the magic part
        MKPolygon *poly = [MKPolygon polygonWithCoordinates:points count:2];
        
        NSLog(@"HomeVC drawRoute");
        MKCoordinateRegion region = MKCoordinateRegionForMapRect([poly boundingMapRect]);
        region.span = MKCoordinateSpanMake(region.span.latitudeDelta + 0.01, region.span.longitudeDelta+ 0.01);
        [_mapview setRegion:region];
    }
    
}



#pragma mark- TABLE VIEW DATASOURCE DELEGATE

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 210;
}

- (DetailTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identify = @"DetailTableViewCell";
    DetailTableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:identify];
    
    if (cell == NULL) {
        cell = [[DetailTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identify];
    }
    
    cell.delegate = (id)self;
    
    NSLog(@"HomeVC cellForRowAtIndexPath %@", _cureentRoute);
    
    if (_cureentRoute) {
        if ([_cureentRoute objectForKey:@"legs"]) {
            NSArray *legs = [_cureentRoute objectForKey:@"legs"];

            
            NSDictionary *distance = [legs[0] objectForKey:@"distance"];
            NSDictionary *duration = [legs[0] objectForKey:@"duration"];
            
            NSString *summary = [_cureentRoute objectForKey:@"summary"];
            
            cell.cellDistance.text = [distance objectForKey:@"text"];
            cell.cellDuration.text = [duration objectForKey:@"text"];
            
            cell.cellSummary.text = summary;
            
            cell.cellAddress.text = [_cureentRoute objectForKey:@"address"];
            cell.cellTitle.text = [_cureentRoute objectForKey:@"name"];
            
            if ([_currentRoutes count] == 1) {
                [cell.cellBtnNextAlternative setAlpha:0];
            }else{
                [cell.cellBtnNextAlternative setAlpha:1];
            }
            
        }
    }
    
    return cell;
}

#pragma mark - DETAIL TABLE VIEW CELL DELEGATE

- (void)detailTableViewCell:(DetailTableViewCell *)detailTableViewCell didPressDetail:(NSDictionary *)info
{
    
    if (_cureentRoute) {
        if ([_cureentRoute objectForKey:@"legs"]) {
            NSArray *legs = [_cureentRoute objectForKey:@"legs"];
            NSArray *steps = [legs[0] objectForKey:@"steps"];
            DetailVC *detailVC = [[DetailVC alloc] init];
            detailVC.title = _currentAdress;
            detailVC.steps = steps;
            [self.navigationController pushViewController:detailVC animated:YES];
        }
    }
    
    NSLog(@"HomeVC detailTableViewCell didPressDetail");
    
}

- (void)detailTableViewCell:(DetailTableViewCell *)detailTableViewCell didPressAlternativeRoute:(NSDictionary *)info
{
    NSLog(@"HomeVC detailTableViewCell didPressAlternativeRoute");
    
    [self showNextAlternativeRoute];
    
}

@end
