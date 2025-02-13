#pragma once

#include <algorithm>
#include <cctype>
#include <errno.h>
#include <iostream>
#include <string>
#include <sys/stat.h>

#ifdef _WIN32
#include <direct.h>
#define mkdir(path, mode) _mkdir(path)
#define PATH_SEPARATOR "\\"
#else
#include <sys/types.h>
#define PATH_SEPARATOR "/"
#endif

std::string sanitizeForPath(const std::string &text) {
  std::string sanitized = text;

  const std::string forbiddenChars = "\\/:*?\"<>|";

  std::replace_if(
      sanitized.begin(), sanitized.end(),
      [&](char c) {
        return !std::isalnum(c) && forbiddenChars.find(c) != std::string::npos;
      },
      '_');

  std::replace(sanitized.begin(), sanitized.end(), ' ', '_');

  return sanitized;
}

std::string join(const std::string &path1, const std::string &path2) {
  if (path1.empty())
    return path2;
  if (path2.empty())
    return path1;

  if (path1.back() == PATH_SEPARATOR[0]) {
    return path1 + path2;
  } else {
    return path1 + PATH_SEPARATOR + path2;
  }
}

bool createDirectory(const std::string &path) {
  if (mkdir(path.c_str(), 0777) == 0 || errno == EEXIST) {
    return true;
  } else {
    return false;
  }
}

bool createDirectoryRecursive(const std::string &path) {
  std::size_t pos = 0;
  std::string tempPath;

  while ((pos = path.find(PATH_SEPARATOR, pos)) != std::string::npos) {
    tempPath = path.substr(0, pos++);
    if (!tempPath.empty() && mkdir(tempPath.c_str(), 0777) != 0 &&
        errno != EEXIST) {
      return false;
    }
  }

  if (mkdir(path.c_str(), 0777) != 0 && errno != EEXIST) {
    return false;
  }

  return true;
}
