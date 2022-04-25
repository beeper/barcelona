#import <CommunicationsFilter/CommunicationFilterItem.h>
#import <CommunicationsFilter/CommunicationFilterItemCache.h>
#import <CommunicationsFilter/CommunicationsFilterBlockList.h>
#import <CommunicationsFilter/CommunicationsFilterBlockListCache.h>

CommunicationFilterItem* CreateCMFItemFromString(NSString*);
Boolean CMFBlockListIsItemBlocked(CommunicationFilterItem* item);
NSString* CMFBlockListUpdatedNotification;
void CMFBlockListCopyItemsForAllServicesService(CFArrayRef * items);
