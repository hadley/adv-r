#include <Rcpp.h>

namespace boost{
    std::size_t hash_value(Rcpp::String);
}

#include <boost/unordered_map.hpp>

namespace boost{
    std::size_t hash_value(Rcpp::String obj){
        return hash_value<SEXP>( obj.get_sexp() ) ;
    }
}
using namespace Rcpp;

// // [[Rcpp::export]]
// IntegerVector match1(const CharacterVector x, const CharacterVector table) {
//   boost::unordered_map<std::string, int> lookup;

//   int n = table.length();
//   for (int i = 0; i < n; i++) {
//     const char* name = table[i];
//     lookup[name] = i + 1;
//   }

//   int m = x.length();
//   IntegerVector out(m);
//   for (int j = 0; j < m; j++) {
//     const char* name = x[j];
//     out[j] = lookup[name];
//   }
//   return out;
// }

// // With iterators: is actually slower?
// // [[Rcpp::export]]
// IntegerVector match2(const CharacterVector x, const CharacterVector table) {
//   boost::unordered_map<std::string, int> lookup;

//   int n = table.length();
//   for (int i = 0; i < n; i++) {
//     const char* name = table[i];
//     lookup[name] = i + 1;
//   }

//   int m = x.length();
//   IntegerVector out(m);
//   CharacterVector::iterator it = x.begin();

//   for (int j = 0; j < m; j++) {
//     const char* name = it[j];
//     out[j] = lookup[name];
//   }
//   return out;
// }

// [[Rcpp::export]]
IntegerVector match3(const CharacterVector x, const CharacterVector table) {
  boost::unordered_map<String, int> lookup;

  int n = table.size();
  for (int i = 0; i < n; ++i) {
    lookup[table[i]] = i;
  }

  int m = x.size();
  IntegerVector out(m);
  for (int i = 0; i < m; ++i) {
    out[i] = lookup[x[i]] + 1;
  }
  return out;
}

/*** R

library(microbenchmark)

# Long x, short table
x <- sample(letters, 1e4, rep = T)
microbenchmark(
  match(x, letters),
#  match1(x, letters),
#  match2(x, letters),
  match3(x, letters)
)

x <- replicate(1e4, paste(sample(letters, 10), collapse = ""))
microbenchmark(
  match(x[1:10], x),
#  match1(x[1:10], x),
#  match2(x[1:10], x),
  match3(x[1:10], x)
)

microbenchmark(
  match(x[9990:10000], x),
#  match1(x[9990:10000], x),
#  match2(x[9990:10000], x),
  match3(x[9990:10000], x)
)

*/