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

#include <cstdio>

#include "fs.cc"

#define BLOCK_SIZE 4096
#define INDEX_FILE "cache_index.bin"
#define DATA_FILE "cache_data.bin"

class CacheAvio {
private:
  int seek_offset = 0;

  FILE *data_file;
  FILE *index_file;
  uint8_t *index_map;
  size_t index_size;
  size_t current_offset;

  // Vérifie si un bloc est en cache
  bool is_block_cached(size_t block_id) {
    size_t byte_index = block_id / 8;
    size_t bit_index = block_id % 8;
    if (byte_index >= index_size)
      return false;
    return (index_map[byte_index] >> bit_index) & 1;
  }

  // Marque un bloc comme téléchargé
  void mark_block_as_cached(size_t block_id) {
    size_t byte_index = block_id / 8;
    size_t bit_index = block_id % 8;

    if (byte_index >= index_size) {
      size_t new_size = byte_index + 1;
      index_map = (uint8_t *)realloc(index_map, new_size);
      memset(index_map + index_size, 0, new_size - index_size);
      index_size = new_size;
    }

    index_map[byte_index] |= (1 << bit_index);

    // Met à jour l'index sur le disque
    fseek(index_file, byte_index + sizeof(int64_t), SEEK_SET);
    fwrite(&index_map[byte_index], 1, 1, index_file);
    fflush(index_file);
  }

  int download_block(size_t block_id) {
    if (is_block_cached(block_id)) {
      return 1;
    }

    int response = OpenHttp();
    if (response != 0) {
      return response;
    }

    uint8_t buffer[BLOCK_SIZE] = {0};

    // Déplacer la lecture HTTP à la bonne position
    size_t offset = block_id * BLOCK_SIZE;
    avio_seek(source_avio_ctx, offset, SEEK_SET);

    // Lire les données via HTTP
    size_t bytes_read = avio_read(source_avio_ctx, buffer, BLOCK_SIZE);

    if (bytes_read <= 0) {
      return bytes_read;
    }

    // Stocker en cache
    fseek(data_file, offset, SEEK_SET);
    fwrite(buffer, 1, bytes_read, data_file);
    fflush(data_file);

    mark_block_as_cached(block_id);

    return 1;
  }

  static int CustomReadPacket(void *opaque, uint8_t *buf, int buf_size) {
    CacheAvio *cacheAvio = reinterpret_cast<CacheAvio *>(opaque);

    size_t start_block = cacheAvio->current_offset / BLOCK_SIZE;
    size_t end_block = (cacheAvio->current_offset + buf_size - 1) / BLOCK_SIZE;

    for (size_t block_id = start_block; block_id <= end_block; block_id++) {
      int result = cacheAvio->download_block(block_id);
      if (result <= 0) {
        return 0;
      }
    }

    fseek(cacheAvio->data_file, cacheAvio->current_offset, SEEK_SET);
    size_t bytes_read = fread(buf, 1, buf_size, cacheAvio->data_file);

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

  bool has_been_open = false;

  int buffer_size = 4096;

  bool has_been_open_http = false;

  std::string file_url = "";

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
  AVIOContext *source_avio_ctx = nullptr;
  AVIOContext *avio_ctx = nullptr;

  CacheAvio() {}

  ~CacheAvio() { freeCache(); }

  AVDictionary *options = NULL;

  int64_t fileTotalSize = 0;

  int init(const char *cachePath, const char *cacheKey, const char *url,
           AVDictionary **newOptions) {
    if (has_been_open) {
      return 0;
    }

    file_url = url;

    av_dict_copy(&options, *newOptions, 0);

    std::string cacheDirectory = join(cachePath, sanitizeForPath(cacheKey));

    createDirectoryRecursive(cacheDirectory);

    data_file = fopen(join(cacheDirectory, DATA_FILE).c_str(), "rb+");
    if (!data_file)
      data_file = fopen(join(cacheDirectory, DATA_FILE).c_str(), "wb+");

    if (!data_file)
      return -1;

    index_file = fopen(join(cacheDirectory, INDEX_FILE).c_str(), "rb+");
    if (!index_file)
      index_file = fopen(join(cacheDirectory, INDEX_FILE).c_str(), "wb+");

    if (!index_file)
      return -1;

    // Charge l'index en mémoire
    fseek(index_file, 0, SEEK_END);
    index_size = ftell(index_file);
    rewind(index_file);

    if (index_size >= 8) {
      fread(&fileTotalSize, sizeof(int64_t), 1, index_file);
      index_size -= sizeof(int64_t);
    } else {
      int response = OpenHttp();
      if (response != 0) {
        return response;
      }

      fileTotalSize = avio_size(source_avio_ctx);
      fwrite(&fileTotalSize, sizeof(int64_t), 1, index_file);
    }

    index_map = (uint8_t *)malloc(index_size);
    fread(index_map, 1, index_size, index_file);

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

  void freeCache() {
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

    has_been_open = false;
  }
};
