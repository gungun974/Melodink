#pragma once

#include <algorithm>
#include <cctype>
#include <cerrno>
#include <cstdint>
#include <errno.h>
#include <iostream>
#include <limits>
#include <string>
#include <sys/stat.h>
#include <vector>

#ifdef _WIN32
#include <direct.h>
#include <windows.h>
#define mkdir(path, mode) _mkdir(path)
#define PATH_SEPARATOR "\\"
#else
#include <dirent.h>
#include <sys/types.h>
#include <unistd.h>
#include <utime.h>
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

bool touch(const std::string &filePath) {
  struct stat fileInfo;

#ifdef _WIN32
  HANDLE hFile = CreateFile(filePath.c_str(), FILE_WRITE_ATTRIBUTES, 0, NULL,
                            OPEN_EXISTING, 0, NULL);
  if (hFile == INVALID_HANDLE_VALUE) {
    return false;
  }

  FILETIME ft;
  SYSTEMTIME st;
  GetSystemTime(&st); // Récupère le temps actuel
  SystemTimeToFileTime(&st, &ft);

  if (!SetFileTime(hFile, NULL, NULL, &ft)) {
    CloseHandle(hFile);
    return false;
  }

  CloseHandle(hFile);
#else
  struct utimbuf new_times;
  new_times.actime = time(nullptr);
  new_times.modtime = time(nullptr);

  if (utime(filePath.c_str(), &new_times) != 0) {
    return false;
  }
#endif

  return true;
}

#include <cstdint> // Pour int64_t
#include <iostream>
#include <string>
#include <sys/stat.h>
#include <vector>

#ifdef _WIN32
#include <windows.h>
#else
#include <dirent.h> // Pour parcourir les fichiers sous Linux/macOS
#include <unistd.h>
#endif

int64_t getDirectorySize(const std::string &path) {
  int64_t totalSize = 0;

#ifdef _WIN32
  WIN32_FIND_DATA findFileData;
  HANDLE hFind = FindFirstFile((path + "\\*").c_str(), &findFileData);

  if (hFind == INVALID_HANDLE_VALUE) {
    return 0;
  }

  do {
    std::string fileName = findFileData.cFileName;
    if (fileName == "." || fileName == "..")
      continue;

    std::string fullPath = path + "\\" + fileName;
    if (findFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      totalSize += getDirectorySize(fullPath);
    } else {
      LARGE_INTEGER fileSize;
      fileSize.LowPart = findFileData.nFileSizeLow;
      fileSize.HighPart = findFileData.nFileSizeHigh;
      totalSize += fileSize.QuadPart;
    }
  } while (FindNextFile(hFind, &findFileData) != 0);

  FindClose(hFind);

#else
  DIR *dir = opendir(path.c_str());
  if (!dir) {
    return 0;
  }

  struct dirent *entry;
  while ((entry = readdir(dir)) != nullptr) {
    std::string fileName = entry->d_name;
    if (fileName == "." || fileName == "..")
      continue;

    std::string fullPath = path + "/" + fileName;
    struct stat fileStat;
    if (stat(fullPath.c_str(), &fileStat) == 0) {
      if (S_ISDIR(fileStat.st_mode)) {
        totalSize += getDirectorySize(fullPath);
      } else {
        totalSize += fileStat.st_size;
      }
    }
  }

  closedir(dir);
#endif

  return totalSize;
}

