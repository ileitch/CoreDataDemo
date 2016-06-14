@protocol TTIndexPathTranslationDelegate <NSObject>
@optional
- (NSIndexPath *)translatedIndexPathWithIndexPath:(NSIndexPath *)indexPath;

@end
