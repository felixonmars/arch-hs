#ifndef CLIB_H
#define CLIB_H

typedef void callback_t(const char *, const char *);

int query_community(callback_t callback);

#endif