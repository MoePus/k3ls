#define SHADOW_QUALITY 4

#define CasterAlphaThreshold 180
#define RecieverAlphaThreshold 0.4

#if SHADOW_QUALITY == 1
#   define SHADOW_MAP_SIZE 2048
#elif SHADOW_QUALITY == 2
#   define SHADOW_MAP_SIZE 4096
#elif SHADOW_QUALITY == 3
#   define SHADOW_MAP_SIZE 6144
#elif SHADOW_QUALITY == 4
#   define SHADOW_MAP_SIZE 8192
#else
#   define SHADOW_MAP_SIZE 10000
#endif