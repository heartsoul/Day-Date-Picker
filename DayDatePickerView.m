//
//  DayDatePickerView.m
//  DayDatePicker
//
//  Created by Hugh Bellamy on 17/01/2015.
//  Copyright (c) 2015 Hugh Bellamy. All rights reserved.
//

#import "DayDatePickerView.h"

@interface DayDatePickerView ()

@property (strong, nonatomic) NSDateComponents *components;

@property (strong, nonatomic) UIView *overlayView;

@property (strong, nonatomic) UIView *selectionIndicator;

@property (assign, nonatomic) NSInteger rowHeight;
@property (assign, nonatomic) NSInteger centralRowOffset;

@end

@implementation DayDatePickerView

@synthesize date = _date;
@synthesize dayDateFormatter = _dayDateFormatter;
@synthesize monthDateFormatter = _monthDateFormatter;
@synthesize yearDateFormatter = _yearDateFormatter;

- (NSString *)daySuffixForDate:(NSDate *)date {
    NSInteger day_of_month = [[self.calendar components:NSCalendarUnitDay fromDate:date] day];
    switch (day_of_month) {
        case 1:
        case 21:
        case 31: return @"st";
        case 2:
        case 22: return @"nd";
        case 3:
        case 23: return @"rd";
        default: return @"th";
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [self setup];
}

- (void)setup {
    if(self.daysTableView.superview) {
        return;
    }
    
    if([self.delegate respondsToSelector:@selector(rowHeightForDayDatePickerView:)]) {
        self.rowHeight = [self.delegate rowHeightForDayDatePickerView:self];
    }
    else {
        self.rowHeight = 44;
    }
    self.centralRowOffset = (self.frame.size.height - self.rowHeight) / 2;
    
    CGRect frame = self.bounds;
    if([self.delegate respondsToSelector:@selector(dayDatePickerView:sizeFractionForColumnType:)]) {
        frame.size.width = self.frame.size.width * [self.delegate dayDatePickerView:self sizeFractionForColumnType:DayDatePickerViewColumnTypeDay];
    }
    else {
        frame.size.width = self.frame.size.width / 2.3;
    }
    
    self.daysTableView = [self dayDatePickerTableViewWithFrame:frame type:DayDatePickerViewColumnTypeDay];
    [self addSubview:self.daysTableView];
    
    frame.origin.x = frame.size.width;
    if([self.delegate respondsToSelector:@selector(dayDatePickerView:sizeFractionForColumnType:)]) {
        frame.size.width = self.frame.size.width * [self.delegate dayDatePickerView:self sizeFractionForColumnType:DayDatePickerViewColumnTypeMonth];
    }
    else {
        frame.size.width = self.frame.size.width / 3.5;
    }
    self.monthsTableView = [self dayDatePickerTableViewWithFrame:frame type:DayDatePickerViewColumnTypeMonth];
    [self addSubview:self.monthsTableView];
    
    
    if([self.delegate respondsToSelector:@selector(dayDatePickerView:sizeFractionForColumnType:)]) {
        frame.size.width = self.frame.size.width * [self.delegate dayDatePickerView:self sizeFractionForColumnType:DayDatePickerViewColumnTypeMonth];
    }
    else {
        frame.size.width = self.frame.size.width - frame.origin.x - frame.size.width;
    }
    
    frame.origin.x = self.frame.size.width - frame.size.width;
    self.yearsTableView = [self dayDatePickerTableViewWithFrame:frame type:DayDatePickerViewColumnTypeYear];
    [self addSubview:self.yearsTableView];
    
    if([self.delegate respondsToSelector:@selector(selectionViewForDayDatePickerView:)]) {
        self.overlayView = [self.delegate selectionViewForDayDatePickerView:self];
    }
    else {
        self.overlayView = [[UIView alloc] init];
        if([self.delegate respondsToSelector:@selector(selectionViewBackgroundColorForDayDatePickerView:)]) {
            self.overlayView.backgroundColor = [self.delegate selectionViewBackgroundColorForDayDatePickerView:self];
        }
        else {
            self.overlayView.backgroundColor = [UIColor blackColor];
        }
        if([self.delegate respondsToSelector:@selector(selectionViewOpacityForDayDatePickerView:)]) {
            self.overlayView.alpha = [self.delegate selectionViewOpacityForDayDatePickerView:self];
        }
        else {
            self.overlayView.alpha = 0.1;
        }
        self.overlayView.userInteractionEnabled = NO;
    }
    
    CGRect selectionViewFrame = self.bounds;
    selectionViewFrame.origin.y = self.centralRowOffset;
    selectionViewFrame.size.height = self.rowHeight;
    self.overlayView.frame = selectionViewFrame;
    
    [self addSubview:self.overlayView];
    
    _calendar = [NSCalendar currentCalendar];
    self.minimumDate = [NSDate date];
    [self setDate:[NSDate date] updateComponents:YES];
}

- (UITableView *)dayDatePickerTableViewWithFrame:(CGRect)frame type:(DayDatePickerViewColumnType)type {
    UITableView *tableView =
    tableView = [[UITableView alloc]initWithFrame:frame style:UITableViewStylePlain];
    tableView.rowHeight = self.rowHeight;
    tableView.contentInset = UIEdgeInsetsMake(self.centralRowOffset, 0, self.centralRowOffset, 0);
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if([self.delegate respondsToSelector:@selector(dayDatePickerView:backgroundColorForColumn:)]) {
        tableView.backgroundColor = [self.delegate dayDatePickerView:self backgroundColorForColumn:type];
    }
    else {
        tableView.backgroundColor = [UIColor whiteColor];
    }
    return tableView;
}

- (void)setDate:(NSDate *)date {
    if([date compare:self.minimumDate] == NSOrderedAscending) {
        [self setDate:self.minimumDate updateComponents:YES];
    }
    else {
        [self setDate:date updateComponents:YES];
    }
}

- (void)setDate:(NSDate *)date updateComponents:(BOOL)updateComponents {
    _date = date;
    if(updateComponents) {
        self.components = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.date];
        [self selectRow:self.components.day - 1 inTableView:self.daysTableView animated:YES updateComponents:NO];
        [self selectRow:self.components.month - 1 inTableView:self.monthsTableView animated:YES updateComponents:NO];
        [self reload];
    }
    else if([self.delegate respondsToSelector:@selector(dayDatePickerView:didSelectDate:)]) {
        [self.delegate dayDatePickerView:self didSelectDate:date];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numberOfRows = 0;
    if(tableView == self.daysTableView) {
        numberOfRows = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:self.date].length;
    }
    else if(tableView == self.monthsTableView) {
        numberOfRows = [self.calendar rangeOfUnit:NSCalendarUnitMonth inUnit:NSCalendarUnitYear forDate:self.date].length;
    }
    else if(tableView == self.yearsTableView) {
        if([self.dataSource respondsToSelector:@selector(numberOfYearsInDayDatePickerView:)]) {
            numberOfRows = [self.dataSource numberOfYearsInDayDatePickerView:self];
        }
        else {
            numberOfRows = 2;
        }
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.font = [UIFont systemFontOfSize:17.0];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.backgroundColor = [UIColor whiteColor];
    
    DayDatePickerViewColumnType columType = DayDatePickerViewColumnTypeDay;
    BOOL disabled = NO;
    
    NSDateComponents *minimumDateComponents = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.minimumDate];
    NSDateComponents *dateComponents = [self.components copy];
    
    if(tableView == self.daysTableView) {
        dateComponents.day = indexPath.row + 1;
        NSDate *date = [self.calendar dateFromComponents:dateComponents];
        cell.textLabel.text = [[self.dayDateFormatter stringFromDate:date] stringByAppendingString:[self daySuffixForDate:date]];
        
        if(dateComponents.day < minimumDateComponents.day && dateComponents.month <= minimumDateComponents.month && dateComponents.year <= minimumDateComponents.year) {
            disabled = YES;
        }
        columType = DayDatePickerViewColumnTypeDay;
    }
    else if(tableView == self.monthsTableView) {
        dateComponents.month = indexPath.row + 1;
        NSDate *date = [self.calendar dateFromComponents:dateComponents];
        cell.textLabel.text = [self.monthDateFormatter stringFromDate:date];
        
        if(dateComponents.month < minimumDateComponents.month && dateComponents.year <= minimumDateComponents.year) {
            disabled = YES;
        }
        columType = DayDatePickerViewColumnTypeDay;
    }
    else if(tableView == self.yearsTableView) {
        dateComponents.year += indexPath.row;
        NSDate *date = [self.calendar dateFromComponents:dateComponents];
        cell.textLabel.text = [self.yearDateFormatter stringFromDate:date];
        
        if(dateComponents.year < minimumDateComponents.year) {
            disabled = YES;
        }
        columType = DayDatePickerViewColumnTypeDay;
    }
    
    if([self.delegate respondsToSelector:@selector(dayDatePickerView:fontForRow:inColumn:disabled:)]) {
        cell.textLabel.font = [self.delegate dayDatePickerView:self fontForRow:indexPath.row inColumn:columType disabled:disabled];
    }
    
    if([self.delegate respondsToSelector:@selector(dayDatePickerView:textColorForRow:inColumn:disabled:)]) {
        cell.textLabel.textColor = [self.delegate dayDatePickerView:self textColorForRow:indexPath.row inColumn:columType disabled:disabled];
    }
    else if(disabled) {
        cell.textLabel.textColor = [UIColor lightGrayColor];
    }
    
    if([self.delegate respondsToSelector:@selector(dayDatePickerView:backgroundColorForRow:inColumn:)]) {
        cell.backgroundColor = [self.delegate dayDatePickerView:self backgroundColorForRow:indexPath.row inColumn:columType];
    }
    
    return cell;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self alignTableViewToRowBoundary:(UITableView *)scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self alignTableViewToRowBoundary:(UITableView *)scrollView];
}

