//
//  RunnerClasses+Reverse.m
//  OCRunner
//
//  Created by Jiang on 2021/2/1.
//

#import "RunnerClasses+Reverse.h"
#import "MFScopeChain.h"
#import "util.h"
#import "MFMethodMapTable.h"
#import "MFPropertyMapTable.h"
#import "MFVarDeclareChain.h"
#import "MFBlock.h"
#import "MFValue.h"
#import "MFStaticVarTable.h"
#import "ORStructDeclare.h"
#import <objc/message.h>
#import "ORTypeVarPair+TypeEncode.h"
#import "ORCoreImp.h"
#import "ORSearchedFunction.h"
void reverse_method(BOOL isClassMethod, Class clazz, SEL sel){
    NSString *orgSelName = [NSString stringWithFormat:@"ORG%@",NSStringFromSelector(sel)];
    SEL orgsel = NSSelectorFromString(orgSelName);
    Method ocMethod;
    if (isClassMethod) {
        ocMethod = class_getClassMethod(clazz, orgsel);
    }else{
        ocMethod = class_getInstanceMethod(clazz, orgsel);
    }
    const char *typeEncoding = method_getTypeEncoding(ocMethod);
    Class c2 = isClassMethod ? objc_getMetaClass(class_getName(clazz)) : clazz;
    IMP orgImp = class_getMethodImplementation(c2, orgsel);
    class_replaceMethod(c2, sel, orgImp, typeEncoding);
}

@implementation ORNode (Reverse)
- (void)reverse{
    
}
@end

@implementation ORClass (Reverse)
- (void)reverse{
    BOOL isRegisterClass = NO;
    MFValue *classValue = [[MFScopeChain topScope] recursiveGetValueWithIdentifier:self.className];
    Class classVar = classValue.classValue;
    Class class = NSClassFromString(self.className);
    if (classVar != nil && classVar == class) {
        isRegisterClass = YES;
    }
    // FIXME: Reverse时，释放ffi_closure和ffi_type
    for (ORMethodImplementation *imp in self.methods) {
        SEL sel = NSSelectorFromString(imp.declare.selectorName);
        BOOL isClassMethod = imp.declare.isClassMethod;
        reverse_method(isClassMethod, class, sel);
        CFRelease((__bridge CFTypeRef)(imp));
    }
    for (ORPropertyDeclare *prop in self.properties){
        NSString *name = prop.var.var.varname;
        NSString *str1 = [[name substringWithRange:NSMakeRange(0, 1)] uppercaseString];
        NSString *str2 = name.length > 1 ? [name substringFromIndex:1] : nil;
        SEL getterSEL = NSSelectorFromString(name);
        SEL setterSEL = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",str1,str2]);
        reverse_method(NO, class, getterSEL);
        reverse_method(NO, class, setterSEL);
        CFRelease((__bridge CFTypeRef)(prop));
    }
    [[MFMethodMapTable shareInstance] removeMethodsForClass:class];
    [[MFPropertyMapTable shareInstance] removePropertiesForClass:class];
    if (isRegisterClass) {
        objc_disposeClassPair(class);
    }
}

@end


