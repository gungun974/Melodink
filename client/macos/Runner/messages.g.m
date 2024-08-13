// Autogenerated from Pigeon (v21.1.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#import "messages.g.h"

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

#if !__has_feature(objc_arc)
#error File requires ARC to be enabled.
#endif

static NSArray<id> *wrapResult(id result, FlutterError *error) {
  if (error) {
    return @[
      error.code ?: [NSNull null], error.message ?: [NSNull null], error.details ?: [NSNull null]
    ];
  }
  return @[ result ?: [NSNull null] ];
}

static FlutterError *createConnectionError(NSString *channelName) {
  return [FlutterError errorWithCode:@"channel-error" message:[NSString stringWithFormat:@"%@/%@/%@", @"Unable to establish connection on channel: '", channelName, @"'."] details:@""];
}

static id GetNullableObjectAtIndex(NSArray<id> *array, NSInteger key) {
  id result = array[key];
  return (result == [NSNull null]) ? nil : result;
}

@implementation PGNMelodinkHostPlayerProcessingStateBox
- (instancetype)initWithValue:(PGNMelodinkHostPlayerProcessingState)value {
  self = [super init];
  if (self) {
    _value = value;
  }
  return self;
}
@end

@implementation PGNMelodinkHostPlayerLoopModeBox
- (instancetype)initWithValue:(PGNMelodinkHostPlayerLoopMode)value {
  self = [super init];
  if (self) {
    _value = value;
  }
  return self;
}
@end

@interface PGNPlayerStatus ()
+ (PGNPlayerStatus *)fromList:(NSArray<id> *)list;
+ (nullable PGNPlayerStatus *)nullableFromList:(NSArray<id> *)list;
- (NSArray<id> *)toList;
@end

@implementation PGNPlayerStatus
+ (instancetype)makeWithPlaying:(BOOL )playing
    pos:(NSInteger )pos
    positionMs:(NSInteger )positionMs
    bufferedPositionMs:(NSInteger )bufferedPositionMs
    state:(PGNMelodinkHostPlayerProcessingState)state
    loop:(PGNMelodinkHostPlayerLoopMode)loop {
  PGNPlayerStatus* pigeonResult = [[PGNPlayerStatus alloc] init];
  pigeonResult.playing = playing;
  pigeonResult.pos = pos;
  pigeonResult.positionMs = positionMs;
  pigeonResult.bufferedPositionMs = bufferedPositionMs;
  pigeonResult.state = state;
  pigeonResult.loop = loop;
  return pigeonResult;
}
+ (PGNPlayerStatus *)fromList:(NSArray<id> *)list {
  PGNPlayerStatus *pigeonResult = [[PGNPlayerStatus alloc] init];
  pigeonResult.playing = [GetNullableObjectAtIndex(list, 0) boolValue];
  pigeonResult.pos = [GetNullableObjectAtIndex(list, 1) integerValue];
  pigeonResult.positionMs = [GetNullableObjectAtIndex(list, 2) integerValue];
  pigeonResult.bufferedPositionMs = [GetNullableObjectAtIndex(list, 3) integerValue];
  PGNMelodinkHostPlayerProcessingStateBox *enumBox = GetNullableObjectAtIndex(list, 4);
  pigeonResult.state = enumBox.value;
  PGNMelodinkHostPlayerLoopModeBox *enumBox = GetNullableObjectAtIndex(list, 5);
  pigeonResult.loop = enumBox.value;
  return pigeonResult;
}
+ (nullable PGNPlayerStatus *)nullableFromList:(NSArray<id> *)list {
  return (list) ? [PGNPlayerStatus fromList:list] : nil;
}
- (NSArray<id> *)toList {
  return @[
    @(self.playing),
    @(self.pos),
    @(self.positionMs),
    @(self.bufferedPositionMs),
    [[PGNMelodinkHostPlayerProcessingStateBox alloc] initWithValue:self.state],
    [[PGNMelodinkHostPlayerLoopModeBox alloc] initWithValue:self.loop],
  ];
}
@end