- (void)alignTableViewToRowBoundary:(UITableView *)tableView {
    const CGPoint relativeOffset = CGPointMake(0, tableView.contentOffset.y + tableView.contentInset.top);
    const NSUInteger row = round(relativeOffset.y / tableView.rowHeight);
    
    [self selectRow:row inTableView:tableView animated:YES updateComponents:YES];
}

- (void)selectRow:(NSInteger)row inTableView:(UITableView *)tableView animated:(BOOL)animated updateComponents:(BOOL)updateComponents {
    const CGPoint alignedOffset = CGPointMake(0, row * tableView.rowHeight - tableView.contentInset.top);
    [tableView setContentOffset:alignedOffset animated:animated];
    
    if(updateComponents) {
        if(tableView == self.daysTableView) {
            self.components.day = row + 1;
        }
        else if(tableView == self.monthsTableView) {
            self.components.month = row + 1;
        }
        else if(tableView == self.yearsTableView) {
            self.components.year = [self.calendar component:NSCalendarUnitYear fromDate:self.minimumDate];
            if(row == 1) {
                self.components.year++;
            }
        }
        
        self.date = [self.calendar dateFromComponents:self.components];
        [self.daysTableView reloadData];
    }
}

- (void)reload {
    [self.daysTableView reloadData];
    [self.monthsTableView reloadData];
    [self.yearsTableView reloadData];
}

