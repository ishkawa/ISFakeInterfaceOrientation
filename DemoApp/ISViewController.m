#import "ISViewController.h"

@implementation ISViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                      target:self
                                                    selector:@selector(rotate)
                                                    userInfo:nil
                                                     repeats:YES];
    }
    return self;
}

- (void)loadView
{
    CGRect frame = [UIScreen mainScreen].bounds;
    self.view = [[UIView alloc] initWithFrame:frame];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:frame];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.backgroundColor = [UIColor lightGrayColor];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    [self.view addSubview:tableView];
}

#pragma mark - UIViewController rotations

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return NO;
}

#pragma mark -

- (void)rotate
{
    if (!self.isViewLoaded) {
        return;
    }
    
    UIInterfaceOrientation interfaceOrientation;
    switch (self.fakeInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            break;
            
        case UIInterfaceOrientationLandscapeLeft:
            interfaceOrientation = UIInterfaceOrientationPortraitUpsideDown;
            break;

        case UIInterfaceOrientationPortraitUpsideDown:
            interfaceOrientation = UIInterfaceOrientationLandscapeRight;
            break;
            
        case UIInterfaceOrientationLandscapeRight:
            interfaceOrientation = UIInterfaceOrientationPortrait;
            break;
    }
    
    [self setFakeInterfaceOrientation:interfaceOrientation animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *Identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:Identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:Identifier];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %d", indexPath.row];
    
    return cell;
}

@end