@interface PGNMessagesPigeonCodecReader : FlutterStandardReader
@end
@implementation PGNMessagesPigeonCodecReader
- (nullable id)readValueOfType:(UInt8)type {
  switch (type) {
    case 129: 
      return [PGNPlayerStatus fromList:[self readValue]];
    case 130: 
      {
        NSNumber *enumAsNumber = [self readValue];
        return enumAsNumber == nil ? nil : [[PGNMelodinkHostPlayerProcessingStateBox alloc] initWithValue:[enumAsNumber integerValue]];
      }
    case 131: 
      {
        NSNumber *enumAsNumber = [self readValue];
        return enumAsNumber == nil ? nil : [[PGNMelodinkHostPlayerLoopModeBox alloc] initWithValue:[enumAsNumber integerValue]];
      }
    default:
      return [super readValueOfType:type];
  }
}
@end

@interface PGNMessagesPigeonCodecWriter : FlutterStandardWriter
@end
@implementation PGNMessagesPigeonCodecWriter
- (void)writeValue:(id)value {
  if ([value isKindOfClass:[PGNPlayerStatus class]]) {
    [self writeByte:129];
    [self writeValue:[value toList]];
  } else if ([value isKindOfClass:[PGNMelodinkHostPlayerProcessingStateBox class]]) {
    PGNMelodinkHostPlayerProcessingStateBox * box = (PGNMelodinkHostPlayerProcessingStateBox *)value;
    [self writeByte:130];
    [self writeValue:(value == nil ? [NSNull null] : [NSNumber numberWithInteger:box.value])];
  } else if ([value isKindOfClass:[PGNMelodinkHostPlayerLoopModeBox class]]) {
    PGNMelodinkHostPlayerLoopModeBox * box = (PGNMelodinkHostPlayerLoopModeBox *)value;
    [self writeByte:131];
    [self writeValue:(value == nil ? [NSNull null] : [NSNumber numberWithInteger:box.value])];
  } else {
    [super writeValue:value];
  }
}
@end

