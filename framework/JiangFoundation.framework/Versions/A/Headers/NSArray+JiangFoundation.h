@interface NSArray (JiangFoundation)

/* Override behavior */

- (NSString *)description;

/* Additional behavior */

- (void)each:(void (^)(id))block;

/* Functional programming */

- (NSArray *)collect:(id (^)(id))block;
- (NSArray *)map:(id (^)(id))block;
- (NSArray *)select:(BOOL (^)(id))block;

/* Syntax suger */

- (NSArray *)reverse;
- (NSString *)join:(NSString *)sep;

@end
