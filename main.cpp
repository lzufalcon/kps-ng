#include <iostream>
#include <string>
#include <fstream>
#include <regex>
#include <cassert>

enum class ChangeLogParseState {
  AUTHOR_LINE = 0,
  DIFFSTAT_LINE,
  DIR_LINE,
};

class Author {
 public:
  std::string name;
  std::string email;
};

bool parseAuthorLine(const std::string &line, Author *author, std::string *date) {
  static const std::regex authorLineRegex("^Author: (.*) (<.*@.*>); Date: ([0-9]{4}-[0-1][0-9]-[0-3][0-9])$");
  std::smatch match;
  if (std::regex_match(line, match, authorLineRegex)) {
    if (match.size() != 4)
      return false;
    author->name = match[1];
    author->email = match[2];
    *date = match[3];
    //std::cout << author->name << " " << author->email << " " << *date << std::endl;
  } else {
    return false;
  }
  return true;
}

bool parseDiffStatLine(const std::string &line, size_t * lineCount) {
  static const std::regex diffStatLineRegex("^ ([0-9]+) files? changed, (([0-9]+) insertions?\\(\\+\\))?(, )?(([0-9]+) deletions?\\(-\\))?$");
  std::smatch match;
  if (std::regex_match(line, match, diffStatLineRegex)) {
    if (match.size() != 7)
      return false;
    *lineCount = 0;
    if (match[3].matched) {
      *lineCount += stoi(match[3]);
    }
    if (match[6].matched) {
      *lineCount += stoi(match[6]);
    }
    //std::cout << *lineCount << std::endl;
  } else {
    return false;
  }
  return true;
}

bool parseDirLine(const std::string &line, std::string * dir) {
  static const std::regex dirLineRegex("^.*% (.*)$");
  std::smatch match;
  if (std::regex_match(line, match, dirLineRegex)) {
    if (match.size() != 2)
      return false;
    *dir = match[1];
  } else {
    return false;
  }
  return true;
}

int main(int argc, char *argv[]) {
  std::string fileName = argv[1];
  std::ifstream inFile(fileName);
  std::string line;
  ChangeLogParseState state = ChangeLogParseState::AUTHOR_LINE;
  Author author;
  std::string date;
  size_t lineCount;
  std::string dir;
  while (std::getline(inFile, line)) {
    bool ret;
    switch (state) {
      case ChangeLogParseState::AUTHOR_LINE:
        ret = parseAuthorLine(line, &author, &date);
        assert(ret);
        state = ChangeLogParseState::DIFFSTAT_LINE;
        break;
      case ChangeLogParseState::DIFFSTAT_LINE:
        ret = parseDiffStatLine(line, &lineCount);
        assert(ret);
        state = ChangeLogParseState::DIR_LINE;
        break;
      case ChangeLogParseState::DIR_LINE:
        if (line.empty()) {
          state = ChangeLogParseState::AUTHOR_LINE;
          break;
        }
        ret = parseDirLine(line, &dir);
        assert(ret);
        break;
    }
  }
  return 0;
}