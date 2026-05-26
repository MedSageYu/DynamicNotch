// MediaRemote C Wrapper — 避免 Swift unsafeBitCast 签名不确定性

#include <dlfcn.h>
#include <dispatch/dispatch.h>
#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef void (*MRGetNowPlayingInfoFn)(dispatch_queue_t, void (^)(CFDictionaryRef));
typedef Boolean (*MRSendCommandFn)(unsigned int, CFDictionaryRef);

static MRGetNowPlayingInfoFn _mrGetNowPlayingInfo = NULL;
static MRSendCommandFn _mrSendCommand = NULL;

static void ensureLoaded(void) {
    static bool loaded = false;
    if (loaded) return;
    void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_LAZY);
    if (h == NULL) return;
    _mrGetNowPlayingInfo = (MRGetNowPlayingInfoFn)dlsym(h, "MRMediaRemoteGetNowPlayingInfo");
    _mrSendCommand = (MRSendCommandFn)dlsym(h, "MRMediaRemoteSendCommand");
    loaded = true;
}

/// 获取当前播放信息，返回 JSON 字符串（由调用方 free）
/// 格式: {"title":"...","artist":"...","album":"...","playing":true/false}
/// 或无播放时返回 NULL
char *dni_get_now_playing_json(void) {
    ensureLoaded();
    if (!_mrGetNowPlayingInfo) return NULL;

    __block char *result = NULL;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    _mrGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef info) {
        if (info) {
            CFStringRef title   = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoTitle"));
            CFStringRef artist  = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoArtist"));
            CFStringRef album   = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoAlbum"));
            CFNumberRef rate    = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoPlaybackRate"));
            CFDataRef artData   = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoArtworkData"));
            // also try MRContentItem artwork data
            if (!artData) {
                CFDictionaryRef ci = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoContentItem"));
                if (ci) artData = CFDictionaryGetValue(ci, CFSTR("kMRMediaRemoteNowPlayingInfoArtworkData"));
            }

            char titleStr[512] = "", artistStr[512] = "", albumStr[512] = "", artB64[65536] = "";
            if (title)  CFStringGetCString(title, titleStr, sizeof(titleStr), kCFStringEncodingUTF8);
            if (artist) CFStringGetCString(artist, artistStr, sizeof(artistStr), kCFStringEncodingUTF8);
            if (album)  CFStringGetCString(album, albumStr, sizeof(albumStr), kCFStringEncodingUTF8);

            // Base64-encode artwork data
            if (artData) {
                CFIndex len = CFDataGetLength(artData);
                const UInt8 *bytes = CFDataGetBytePtr(artData);
                static const char b64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
                size_t outPos = 0;
                for (CFIndex i = 0; i < len && outPos < sizeof(artB64) - 5; i += 3) {
                    UInt8 a = bytes[i];
                    UInt8 b = (i+1 < len) ? bytes[i+1] : 0;
                    UInt8 c = (i+2 < len) ? bytes[i+2] : 0;
                    artB64[outPos++] = b64[a >> 2];
                    artB64[outPos++] = b64[((a & 3) << 4) | (b >> 4)];
                    artB64[outPos++] = (i+1 < len) ? b64[((b & 15) << 2) | (c >> 6)] : '=';
                    artB64[outPos++] = (i+2 < len) ? b64[c & 63] : '=';
                }
                artB64[outPos] = '\0';
            }

            double rateVal = 0;
            if (rate) CFNumberGetValue(rate, kCFNumberDoubleType, &rateVal);

            size_t bufSize = 4096 + sizeof(artB64);
            result = (char *)malloc(bufSize);
            snprintf(result, bufSize,
                "{\"title\":\"%s\",\"artist\":\"%s\",\"album\":\"%s\",\"playing\":%s,\"artwork\":\"%s\"}",
                titleStr, artistStr, albumStr,
                rateVal > 0 ? "true" : "false",
                artB64);
        }
        dispatch_semaphore_signal(sem);
    });

    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, 2LL * NSEC_PER_SEC));
    return result;
}

/// 发送媒体控制命令
void dni_send_command(unsigned int cmd) {
    ensureLoaded();
    if (_mrSendCommand) _mrSendCommand(cmd, NULL);
}