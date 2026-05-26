// mrhelper.c — MediaRemote 查询助手，输出 JSON
// 编译: clang -o mrhelper mrhelper.c -framework CoreFoundation -framework Foundation

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <dispatch/dispatch.h>
#include <CoreFoundation/CoreFoundation.h>
#include <os/log.h>   // ← 新增：os_log 诊断

typedef void (*MRGetNowPlayingFn)(dispatch_queue_t, void (^)(CFDictionaryRef));
typedef Boolean (*MRSendCommandFn)(unsigned int, CFDictionaryRef);

static MRGetNowPlayingFn fnGet = NULL;
static MRSendCommandFn fnSend = NULL;

__attribute__((constructor))
static void load(void) {
    void *h = dlopen("/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote", RTLD_NOW);
    if (!h) {
        os_log(OS_LOG_DEFAULT, "mrhelper: dlopen FAILED: %s", dlerror());
        return;
    }
    fnGet  = (MRGetNowPlayingFn)dlsym(h, "MRMediaRemoteGetNowPlayingInfo");
    fnSend = (MRSendCommandFn)dlsym(h, "MRMediaRemoteSendCommand");
    os_log(OS_LOG_DEFAULT, "mrhelper: dlopen OK, fnGet=%p, fnSend=%p", fnGet, fnSend);
}

static const char b64t[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static void b64encode(const UInt8 *bytes, CFIndex len, char *out, size_t outLen) {
    size_t p = 0;
    for (CFIndex i = 0; i < len && p < outLen - 4; i += 3) {
        UInt8 b0 = bytes[i], b1 = (i+1 < len) ? bytes[i+1] : 0, b2 = (i+2 < len) ? bytes[i+2] : 0;
        out[p++] = b64t[b0 >> 2];
        out[p++] = b64t[((b0 & 3) << 4) | (b1 >> 4)];
        out[p++] = (i+1 < len) ? b64t[((b1 & 15) << 2) | (b2 >> 6)] : '=';
        out[p++] = (i+2 < len) ? b64t[b2 & 63] : '=';
    }
    out[p] = '\0';
}

static void jsonEscape(const char *src, char *dst, size_t dstLen) {
    const char *p = src;
    char *out = dst;
    while (*p && out - dst < (int)dstLen - 3) {
        if (*p == '"' || *p == '\\') { *out++ = '\\'; *out++ = *p++; }
        else if (*p == '\n') { *out++ = '\\'; *out++ = 'n'; p++; }
        else *out++ = *p++;
    }
    *out = 0;
}

int main(int argc, const char *argv[]) {
    if (argc < 2) {
        if (!fnGet) { printf("{}\n"); os_log(OS_LOG_DEFAULT, "mrhelper: fnGet is NULL, returning {}"); return 1; }

        char *title  = calloc(1024, 1);
        char *artist = calloc(1024, 1);
        char *album  = calloc(1024, 1);
        char *artB64 = calloc(196608, 1);
        __block double rate = 0;
        __block bool   done = false;
        __block CFAbsoluteTime t0 = CFAbsoluteTimeGetCurrent();

        os_log(OS_LOG_DEFAULT, "mrhelper: calling MRMediaRemoteGetNowPlayingInfo...");

        fnGet(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^(CFDictionaryRef info) {
            CFAbsoluteTime t1 = CFAbsoluteTimeGetCurrent();
            os_log(OS_LOG_DEFAULT, "mrhelper: callback fired after %.0fms, info=%p", (t1-t0)*1000, info);

            if (!info) { done = true; return; }

            CFStringRef t = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoTitle"));
            CFStringRef a = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoArtist"));
            CFStringRef al = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoAlbum"));
            CFNumberRef r = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoPlaybackRate"));
            CFDataRef   art = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoArtworkData"));
            if (!art) {
                CFDictionaryRef ci = CFDictionaryGetValue(info, CFSTR("kMRMediaRemoteNowPlayingInfoContentItem"));
                if (ci) art = CFDictionaryGetValue(ci, CFSTR("kMRMediaRemoteNowPlayingInfoArtworkData"));
            }

            if (t)  { CFStringGetCString(t, title, 1023, kCFStringEncodingUTF8); os_log(OS_LOG_DEFAULT, "mrhelper: title=%s", title); }
            if (a)  { CFStringGetCString(a, artist, 1023, kCFStringEncodingUTF8); }
            if (al) { CFStringGetCString(al, album, 1023, kCFStringEncodingUTF8); }
            if (r)  { CFNumberGetValue(r, kCFNumberDoubleType, &rate); }
            if (art) { b64encode(CFDataGetBytePtr(art), CFDataGetLength(art), artB64, 196607); os_log(OS_LOG_DEFAULT, "mrhelper: artwork %lu bytes", CFDataGetLength(art)); }

            done = true;
        });

        for (int i = 0; i < 100 && !done; i++) usleep(50000);

        if (!done) os_log(OS_LOG_DEFAULT, "mrhelper: TIMEOUT after 5s");

        if (title[0]) {
            char escT[2048] = "", escA[2048] = "", escAl[2048] = "";
            jsonEscape(title, escT, sizeof(escT));
            jsonEscape(artist, escA, sizeof(escA));
            jsonEscape(album, escAl, sizeof(escAl));
            printf("{\"title\":\"%s\",\"artist\":\"%s\",\"album\":\"%s\",\"playing\":%s,\"artwork\":\"%s\"}\n",
                   escT, escA, escAl, rate > 0 ? "true" : "false", artB64);
            os_log(OS_LOG_DEFAULT, "mrhelper: output JSON with title");
        } else {
            printf("{}\n");
            os_log(OS_LOG_DEFAULT, "mrhelper: no title, output {}");
        }

        free(title); free(artist); free(album); free(artB64);
        return 0;
    }
    else {
        if (fnSend) fnSend((unsigned int)atoi(argv[1]), NULL);
        return 0;
    }
}
