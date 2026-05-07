// link: -lcurl
/*
 * http.c — m-stdlib Phase 3 HTTP/1.1 client callout (track H3 iter 2).
 *
 * Backend: libcurl easy interface (curl_easy_init / setopt / perform /
 * getinfo / cleanup). Single entry point:
 *
 *   http_perform(method, url, reqHeaders, reqBody,
 *                timeoutMs, followRedirects, verifyTls,
 *                statusCode_out, respHeaders_out, respBody_out,
 *                errorMsg_out)
 *
 * The C side captures both the response header stream and the response
 * body stream via libcurl write callbacks into caller-allocated YDB
 * buffers. Returns 0 on success; non-zero on error (see Status codes
 * below). Status codes are the libcurl error semantic; the HTTP status
 * code (200 / 404 / 500 / ...) is returned out-of-band via
 * statusCode_out so a successful HTTP call with a 4xx/5xx response is
 * still a "C-side success" — the M layer interprets the status itself.
 *
 * Build:
 *   tools/build-callouts.sh             # produces so/<plat>/http.so
 * Loading:
 *   tools/std_http.xc                   # YDB call-out descriptor
 *   export STDLIB_LIB=<abs-path-to-so/<plat>>
 *   export ydb_xc_std_http=<abs-path>/tools/std_http.xc
 *
 * Calling convention:
 *   Inputs are ydb_string_t* (pointer + length, byte-safe).
 *   statusCode_out is ydb_int_t* (signed long; 0 if no response).
 *   respHeaders_out / respBody_out are ydb_string_t* with caller-
 *   allocated address + length budget; the C side writes up to
 *   length bytes and updates length to the actual size written.
 *   If the backend produces more bytes than the budget, output is
 *   truncated and the function returns 0 (truncation is silent —
 *   callers needing exact-size enforcement should check Content-
 *   Length on the response). errorMsg_out is similarly pre-
 *   allocated; written with a curl error string on non-zero return.
 *
 * Status codes:
 *    0 = ok (HTTP exchange completed; statusCode_out holds HTTP code)
 *   -1 = curl_easy_init() returned NULL
 *   -2 = setopt failed (rare; usually a build/version mismatch)
 *   -3 = curl_easy_perform() returned non-CURLE_OK (network / TLS / DNS
 *        failure; errorMsg_out holds curl_easy_strerror() text)
 *   -4 = caller-provided output buffer pointer is NULL
 *   -5 = curl_slist_append failed for one of the request headers
 */

#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <curl/curl.h>
#include "libyottadb.h"

/* Capture buffer — points into caller's ydb_string_t and tracks how many
 * bytes have been written so far. Truncates silently when full. */
typedef struct {
    char         *base;
    unsigned long cap;
    unsigned long used;
} capture_t;

static size_t capture_write(void *ptr, size_t size, size_t nmemb, void *userp)
{
    capture_t    *cap   = (capture_t *)userp;
    size_t        avail = (size_t)nmemb * size;
    unsigned long room  = (cap->cap > cap->used) ? (cap->cap - cap->used) : 0;
    size_t        copy  = (avail < room) ? avail : (size_t)room;

    if (copy > 0) {
        memcpy(cap->base + cap->used, ptr, copy);
        cap->used += copy;
    }
    /* Always tell curl we accepted everything — truncation is silent. */
    return avail;
}

static void copy_str_safely(ydb_string_t *out, const char *src)
{
    size_t n;
    if (out == NULL || out->address == NULL) return;
    n = strlen(src);
    if (n > (size_t)out->length) n = (size_t)out->length;
    memcpy(out->address, src, n);
    out->length = (unsigned long)n;
}

static int append_request_headers(struct curl_slist **dst,
                                  ydb_string_t *headers)
{
    /* headers is a CRLF-separated block produced by formatHeaders^STDHTTP.
     * Walk it line-by-line; each non-empty "Name: value" line goes through
     * curl_slist_append. Per libcurl convention, empty/whitespace-only
     * lines are skipped. */
    struct curl_slist *slist = *dst;
    const char        *p, *q, *end;
    char               line[8192];
    size_t             n;

    if (headers == NULL || headers->address == NULL || headers->length == 0)
        return 0;

    p   = headers->address;
    end = p + headers->length;

    while (p < end) {
        /* Find end of this line (CRLF or LF). */
        q = p;
        while (q < end && *q != '\r' && *q != '\n') q++;
        n = (size_t)(q - p);
        if (n > sizeof(line) - 1) n = sizeof(line) - 1;
        if (n > 0) {
            memcpy(line, p, n);
            line[n] = '\0';
            slist = curl_slist_append(slist, line);
            if (slist == NULL) return -5;
        }
        /* Advance past CR (if present) then LF (if present). */
        p = q;
        if (p < end && *p == '\r') p++;
        if (p < end && *p == '\n') p++;
    }
    *dst = slist;
    return 0;
}

