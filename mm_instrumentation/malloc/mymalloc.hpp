struct mem_info {
    size_t realbytes;
    long creation_time;
    size_t creation_heap_size;
    std::string annotation;
};

static long cycle_clock = 0;

void mx_noop();
void* interpose_function();
void* malloc(size_t);
void free(void*);

void* temp_calloc(size_t, size_t);
void* calloc(size_t, size_t);

// g++ will go crazy if we add this in and talk about a mystery exception
// void* realloc(void*, size_t);
