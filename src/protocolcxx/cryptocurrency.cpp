#include "cryptocurrency.h"
namespace bacteria {
namespace bjson {
json req(std::string userpwd, std::string url, json &data) {
  CURL *curl = curl_easy_init();
  struct curl_slist *headers = NULL;
  struct string s;

  if (curl) {
    std::string d_str = data.dump();
    init_string(&s);
    headers = curl_slist_append(headers, "content-type: text/plain;");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)d_str.size());
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, d_str.c_str());
    if (userpwd.size())
      curl_easy_setopt(curl, CURLOPT_USERPWD, userpwd.c_str());
    curl_easy_setopt(curl, CURLOPT_USE_SSL, CURLUSESSL_TRY);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writefunc);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &s);
    curl_easy_perform(curl);
  }
  auto req = json::parse(s.ptr);
  curl_slist_free_all(headers);
  curl_easy_cleanup(curl);
  if (s.ptr != NULL) {
#ifdef debug
    puts("clear old request");
#endif
    free(s.ptr);
    s.ptr = NULL;
    s.len = 0;
  }
  return req;
}
} // namespace bjson
cryptocoins::cryptocoins(std::string initFile) {
  mCryptocoins = init_new_cryptocoins(initFile.c_str(), &mCount);
}
cryptocoins::~cryptocoins(void) {
  uint tmp = getCountCryptocoins();
  setCountCryptocoins(mCount);
  clear_cryptocoins(mCryptocoins);
  setCountCryptocoins(tmp);
}
struct cryptocoin &cryptocoins::searchByName(std::string n) {
  for (unsigned char i = 0; mCryptocoins[i].rpchost != NULL &&
                            mCryptocoins[i].rpcport != 0 && i < mCount;
       i++) {
    if (strcmp(mCryptocoins[i].cryptocoin_name, n.c_str()) == 0)
      return mCryptocoins[i];
  }
  throw std::runtime_error("Not found cryptocoin: " + n);
}
struct cryptocoin &cryptocoins::operator[](std::string n) {
  return searchByName(n);
}
cryptocoins::mapOfKeys cryptocoins::getMap(void) {
  mapOfKeys rt;
  for (unsigned char i = 0; mCryptocoins[i].rpchost != NULL &&
                            mCryptocoins[i].rpcport != 0 && i < mCount;
       i++) {
    rt[mCryptocoins[i].cryptocoin_name] = &mCryptocoins[i];
  }
  return rt;
}

json cryptocoins::req(std::string &name, json &data) {
  struct cryptocoin &crypto = operator[](name);
  return req(crypto, data);
}
json cryptocoins::req(struct cryptocoin &a, json &data) {
  char userpwd[strlen(a.rpcuser) + strlen(a.rpcpassword) + 2];
  char url[strlen(a.rpchost) + sizeof("http://") + sizeof("65535") + 2];
  sprintf(userpwd, "%s:%s%c", a.rpcuser, a.rpcpassword, '\0');
  sprintf(url, "http://%s:%d%c", a.rpchost, a.rpcport, '\0');
  return bjson::req(userpwd, url, data);
}

}; // namespace bacteria
