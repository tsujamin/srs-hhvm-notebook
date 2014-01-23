#include <cstdio>
#include <iostream>

#include <dlfcn.h>

#include "mymalloc.hpp"

void mx_noop() {
    fprintf(stderr, "How did I get here?\n");
}

void* interpose(const char* name) {
    void* f = dlsym(RTLD_NEXT, name);
    if (nullptr == f) {
        fprintf(stderr, "Error in `dlsym`: %s\n", dlerror());
    }
    return f;
}

void* malloc(size_t size) {
    static void* (*real_malloc)(size_t);
    if (!real_malloc) {
        real_malloc = reinterpret_cast<void* (*)(size_t)>(interpose("malloc"));
    }

    void *p = real_malloc(size);
    fprintf(stderr, "malloc(%ld) to %p\n", size, p);
    return p;
}

void free(void* ptr) {
    static void* (*real_free)(void*);
    if (!real_free) {
        real_free = reinterpret_cast<void* (*)(void*)>(interpose("free"));
    }

    fprintf(stderr, "free at %p\n", ptr);
    real_free(ptr);
}

void* temp_calloc(size_t, size_t) {
    return nullptr;
}

void* calloc(size_t nmemb, size_t size) {
    static void* (*real_calloc)(size_t, size_t);
    printf("Entering calloc\n");

    if (!real_calloc) {
        // set calloc to a nulling function. dlsym won't complain.
        real_calloc = temp_calloc;
        real_calloc = (void *(*)(size_t, size_t)) dlsym(RTLD_NEXT, "calloc");
    }

    void* ret = real_calloc(nmemb, size);

    return ret;
}

void* realloc(void* ptr, size_t size) {
    static void* (*real_realloc)(void*, size_t);
    if (!real_realloc) {
        real_realloc = reinterpret_cast<void* (*)(void*, size_t)>(interpose("realloc"));
    }
    void* retptr = real_realloc(ptr, size);
    fprintf(stderr, "realloc(%ld) from %p to %p\n", size, ptr, retptr);
    return retptr;
}
