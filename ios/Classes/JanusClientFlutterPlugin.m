#import "JanusClientFlutterPlugin.h"
#if __has_include(<janus_client_flutter/janus_client_flutter-Swift.h>)
#import <janus_client_flutter/janus_client_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "janus_client_flutter-Swift.h"
#endif

@implementation JanusClientFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftJanusClientFlutterPlugin registerWithRegistrar:registrar];
}
@end
