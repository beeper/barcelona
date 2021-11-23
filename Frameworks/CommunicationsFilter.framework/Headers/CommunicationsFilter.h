#import <CommunicationsFilter/CommunicationFilterItem.h>
#import <CommunicationsFilter/CommunicationFilterItemCache.h>
#import <CommunicationsFilter/CommunicationsFilterBlockList.h>
#import <CommunicationsFilter/CommunicationsFilterBlockListCache.h>

CommunicationFilterItem* CreateCMFItemFromString(NSString*);

NSString* CMFBlockListUpdatedNotification;
void CMFBlockListCopyItemsForAllServicesService(CFArrayRef * items);