@interface PGNMessagesPigeonCodecReaderWriter : FlutterStandardReaderWriter
@end
@implementation PGNMessagesPigeonCodecReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
  return [[PGNMessagesPigeonCodecWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
  return [[PGNMessagesPigeonCodecReader alloc] initWithData:data];
}
@end

NSObject<FlutterMessageCodec> *PGNGetMessagesCodec(void) {
  static FlutterStandardMessageCodec *sSharedObject = nil;
  static dispatch_once_t sPred = 0;
  dispatch_once(&sPred, ^{
    PGNMessagesPigeonCodecReaderWriter *readerWriter = [[PGNMessagesPigeonCodecReaderWriter alloc] init];
    sSharedObject = [FlutterStandardMessageCodec codecWithReaderWriter:readerWriter];
  });
  return sSharedObject;
}
void SetUpPGNMelodinkHostPlayerApi(id<FlutterBinaryMessenger> binaryMessenger, NSObject<PGNMelodinkHostPlayerApi> *api) {
  SetUpPGNMelodinkHostPlayerApiWithSuffix(binaryMessenger, api, @"");
}

void SetUpPGNMelodinkHostPlayerApiWithSuffix(id<FlutterBinaryMessenger> binaryMessenger, NSObject<PGNMelodinkHostPlayerApi> *api, NSString *messageChannelSuffix) {
  messageChannelSuffix = messageChannelSuffix.length > 0 ? [NSString stringWithFormat: @".%@", messageChannelSuffix] : @"";
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.play", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(playWithError:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(playWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        [api playWithError:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.pause", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(pauseWithError:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(pauseWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        [api pauseWithError:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.seek", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(seekPositionMs:error:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(seekPositionMs:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray<id> *args = message;
        NSInteger arg_positionMs = [GetNullableObjectAtIndex(args, 0) integerValue];
        FlutterError *error;
        [api seekPositionMs:arg_positionMs error:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.skipToNext", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(skipToNextWithError:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(skipToNextWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        [api skipToNextWithError:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.skipToPrevious", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(skipToPreviousWithError:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(skipToPreviousWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        [api skipToPreviousWithError:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.setAudios", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(setAudiosPreviousUrls:nextUrls:error:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(setAudiosPreviousUrls:nextUrls:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray<id> *args = message;
        NSArray<NSString *> *arg_previousUrls = GetNullableObjectAtIndex(args, 0);
        NSArray<NSString *> *arg_nextUrls = GetNullableObjectAtIndex(args, 1);
        FlutterError *error;
        [api setAudiosPreviousUrls:arg_previousUrls nextUrls:arg_nextUrls error:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.setLoopMode", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(setLoopModeLoop:error:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(setLoopModeLoop:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray<id> *args = message;
        PGNMelodinkHostPlayerLoopModeBox *enumBox = GetNullableObjectAtIndex(args, 0);
        PGNMelodinkHostPlayerLoopMode arg_loop = enumBox.value;
        FlutterError *error;
        [api setLoopModeLoop:arg_loop error:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApi.fetchStatus", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:PGNGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(fetchStatusWithError:)], @"PGNMelodinkHostPlayerApi api (%@) doesn't respond to @selector(fetchStatusWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        PGNPlayerStatus *output = [api fetchStatusWithError:&error];
        callback(wrapResult(output, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
}
@interface PGNMelodinkHostPlayerApiInfo ()
@property(nonatomic, strong) NSObject<FlutterBinaryMessenger> *binaryMessenger;
@property(nonatomic, strong) NSString *messageChannelSuffix;
@end

@implementation PGNMelodinkHostPlayerApiInfo

- (instancetype)initWithBinaryMessenger:(NSObject<FlutterBinaryMessenger> *)binaryMessenger {
  return [self initWithBinaryMessenger:binaryMessenger messageChannelSuffix:@""];
}
- (instancetype)initWithBinaryMessenger:(NSObject<FlutterBinaryMessenger> *)binaryMessenger messageChannelSuffix:(nullable NSString*)messageChannelSuffix{
  self = [self init];
  if (self) {
    _binaryMessenger = binaryMessenger;
    _messageChannelSuffix = [messageChannelSuffix length] == 0 ? @"" : [NSString stringWithFormat: @".%@", messageChannelSuffix];
  }
  return self;
}
- (void)audioChangedPos:(NSInteger)arg_pos completion:(void (^)(FlutterError *_Nullable))completion {
  NSString *channelName = [NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApiInfo.audioChanged", _messageChannelSuffix];
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:channelName
      binaryMessenger:self.binaryMessenger
      codec:PGNGetMessagesCodec()];
  [channel sendMessage:@[@(arg_pos)] reply:^(NSArray<id> *reply) {
    if (reply != nil) {
      if (reply.count > 1) {
        completion([FlutterError errorWithCode:reply[0] message:reply[1] details:reply[2]]);
      } else {
        completion(nil);
      }
    } else {
      completion(createConnectionError(channelName));
    } 
  }];
}
- (void)updateStateState:(PGNMelodinkHostPlayerProcessingState)arg_state completion:(void (^)(FlutterError *_Nullable))completion {
  NSString *channelName = [NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.pigeon_melodink.MelodinkHostPlayerApiInfo.updateState", _messageChannelSuffix];
  FlutterBasicMessageChannel *channel =
    [FlutterBasicMessageChannel
      messageChannelWithName:channelName
      binaryMessenger:self.binaryMessenger
      codec:PGNGetMessagesCodec()];
  [channel sendMessage:@[[[PGNMelodinkHostPlayerProcessingStateBox alloc] initWithValue:arg_state]] reply:^(NSArray<id> *reply) {
    if (reply != nil) {
      if (reply.count > 1) {
        completion([FlutterError errorWithCode:reply[0] message:reply[1] details:reply[2]]);
      } else {
        completion(nil);
      }
    } else {
      completion(createConnectionError(channelName));
    } 
  }];
}
@end