int http_perform(ydb_string_t *method,
                 ydb_string_t *url,
                 ydb_string_t *reqHeaders,
                 ydb_string_t *reqBody,
                 ydb_int_t     timeoutMs,
                 ydb_int_t     followRedirects,
                 ydb_int_t     verifyTls,
                 ydb_int_t    *statusCode,
                 ydb_string_t *respHeaders,
                 ydb_string_t *respBody,
                 ydb_string_t *errorMsg)
{
    CURL              *curl;
    CURLcode           rc;
    struct curl_slist *headerSlist = NULL;
    capture_t          headerCap, bodyCap;
    char               methodBuf[16];
    char               urlBuf[8192];
    long               httpCode = 0;
    size_t             n;
    int                ret = 0;

    /* Pre-flight: every output buffer must be present. */
    if (statusCode == NULL || respHeaders == NULL || respBody == NULL) {
        if (errorMsg) copy_str_safely(errorMsg, "STDHTTP-NULL-OUT");
        return -4;
    }

    *statusCode       = 0;
    respHeaders->length = 0;
    respBody->length    = 0;
    if (errorMsg) errorMsg->length = 0;

    /* Snapshot method + url into NUL-terminated stack buffers — libcurl
     * needs C strings, but the inputs are length-prefixed. Truncate
     * silently if either is unreasonably long. */
    n = (method && method->address)
        ? ((size_t)method->length < sizeof(methodBuf) - 1
               ? (size_t)method->length : sizeof(methodBuf) - 1)
        : 0;
    if (n > 0) memcpy(methodBuf, method->address, n);
    methodBuf[n] = '\0';
    if (n == 0) strcpy(methodBuf, "GET");

    n = (url && url->address)
        ? ((size_t)url->length < sizeof(urlBuf) - 1
               ? (size_t)url->length : sizeof(urlBuf) - 1)
        : 0;
    if (n > 0) memcpy(urlBuf, url->address, n);
    urlBuf[n] = '\0';

    curl = curl_easy_init();
    if (curl == NULL) {
        if (errorMsg) copy_str_safely(errorMsg, "STDHTTP-CURL-INIT-FAIL");
        return -1;
    }

    /* Capture buffers. */
    headerCap.base = respHeaders->address;
    headerCap.cap  = (unsigned long)respHeaders->length;
    headerCap.used = 0;
    bodyCap.base   = respBody->address;
    bodyCap.cap    = (unsigned long)respBody->length;
    bodyCap.used   = 0;

    /* Core options. */
    curl_easy_setopt(curl, CURLOPT_URL,            urlBuf);
    curl_easy_setopt(curl, CURLOPT_CUSTOMREQUEST,  methodBuf);
    curl_easy_setopt(curl, CURLOPT_HEADERFUNCTION, capture_write);
    curl_easy_setopt(curl, CURLOPT_HEADERDATA,     &headerCap);
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION,  capture_write);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA,      &bodyCap);
    curl_easy_setopt(curl, CURLOPT_NOSIGNAL,       1L);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT_MS,
                     (long)(timeoutMs > 0 ? timeoutMs : 30000));
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION,
                     (long)(followRedirects ? 1 : 0));
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER,
                     (long)(verifyTls ? 1 : 0));
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYHOST,
                     (long)(verifyTls ? 2 : 0));

    /* Request body — POST/PUT/PATCH/etc. */
    if (reqBody && reqBody->address && reqBody->length > 0) {
        curl_easy_setopt(curl, CURLOPT_POSTFIELDSIZE, (long)reqBody->length);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS,    reqBody->address);
    }

    /* Caller-supplied request headers. We deliberately do NOT add a
     * default User-Agent here — leave that to the M layer or libcurl's
     * built-in default. The M layer's buildRequest already synthesises
     * Host: when not given. */
    ret = append_request_headers(&headerSlist, reqHeaders);
    if (ret != 0) {
        if (errorMsg) copy_str_safely(errorMsg, "STDHTTP-HEADER-APPEND-FAIL");
        if (headerSlist) curl_slist_free_all(headerSlist);
        curl_easy_cleanup(curl);
        return ret;
    }
    if (headerSlist) {
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headerSlist);
    }

    /* Execute. */
    rc = curl_easy_perform(curl);
    if (rc != CURLE_OK) {
        if (errorMsg) copy_str_safely(errorMsg, curl_easy_strerror(rc));
        if (headerSlist) curl_slist_free_all(headerSlist);
        curl_easy_cleanup(curl);
        respHeaders->length = headerCap.used;
        respBody->length    = bodyCap.used;
        return -3;
    }

    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &httpCode);
    *statusCode = (ydb_int_t)httpCode;

    respHeaders->length = headerCap.used;
    respBody->length    = bodyCap.used;

    if (headerSlist) curl_slist_free_all(headerSlist);
    curl_easy_cleanup(curl);
    return 0;
}

ydb_long_t http_available(void)
{
    /* Smoke probe used by $$available^STDHTTP() — returns 1 iff the .so
     * loads AND libcurl is wired in (curl_easy_init() is the cheapest
     * end-to-end check that doesn't touch the network). Returns 0 if
     * curl_easy_init fails. The $ZF caller distinguishes "symbol not
     * resolvable" (M-side $ETRAP) from "loaded but curl broken" (this
     * function returning 0). */
    CURL *c = curl_easy_init();
    if (c == NULL) return 0;
    curl_easy_cleanup(c);
    return 1;
}