std::string findOldestFileByName(const std::string &directory,
                                 const std::string &searchFileName) {
  std::string oldestFile;
  time_t oldestTime = std::numeric_limits<time_t>::max();

#ifdef _WIN32
  WIN32_FIND_DATA findFileData;
  HANDLE hFind = FindFirstFile((directory + "\\*").c_str(), &findFileData);

  if (hFind == INVALID_HANDLE_VALUE) {
    return "";
  }

  do {
    std::string fileName = findFileData.cFileName;
    if (fileName == "." || fileName == "..")
      continue;

    std::string fullPath = directory + "\\" + fileName;
    if (findFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      std::string subOldest = findOldestFileByName(fullPath, searchFileName);
      if (!subOldest.empty()) {
        struct stat fileStat;
        if (stat(subOldest.c_str(), &fileStat) == 0 &&
            fileStat.st_mtime < oldestTime) {
          oldestTime = fileStat.st_mtime;
          oldestFile = subOldest;
        }
      }
    } else if (fileName == searchFileName) {
      struct stat fileStat;
      if (stat(fullPath.c_str(), &fileStat) == 0) {
        if (fileStat.st_mtime < oldestTime) {
          oldestTime = fileStat.st_mtime;
          oldestFile = fullPath;
        }
      }
    }
  } while (FindNextFile(hFind, &findFileData) != 0);

  FindClose(hFind);

#else
  DIR *dir = opendir(directory.c_str());
  if (!dir) {
    return "";
  }

  struct dirent *entry;
  while ((entry = readdir(dir)) != nullptr) {
    std::string fileName = entry->d_name;
    if (fileName == "." || fileName == "..")
      continue;

    std::string fullPath = directory + "/" + fileName;
    struct stat fileStat;
    if (stat(fullPath.c_str(), &fileStat) == 0) {
      if (S_ISDIR(fileStat.st_mode)) {
        std::string subOldest = findOldestFileByName(fullPath, searchFileName);
        if (!subOldest.empty()) {
          struct stat subFileStat;
          if (stat(subOldest.c_str(), &subFileStat) == 0 &&
              subFileStat.st_mtime < oldestTime) {
            oldestTime = subFileStat.st_mtime;
            oldestFile = subOldest;
          }
        }
      } else if (fileName == searchFileName) {
        if (fileStat.st_mtime < oldestTime) {
          oldestTime = fileStat.st_mtime;
          oldestFile = fullPath;
        }
      }
    }
  }

  closedir(dir);
#endif

  return oldestFile;
}

std::string getParentPath(const std::string &filePath) {
  if (filePath.empty())
    return "";

  size_t lastSeparator = filePath.find_last_of(PATH_SEPARATOR);

  if (lastSeparator == std::string::npos)
    return "";

  if (lastSeparator == filePath.length() - 1) {
    lastSeparator = filePath.find_last_of(PATH_SEPARATOR, lastSeparator - 1);
    if (lastSeparator == std::string::npos)
      return "";
  }

  return filePath.substr(0, lastSeparator);
}

bool removeDirectoryRecursive(const std::string &directoryPath) {
#ifdef _WIN32
  std::string searchPath = directoryPath + "\\*";
  WIN32_FIND_DATA findFileData;
  HANDLE hFind = FindFirstFile(searchPath.c_str(), &findFileData);

  if (hFind == INVALID_HANDLE_VALUE) {
    return false;
  }

  do {
    std::string fileName = findFileData.cFileName;
    if (fileName == "." || fileName == "..")
      continue;

    std::string fullPath = directoryPath + "\\" + fileName;
    if (findFileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
      removeDirectoryRecursive(fullPath);
    } else {
      if (!DeleteFile(fullPath.c_str())) {
        FindClose(hFind);
        return false;
      }
    }
  } while (FindNextFile(hFind, &findFileData) != 0);

  FindClose(hFind);
  return RemoveDirectory(directoryPath.c_str());

#else
  DIR *dir = opendir(directoryPath.c_str());
  if (!dir) {
    return false;
  }

  struct dirent *entry;
  while ((entry = readdir(dir)) != nullptr) {
    std::string fileName = entry->d_name;
    if (fileName == "." || fileName == "..")
      continue;

    std::string fullPath = directoryPath + "/" + fileName;
    struct stat fileStat;
    if (stat(fullPath.c_str(), &fileStat) == 0) {
      if (S_ISDIR(fileStat.st_mode)) {
        removeDirectoryRecursive(fullPath);
      } else {
        if (unlink(fullPath.c_str()) != 0) {
          closedir(dir);
          return false;
        }
      }
    }
  }

  closedir(dir);
  return rmdir(directoryPath.c_str()) == 0;
#endif
}
