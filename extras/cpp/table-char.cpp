#include <Rcpp.h>
#include <boost/unordered_map.hpp>
using namespace Rcpp;

// [[Rcpp::export]]
IntegerVector table1(const CharacterVector x) {
  std::map<std::string, int> counts;
  std::vector<std::string> vec = as<std::vector<std::string> >(x);

  int n = x.length();
  for (int i = 0; i < n; i++) {
    counts[vec[i]]++;
  }

  // Loop through each element of map and output into named vector
  IntegerVector out(counts.size());
  CharacterVector names(counts.size());

  std::map<std::string, int>::const_iterator it;
  int i;
  for (i = 0, it = counts.begin(); it != counts.end(); i++, it++) {
    names[i] = it->first;
    out[i] = it->second;
  }
  out.attr("names") = names;
  return out;
}

// [[Rcpp::export]]
IntegerVector table4(CharacterVector x) {
  boost::unordered_map<std::string, int> counts;

  for (int i = 0; i < x.size(); i++) {
    const char* name = x[i];
    counts[name]++;
  }  

  IntegerVector out(counts.size());
  CharacterVector names(counts.size());

  boost::unordered_map<std::string, int>::const_iterator it;
  int i;
  for (i = 0, it = counts.begin(); it != counts.end(); i++, it++) {
    names[i] = it->first;
    out[i] = it->second;
  }
  out.attr("names") = names;
  return out;
}

// [[Rcpp::export]]
std::map<std::string, int> table5(CharacterVector x) {
  std::map<std::string, int> counts;
  int n = x.size();
  CharacterVector::iterator it = x.begin();
  for (int i = 0; i < x.size(); i++) {
    const char* name = x[i];
    counts[name]++;
  }  
  return counts;
}

// [[Rcpp::export]]
std::map<std::string, int> table6(CharacterVector x) {
    
  // perform the count
  std::map<const char*, int> counts;
  for (int i = 0; i < x.size(); i++) {
    const char* name = x[i];
    counts[name]++;
  }
  
  // creating a new map keyed by std::string
  std::map<std::string,int> result;
  for (std::map<const char*, int>::const_iterator 
         it = counts.begin(); it != counts.end(); ++it) {
    result[it->first] = result[it->first] + it->second;
  }
  return result;
}

// [[Rcpp::export]]
std::map<std::string, int> table6a(CharacterVector x) {
    
  // perform the count
  std::map<const char*, int> counts;
  int n = x.size();
  for (int i = 0; i < n; i++) {
    const char* name = x[i];
    counts[name]++;
  }
  
  // creating a new map keyed by std::string
  std::map<std::string,int> result;
  for (std::map<const char*, int>::const_iterator 
         it = counts.begin(); it != counts.end(); ++it) {
    result[it->first] = result[it->first] + it->second;
  }
  return result;
}

/*** R
library(microbenchmark)

x <- sample(letters, 1e4, rep = T)
microbenchmark(
  table(x),
  table1(x),
  table4(x),
  table5(x),
  table6(x),
  table6a(x)
)
# About 2x slower

*/