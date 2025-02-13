#pragma once

extern "C" {
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/avutil.h>
}

#include <atomic>
#include <cassert>
#include <mutex>
#include <string>
#include <thread>
#include <unordered_set>

#include <cstdio>

#include "fs.cc"

#define BLOCK_SIZE 4096
#define INDEX_FILE "cache_index.bin"
#define DATA_FILE "cache_data.bin"

#define CACHE_MAX_SIZE_DIRECTORY                                               \
  1 * 1024 * 1024 * 1024 // 1 GiB max of audio stored

std::mutex CacheAvio_clean_cache_mutex;

std::mutex CacheAvio_opened_paths_mutex;
std::unordered_set<std::string> CacheAvio_opened_paths = {};

class CacheAvio {
private:
  bool has_been_open = false;

  int buffer_size = 4096;

  std::string file_url = "";

  std::string cache_directory = "";

  AVIOContext *source_avio_ctx = nullptr;
  AVIOContext *avio_ctx = nullptr;

  AVDictionary *options = NULL;

  int64_t fileTotalSize = 0;

  bool has_been_open_http = false;

  FILE *data_file;
  FILE *index_file;

  uint8_t *index_map;
  size_t index_size;
  size_t current_offset;

  bool IsBlockCached(size_t block_id) {
    size_t byte_index = block_id / 8;
    size_t bit_index = block_id % 8;
    if (byte_index >= index_size)
      return false;
    return (index_map[byte_index] >> bit_index) & 1;
  }

  void MarkBlockAsCached(size_t block_id) {
    size_t byte_index = block_id / 8;
    size_t bit_index = block_id % 8;

    if (byte_index >= index_size) {
      size_t new_size = byte_index + 1;
      index_map = (uint8_t *)realloc(index_map, new_size);
      memset(index_map + index_size, 0, new_size - index_size);
      index_size = new_size;
    }

    index_map[byte_index] |= (1 << bit_index);

    fseek(index_file, byte_index + sizeof(int64_t), SEEK_SET);
    fwrite(&index_map[byte_index], 1, 1, index_file);
    fflush(index_file);
  }

  int DownloadBlock(size_t block_id) {
    if (IsBlockCached(block_id)) {
      return 1;
    }

    int response = OpenHttp();
    if (response != 0) {
      return response;
    }

    uint8_t buffer[BLOCK_SIZE] = {0};

    size_t offset = block_id * BLOCK_SIZE;
    avio_seek(source_avio_ctx, offset, SEEK_SET);

    int bytes_read = avio_read(source_avio_ctx, buffer, BLOCK_SIZE);

    if (bytes_read == AVERROR_EOF) {
      MarkBlockAsCached(block_id);
      return 1;
    }

    if (bytes_read <= 0) {
      return bytes_read;
    }

    fseek(data_file, offset, SEEK_SET);
    fwrite(buffer, 1, bytes_read, data_file);
    fflush(data_file);

    MarkBlockAsCached(block_id);

    return 1;
  }

  static int CustomReadPacket(void *opaque, uint8_t *buf, int buf_size) {
    CacheAvio *cacheAvio = reinterpret_cast<CacheAvio *>(opaque);

    size_t start_block = cacheAvio->current_offset / BLOCK_SIZE;
    size_t end_block = (cacheAvio->current_offset + buf_size - 1) / BLOCK_SIZE;

    for (size_t block_id = start_block; block_id <= end_block; block_id++) {
      int result = cacheAvio->DownloadBlock(block_id);
      if (result <= 0) {
        return 0;
      }
    }

    fseek(cacheAvio->data_file, cacheAvio->current_offset, SEEK_SET);
    int bytes_read = fread(buf, 1, buf_size, cacheAvio->data_file);

    if (!bytes_read)
      return AVERROR_EOF;

    cacheAvio->current_offset += bytes_read;

    return bytes_read;
  }

  static int64_t CustomSeek(void *opaque, int64_t offset, int whence) {
    CacheAvio *cacheAvio = reinterpret_cast<CacheAvio *>(opaque);

    size_t new_offset;

    if (whence == SEEK_SET) {
      new_offset = offset;
    } else if (whence == SEEK_CUR) {
      new_offset = cacheAvio->current_offset + offset;
    } else if (whence == SEEK_CUR) {
      new_offset = cacheAvio->fileTotalSize - offset;
    } else if (whence == AVSEEK_SIZE) {
      return cacheAvio->fileTotalSize;
    } else {
      return -1;
    }

    cacheAvio->current_offset = new_offset;
    return 0;
  }

  // av_err2str returns a temporary array. This doesn't work in gcc.
  // This function can be used as a replacement for av_err2str.
  static const char *GetError(int errnum) {
    static char str[AV_ERROR_MAX_STRING_SIZE];
    memset(str, 0, sizeof(str));
    return av_make_error_string(str, AV_ERROR_MAX_STRING_SIZE, errnum);
  }