- (NSDateFormatter *)dayDateFormatter {
    if(!_dayDateFormatter) {
        _dayDateFormatter = [[NSDateFormatter alloc]init];
        _dayDateFormatter.dateFormat = @"EEE d";
    }
    return _dayDateFormatter;
}

- (void)setDayDateFormatter:(NSDateFormatter *)dayDateFormatter {
    _dayDateFormatter = dayDateFormatter;
    [self.daysTableView reloadData];
}

- (NSDateFormatter *)monthDateFormatter {
    if(!_monthDateFormatter) {
        _monthDateFormatter = [[NSDateFormatter alloc]init];
        _monthDateFormatter.dateFormat = @"MMM";
    }
    return _monthDateFormatter;
}

- (void)setMonthDateFormatter:(NSDateFormatter *)monthDateFormatter {
    _monthDateFormatter = monthDateFormatter;
    [self.monthsTableView reloadData];
}

- (NSDateFormatter *)yearDateFormatter {
    if(!_yearDateFormatter) {
        _yearDateFormatter = [[NSDateFormatter alloc]init];
        _yearDateFormatter.dateFormat = @"yyyy";
    }
    return _yearDateFormatter;
}

- (void)setYearDateFormatter:(NSDateFormatter *)yearDateFormatter {
    _yearDateFormatter = yearDateFormatter;
    [self.yearsTableView reloadData];
}

- (void)setCalendar:(NSCalendar *)calendar {
    _calendar = calendar;
    [self reload];
}

@end
