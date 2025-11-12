#include <stdlib.h>
#include <string.h>

// Include the full stb headers placed alongside this file.
// You must add the three header files in the same folder:
//  - stb_image.h
//  - stb_image_resize.h
//  - stb_image_write.h
// These are the official single-file headers from https://github.com/nothings/stb
// with their STB_..._IMPLEMENTATION macros defined at the top of each file.

#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

#define STB_IMAGE_RESIZE_IMPLEMENTATION
#include "stb_image_resize2.h"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

// Decode PNG/JPEG into RGBA8
// Returns malloc'd buffer of size width*height*4. Caller frees via free().
unsigned char* decode_to_rgba(const unsigned char* bytes, int length, int* out_w, int* out_h) {
    int w = 0, h = 0, comp = 0;
    unsigned char* data = stbi_load_from_memory(bytes, length, &w, &h, &comp, 4);
    if (!data) return NULL;
    *out_w = w;
    *out_h = h;
    return data;
}

// Resize RGBA8 using high-quality resampling
// Returns malloc'd buffer of size new_w*new_h*4. Caller frees via free().
unsigned char* resize_rgba(const unsigned char* src, int src_w, int src_h, int new_w, int new_h) {
    unsigned char* out = (unsigned char*)malloc(new_w * new_h * 4);
    if (!out) return NULL;
    int ok = stbir_resize_uint8_linear(src, src_w, src_h, 0, out, new_w, new_h, 0, 4);
    if (!ok) {
        free(out);
        return NULL;
    }
    return out;
}

// Encode RGBA8 to PNG
// Returns malloc'd buffer with PNG data and sets out_len. Caller frees via free().
unsigned char* encode_png(const unsigned char* rgba, int w, int h, int* out_len) {
    unsigned char* png = NULL;
    int len = 0;
    png = stbi_write_png_to_mem(rgba, w * 4, w, h, 4, &len);
    if (!png) return NULL;
    *out_len = len;
    return png;
}
