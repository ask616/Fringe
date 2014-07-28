//
//  ASSecondViewController.m
//  FringeTabs
//
//  Created by Amundeep Singh on 7/28/14.
//  Copyright (c) 2014 Amundeep Singh. All rights reserved.
//

#import "ASSecondViewController.h"

@interface ASSecondViewController ()

@end

@implementation ASSecondViewController {
    
    NSArray *friends;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    friends = [NSArray arrayWithObjects:@"Omar Alhait", @"Zuhayeer Musa", @"Areeb Khan", @"Danish Shaik", nil];
    
    [self.tabBarController.tabBar setTintColor:[UIColor whiteColor]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [friends count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"SimpleTableCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
        UISwitch *switchview = [[UISwitch alloc] initWithFrame:CGRectZero];
        cell.accessoryView = switchview;
        
    }
    
    cell.textLabel.text = [friends objectAtIndex:indexPath.row];
    return cell;
}

@end