  int OpenHttp() {
    if (has_been_open_http) {
      return 0;
    }

    AVDictionary *loptions = NULL;
    av_dict_copy(&loptions, options, 0);

    int response = avio_open2(&source_avio_ctx, file_url.c_str(),
                              AVIO_FLAG_READ, NULL, &loptions);
    if (response < 0) {
      fprintf(stderr, "Could not open AVIOContext: %s\n", GetError(response));
      return -1;
    }
    has_been_open_http = true;
    return 0;
  }

  void CloseHttp() {
    if (!has_been_open_http) {
      return;
    }
    avio_closep(&source_avio_ctx);
    has_been_open_http = false;
  }

public:
  CacheAvio() {}

  ~CacheAvio() { FreeCache(); }

  AVIOContext *GetAvioCtx() { return avio_ctx; }

  int Init(const std::string &cache_path, const std::string &cache_key,
           const std::string &url, AVDictionary **new_options) {
    if (has_been_open) {
      return 0;
    }

    file_url = url;

    av_dict_copy(&options, *new_options, 0);

    cache_directory = join(cache_path, sanitizeForPath(cache_key));

    createDirectoryRecursive(cache_directory);

    data_file = fopen(join(cache_directory, DATA_FILE).c_str(), "rb+");
    if (!data_file)
      data_file = fopen(join(cache_directory, DATA_FILE).c_str(), "wb+");

    if (!data_file)
      return -1;

    index_file = fopen(join(cache_directory, INDEX_FILE).c_str(), "rb+");
    if (!index_file)
      index_file = fopen(join(cache_directory, INDEX_FILE).c_str(), "wb+");

    if (!index_file)
      return -1;

    touch(join(cache_directory, INDEX_FILE));

    CacheAvio_opened_paths_mutex.lock();
    CacheAvio_opened_paths.insert(join(cache_directory, INDEX_FILE));
    CacheAvio_opened_paths_mutex.unlock();

    CacheAvio::CheckAndCleanOldCaches(cache_path,
                                      join(cache_directory, INDEX_FILE));

    fseek(index_file, 0, SEEK_END);
    index_size = ftell(index_file);
    rewind(index_file);

    int response = 0;

    if (index_size >= 8) {
      response = fread(&fileTotalSize, sizeof(int64_t), 1, index_file);
      if (response <= 0) {
        return -1;
      }
      index_size -= fread(&fileTotalSize, sizeof(int64_t), 1, index_file);
    } else {
      response = OpenHttp();
      if (response != 0) {
        return response;
      }

      fileTotalSize = avio_size(source_avio_ctx);
      fwrite(&fileTotalSize, sizeof(int64_t), 1, index_file);
    }

    index_map = (uint8_t *)malloc(index_size);
    response = fread(index_map, 1, index_size, index_file);

    if (response < 0) {
      return -1;
    }

    current_offset = 0;

    uint8_t *buffer = reinterpret_cast<uint8_t *>(av_malloc(buffer_size));
    if (!buffer) {
      CloseHttp();
      return -1;
    }

    avio_ctx = avio_alloc_context(buffer, buffer_size, 0, this,
                                  &CacheAvio::CustomReadPacket, NULL,
                                  &CacheAvio::CustomSeek);
    if (!avio_ctx) {
      av_freep(&buffer);
      CloseHttp();

      fprintf(stderr, "Could not open custom AVIOContext\n");
      return -1;
    }

    has_been_open = true;
    return 0;
  }

  void FreeCache() {
    if (!has_been_open) {
      return;
    }

    uint8_t *buffer = avio_ctx->buffer;

    avio_context_free(&avio_ctx);
    CloseHttp();

    av_freep(&buffer);

    fclose(data_file);
    fclose(index_file);
    free(index_map);

    CacheAvio_opened_paths_mutex.lock();
    CacheAvio_opened_paths.erase(join(cache_directory, INDEX_FILE));
    CacheAvio_opened_paths_mutex.unlock();

    has_been_open = false;
  }

  static void CheckAndCleanOldCaches(const std::string &cachePath,
                                     const std::string &protectedCacheIndex) {
    std::unique_lock<std::mutex> lock(CacheAvio_clean_cache_mutex);

    int64_t folderSize = getDirectorySize(cachePath);

    CacheAvio_opened_paths_mutex.lock();

    while (folderSize >= CACHE_MAX_SIZE_DIRECTORY) {
      std::string oldestPath = findOldestFileByName(cachePath, INDEX_FILE);

      if (CacheAvio_opened_paths.find(oldestPath) !=
          CacheAvio_opened_paths.end()) {
        CacheAvio_opened_paths_mutex.unlock();
        return;
      }

      std::string directoryToDelete = getParentPath(oldestPath);

      removeDirectoryRecursive(directoryToDelete);

      folderSize = getDirectorySize(cachePath);
    }

    CacheAvio_opened_paths_mutex.unlock();
  }
};
